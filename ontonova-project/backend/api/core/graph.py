import logging
import os
import re
from functools import lru_cache
from pathlib import Path
from typing import Any, AsyncIterator, Dict, List, Optional, TypedDict

from langgraph.graph import END, StateGraph
from pydantic import BaseModel, Field

from api.core.models import DataProperty, Individual, ObjectProperty, OntoClass, OntoNovaSchema
from api.core.validator import validate_ontonova_json
from api.services.vllm_client import LLMGenerationError, generate_structured

logger = logging.getLogger(__name__)

GUIDANCE_PATH = Path(__file__).resolve().parent.parent / "prompts" / "GUIDANCE.md"
# Dense, entity-rich domain texts can take a few passes for populator to
# converge (each retry only needs to fix what's still wrong, so extra
# retries are cheap when the error count is trending down — see
# core.validator's per-category error prefixes and _stage_from_error below).
MAX_RETRIES = 4

# Pre-flight input budget (REQ-US-FC-01/FC-10: inputs up to 15,000 chars).
# The model context (vLLM --max-model-len 16384) must fit the domain text +
# the guidance/system scaffolding (~3,000 tokens) + the reserved completion
# (8,192, see vllm_client max_tokens); at the 3.3 chars/token ratio measured
# on a real Spanish document that budget is ~17,100 chars, so the committed
# 15,000 keeps ~12% engineering margin. Over-long text is refused instantly
# with an actionable message instead of a cryptic 400 from the inference
# engine; borderline cases beyond the heuristic still fall through to vLLM's
# own exact check, which the client surfaces verbatim.
MAX_INPUT_CHARS = int(os.getenv("MAX_INPUT_CHARS", "15000"))


@lru_cache(maxsize=1)
def _guidance() -> str:
    return GUIDANCE_PATH.read_text(encoding="utf-8")


# =====================================================================
# SCOPED OUTPUT SCHEMAS PER SPECIALIST AGENT
# Each wraps a subset of the OntoNovaSchema $defs from core.models, so
# every agent is only ever asked to produce the slice of the contract it
# owns (Single Responsibility, see thesis sec:agents).
# =====================================================================
class TaxonomistOutput(BaseModel):
    classes: List[OntoClass] = Field(default_factory=list)


class RelationalOutput(BaseModel):
    object_properties: List[ObjectProperty] = Field(default_factory=list)
    data_properties: List[DataProperty] = Field(default_factory=list)


class PopulatorOutput(BaseModel):
    individuals: List[Individual] = Field(default_factory=list)


class OntologyGenerationState(TypedDict, total=False):
    input_text: str
    language: str
    classes: List[Dict[str, Any]]
    object_properties: List[Dict[str, Any]]
    data_properties: List[Dict[str, Any]]
    individuals: List[Dict[str, Any]]
    status: str  # "in_progress" | "valid" | "retrying" | "failed"
    last_error: Optional[str]
    retry_stage: Optional[str]
    retries: int


def _base_url(role: str) -> str:
    return os.getenv(f"{role.upper()}_BASE_URL", "http://localhost:8000/v1")


STAGE_ORDER = ["taxonomist", "relational", "populator"]


# State keys owned by each stage — used to show a retrying stage its own
# previous output so it can EDIT it instead of regenerating from scratch.
_STAGE_STATE_KEYS = {
    "taxonomist": ("classes",),
    "relational": ("object_properties", "data_properties"),
    "populator": ("individuals",),
}


def _correction_note(state: OntologyGenerationState, stage: str) -> str:
    """
    Every stage from `retry_stage` onward re-executes this pass (the graph
    loops back to `retry_stage` and falls through the normal forward edges),
    so each of them needs the failure context — not just the one stage whose
    field happened to be mentioned first in the error. Without this, a
    validation error that actually spans multiple stages (e.g. relational AND
    populator both produced a dangling reference in the same pass) only gets
    corrected one stage at a time, wasting the bounded retry budget.

    The note includes the stage's own previous output with explicit "edit,
    don't regenerate" framing. Without it, models satisfy the validator the
    cheap way — by omitting everything the error touched (observed in the
    scrum-3 graph-quality run: after 4 retries the populator returned zero
    relation assertions rather than fixing the one dangling reference).
    """
    retry_stage = state.get("retry_stage")
    if not retry_stage or not state.get("last_error"):
        return ""
    if STAGE_ORDER.index(stage) < STAGE_ORDER.index(retry_stage):
        return ""  # this stage already succeeded and won't re-run this pass
    previous_output = {key: state.get(key, []) for key in _STAGE_STATE_KEYS[stage]}
    return (
        "\n\nA previous attempt failed schema validation with this error:\n"
        f"{state['last_error']}\n\n"
        f"Your previous output for this stage was:\n{previous_output}\n\n"
        "Produce a corrected version of that output: keep every entry that is "
        "not implicated in the error and fix only what the error requires. Do "
        "NOT drop previously produced valid content (classes, properties, "
        "individuals or their assertions) just to make the error disappear. "
        "If the error says an assertion uses an undeclared property or "
        "individual id, the relationship itself is usually correct: declare "
        "the missing item if this stage owns it, or re-express the assertion "
        "with a declared id — removing the relationship is the last resort."
    )


def _domain_text_header(state: OntologyGenerationState) -> str:
    """
    REQ-US-FC-01 requires accepting text in any language. `language` is an
    optional user hint (blank means auto-detect from the text itself), so it
    must not be rendered as a literal "(language: )" when absent.
    """
    language = (state.get("language") or "").strip()
    suffix = f" (language: {language})" if language else " (detect the language automatically)"
    return f"Domain text{suffix}:\n\n{state['input_text']}"


# =====================================================================
# AGENT NODES
# =====================================================================
async def taxonomist_node(state: OntologyGenerationState) -> Dict[str, Any]:
    messages = [
        {
            "role": "system",
            "content": (
                f"{_guidance()}\n\nYou are the Taxonomist agent. Extract ONLY the "
                "Classes and their subClassOf hierarchy from the domain text below. "
                "Do not produce object properties, data properties or individuals. "
                "A class is a general KIND of thing, never a specific named "
                "entity: for 'the Department of Computer Science' the class is "
                "'Department', for 'the Turing Laboratory' it is 'Laboratory' — "
                "the named entities themselves become Individuals in a later "
                "stage.\n"
                "Two rules matter most here:\n"
                "1. HIERARCHY: whenever the text presents a broader/narrower "
                "relationship, you MUST link the classes with `subClassOf`. This "
                "includes explicit statements ('professors and students are both "
                "persons' -> Professor and Student subClassOf Person) AND "
                "classification or taxonomy listings (e.g. a scientific "
                "classification Kingdom > Phylum > Class > Order > Family > Genus, "
                "or any 'A is a kind/type of B'): chain each level's class under "
                "the level above it. A flat list of classes with no subClassOf for "
                "a text that clearly describes a hierarchy is WRONG.\n"
                "2. NOT CLASSES: do not create a class for a quality, activity, "
                "state, measurement, event, or value mentioned in the text (e.g. "
                "'daytime activity', 'pregnancy period', 'lifespan', 'living "
                "alone', 'leaves and buds', 'a mix of giraffe and zebra'). Those "
                "are attributes or relationships handled by later stages, not "
                "kinds of thing. DO, however, create a class for every distinct "
                "kind of entity the text compares or relates the main subject to "
                "(e.g. if the text links okapis to giraffes and zebras, 'Giraffe' "
                "and 'Zebra' are classes)."
            ),
        },
        {
            "role": "user",
            "content": _domain_text_header(state) + _correction_note(state, "taxonomist"),
        },
    ]
    result = await generate_structured(
        messages, TaxonomistOutput.model_json_schema(), base_url=_base_url("taxonomist")
    )
    return {"classes": result.get("classes", [])}


async def relational_node(state: OntologyGenerationState) -> Dict[str, Any]:
    messages = [
        {
            "role": "system",
            "content": (
                f"{_guidance()}\n\nYou are the Relational agent. Given the Classes "
                "already extracted below, produce Object Properties and Data "
                "Properties. The `domain` and `range` of every property MUST "
                "reference only the provided class IDs. Declare every "
                "relationship the text states between two extracted classes — "
                "including part-whole ones (e.g. a department being part of a "
                "university) and offering/provision ones (e.g. a department "
                "offering a course) — and set `domain`/`range` in exactly the "
                "direction the text states the relationship."
            ),
        },
        {
            "role": "user",
            "content": (
                _domain_text_header(state)
                + f"\n\nExtracted classes:\n{state.get('classes', [])}"
                + _correction_note(state, "relational")
            ),
        },
    ]
    result = await generate_structured(
        messages, RelationalOutput.model_json_schema(), base_url=_base_url("relational")
    )
    return {
        "object_properties": result.get("object_properties", []),
        "data_properties": result.get("data_properties", []),
    }


async def populator_node(state: OntologyGenerationState) -> Dict[str, Any]:
    messages = [
        {
            "role": "system",
            "content": (
                f"{_guidance()}\n\nYou are the Populator agent. Given the text, "
                "Classes and Properties already extracted below, identify concrete "
                "Individuals and assert their object/data property values. "
                "Direction matters: assert each relationship on the individual "
                "whose class is the property's `domain`, with individuals of the "
                "property's `range` class as targets — never the other way around."
            ),
        },
        {
            "role": "user",
            "content": (
                _domain_text_header(state)
                + f"\n\nExtracted classes:\n{state.get('classes', [])}"
                + f"\n\nExtracted object properties:\n{state.get('object_properties', [])}"
                + f"\n\nExtracted data properties:\n{state.get('data_properties', [])}"
                + _correction_note(state, "populator")
            ),
        },
    ]
    result = await generate_structured(
        messages, PopulatorOutput.model_json_schema(), base_url=_base_url("populator")
    )
    return {"individuals": result.get("individuals", [])}


_STAGE_BY_CATEGORY = {
    "classes": "taxonomist",
    "object_properties": "relational",
    "data_properties": "relational",
    "individuals": "populator",
}



# core.validator's exact wording for these two individuals-category error
# kinds (see _check_referential_integrity) — matched verbatim below, not as
# a fuzzy substring search over arbitrary explanation text, so this stays
# safe under the same reasoning _stage_from_error already documents.
_UNDECLARED_PROPERTY_MARKERS = ("asserts undeclared object property", "asserts undeclared data property")


def _stage_from_error(error_msg: str) -> str:
    """
    Routing: core.validator joins every individual error with "; ", and each
    one is formatted as "{category}: ...". Only that leading prefix names
    the stage actually at fault — the error's explanation body can
    legitimately *mention* other category names too (e.g. a uniqueness
    collision explains which earlier category it collides with), so scanning
    the whole string for a substring match would misattribute those to the
    wrong stage. When more than one stage is genuinely implicated, prefer the
    earliest in pipeline order so restarting from it cascades through (and
    re-validates) everything downstream too.

    One "individuals:" error kind is special-cased: populator asserting a
    property id that was never declared at all. Populator can only pick from
    the object/data properties relational already produced — if the text
    implies a relationship relational never declared (e.g. it covered
    Professor-Student but missed a Student-Student relation), no amount of
    retrying populator alone can produce a valid property id for it, and
    retries just oscillate between different hallucinated names (see the
    "university roles" investigation in the project history). Routing these
    to "relational" instead gives it a chance to declare the missing
    property before populator tries again.
    """
    stages = set()
    for part in error_msg.split("; "):
        prefix = part.split(":", 1)[0].strip()
        if prefix == "individuals" and any(marker in part for marker in _UNDECLARED_PROPERTY_MARKERS):
            stages.add("relational")
            continue
        stage = _STAGE_BY_CATEGORY.get(prefix)
        if stage:
            stages.add(stage)

    for stage in ("taxonomist", "relational", "populator"):
        if stage in stages:
            return stage
    return "taxonomist"


# =====================================================================
# DETERMINISTIC REFERENCE REPAIR
# Populator's most common failure is referring to an individual under a
# spelling it never declared (e.g. asserting a relation to
# "professorAlanTuring" while declaring the individual as "alanTuring").
# Regenerating rarely fixes this — each retry just produces a different
# spelling — but it is mechanically repairable, so the validator remaps
# such references before spending a retry (REQ-US-FC-03's graceful
# degradation as an engineering guarantee rather than prompt luck).
# =====================================================================
def _normalize_reference(value: str) -> str:
    value = re.sub(r"^(inst|individual|class|prop|attr)_?", "", value, flags=re.IGNORECASE)
    return re.sub(r"[^a-z0-9]", "", value.lower())


def _fuzzy_individual_match(target: str, lookup: Dict[str, str]) -> Optional[str]:
    normalized = _normalize_reference(target)
    if normalized in lookup:
        return lookup[normalized]
    # "professoralanturing" vs "alanturing": one id embeds the other. The
    # length guard keeps trivially short keys from matching everything.
    if len(normalized) >= 4:
        for key, declared_id in lookup.items():
            if len(key) >= 4 and (normalized.endswith(key) or key.endswith(normalized)):
                return declared_id
    return None


def _class_conformance_checker(merged: Dict[str, Any]):
    """Returns conforms(class_id, ancestor_id) walking the subClassOf chain."""
    parent = {
        cls.get("id"): cls.get("subClassOf")
        for cls in merged.get("classes", [])
        if isinstance(cls, dict)
    }

    def conforms(candidate: Optional[str], ancestor: str) -> bool:
        seen = set()
        while candidate and candidate not in seen:
            if candidate == ancestor:
                return True
            seen.add(candidate)
            candidate = parent.get(candidate)
        return False

    return conforms


def _dedupe_global_ids(merged: Dict[str, Any]) -> List[str]:
    """
    Every id lives in ONE flat RDF namespace (services.rdf_compiler), so an id
    reused anywhere — within a category (two object properties both 'isRelatedTo'
    — observed live) or across categories (class 'TuringLaboratory' + individual
    'TuringLaboratory') — is invalid but losslessly repairable:

    * A byte-identical duplicate is simply dropped.
    * Otherwise the LATER occurrence is renamed (the first keeps the id, so
      existing references still resolve). When the renamed entry is an
      individual whose id was first claimed by a NON-individual, assertion
      targets pointing at that id meant this individual, so they're rewritten
      to the new id; a second individual reusing a first individual's id
      leaves references with the first, so they're left alone.
    """
    notes: List[str] = []
    seen_items: Dict[str, Dict[str, Any]] = {}
    claimant_category: Dict[str, str] = {}
    individual_ref_rewrites: Dict[str, str] = {}

    for category in ("classes", "object_properties", "data_properties", "individuals"):
        kept: List[Any] = []
        for item in merged.get(category, []):
            if not isinstance(item, dict) or not isinstance(item.get("id"), str):
                kept.append(item)
                continue
            original = item["id"]
            if original not in seen_items:
                seen_items[original] = item
                claimant_category[original] = category
                kept.append(item)
                continue
            if item == seen_items[original]:
                notes.append(f"dropped duplicate {category} entry '{original}'")
                continue
            candidate, counter = f"{original}_2", 2
            while candidate in seen_items:
                counter += 1
                candidate = f"{original}_{counter}"
            item["id"] = candidate
            seen_items[candidate] = item
            claimant_category[candidate] = category
            kept.append(item)
            notes.append(f"renamed {category} '{original}' -> '{candidate}' (id collision)")
            if category == "individuals" and claimant_category.get(original) != "individuals":
                individual_ref_rewrites[original] = candidate
        merged[category] = kept

    if individual_ref_rewrites:
        for ind in merged.get("individuals", []):
            if not isinstance(ind, dict):
                continue
            assertions = ind.get("objectPropertyAssertions")
            if not isinstance(assertions, dict):
                continue
            for targets in assertions.values():
                if isinstance(targets, list):
                    for index, target in enumerate(targets):
                        if target in individual_ref_rewrites:
                            targets[index] = individual_ref_rewrites[target]
    return notes


def _swap_inverted_object_assertions(merged: Dict[str, Any]) -> List[str]:
    """
    When an assertion's subject fits the property's RANGE and its target fits
    the DOMAIN (a clean inversion, e.g. `department.worksFor = [professor]`
    for a Professor -> Department property), the stated fact is recoverable
    by swapping — losslessly moving the assertion onto the target.
    Ambiguous mismatches are left for the retry loop / pruner.
    """
    conforms = _class_conformance_checker(merged)
    object_properties = {
        prop.get("id"): prop for prop in merged.get("object_properties", []) if isinstance(prop, dict)
    }
    individuals = [ind for ind in merged.get("individuals", []) if isinstance(ind, dict)]
    by_id = {ind.get("id"): ind for ind in individuals}

    notes: List[str] = []
    for ind in individuals:
        assertions = ind.get("objectPropertyAssertions")
        if not isinstance(assertions, dict):
            continue
        for property_id in list(assertions):
            prop, targets = object_properties.get(property_id), assertions[property_id]
            if not isinstance(prop, dict) or not isinstance(targets, list):
                continue
            if conforms(ind.get("typeClass"), prop.get("domain", "")):
                continue  # direction is fine; target-range issues are not swaps
            if not conforms(ind.get("typeClass"), prop.get("range", "")):
                continue  # subject fits neither end — not a clean inversion
            remaining = []
            for target_id in targets:
                target = by_id.get(target_id)
                if isinstance(target, dict) and conforms(target.get("typeClass"), prop.get("domain", "")):
                    swapped = target.setdefault("objectPropertyAssertions", {}).setdefault(property_id, [])
                    if ind["id"] not in swapped:
                        swapped.append(ind["id"])
                    notes.append(
                        f"swapped inverted '{property_id}': now '{target_id}' -> '{ind['id']}'"
                    )
                else:
                    remaining.append(target_id)
            if remaining:
                assertions[property_id] = remaining
            else:
                del assertions[property_id]
    return notes


def _remap_dangling_class_references(merged: Dict[str, Any]) -> List[str]:
    """
    Rewrites class references (property domain/range, subClassOf, typeClass)
    that don't match any declared class id but unambiguously normalize to one
    (e.g. 'Class_Persona ' vs 'Class_Persona', or 'DeptEnergia' vs
    'DepartamentoEnergia'). Cross-language hallucinations ('GeneralDirection'
    for 'DireccionGeneral' — observed live) won't match and are left for the
    retry loop and, ultimately, _prune_invalid_assertions.
    """
    classes = [cls for cls in merged.get("classes", []) if isinstance(cls, dict)]
    declared = {cls.get("id") for cls in classes}
    lookup: Dict[str, str] = {}
    for cls in classes:
        for candidate in (cls.get("id") or "", cls.get("name") or ""):
            normalized = _normalize_reference(candidate)
            if normalized:
                lookup.setdefault(normalized, cls["id"])

    notes: List[str] = []

    def fix(container: Dict[str, Any], field: str, owner: str) -> None:
        value = container.get(field)
        if not isinstance(value, str) or value in declared:
            return
        match = _fuzzy_individual_match(value, lookup)
        if match:
            container[field] = match
            notes.append(f"remapped {field} '{value}' -> '{match}' in '{owner}'")

    for cls in classes:
        if cls.get("subClassOf"):
            fix(cls, "subClassOf", cls.get("id", "?"))
    for category in ("object_properties", "data_properties"):
        for prop in merged.get(category, []):
            if isinstance(prop, dict):
                fix(prop, "domain", prop.get("id", "?"))
                if category == "object_properties":
                    fix(prop, "range", prop.get("id", "?"))
    for ind in merged.get("individuals", []):
        if isinstance(ind, dict):
            fix(ind, "typeClass", ind.get("id", "?"))
    return notes


def _remap_dangling_individual_references(merged: Dict[str, Any]) -> List[str]:
    """
    Rewrites assertion targets that don't match any declared individual id
    but unambiguously normalize to one. Mutates `merged` in place and
    returns a note per rewrite; unmatchable targets are left untouched (the
    retry loop, and ultimately _prune_invalid_assertions, deal with those).
    """
    individuals = [ind for ind in merged.get("individuals", []) if isinstance(ind, dict)]
    declared = {ind.get("id") for ind in individuals}
    lookup: Dict[str, str] = {}
    for ind in individuals:
        for candidate in (ind.get("id") or "", ind.get("name") or ""):
            normalized = _normalize_reference(candidate)
            if normalized:
                lookup.setdefault(normalized, ind["id"])

    notes: List[str] = []
    for ind in individuals:
        assertions = ind.get("objectPropertyAssertions")
        if not isinstance(assertions, dict):
            continue
        for property_id, targets in assertions.items():
            if not isinstance(targets, list):
                continue
            for index, target in enumerate(targets):
                if target in declared:
                    continue
                match = _fuzzy_individual_match(str(target), lookup)
                if match:
                    targets[index] = match
                    notes.append(f"remapped '{target}' -> '{match}' in '{ind.get('id')}'.{property_id}")
    return notes


def _prune_invalid_assertions(merged: Dict[str, Any]) -> List[str]:
    """
    Last-resort degradation once retries are exhausted: drops assertions
    whose property or target was never declared, or which violate the
    declared domain/range, so the user gets a valid (slightly poorer) graph
    instead of a hard failure. Declared structure (classes, properties,
    individuals) is never touched — only the offending assertion entries
    are removed.
    """
    notes: List[str] = []

    # Structural pruning first: a property whose domain/range was never
    # declared (e.g. a hallucinated range the retries never fixed — observed
    # live) or an individual of an undeclared class can never become valid,
    # so they are removed before the assertion pass, which then also drops
    # every assertion that referenced them.
    class_ids = {cls.get("id") for cls in merged.get("classes", []) if isinstance(cls, dict)}
    for cls in merged.get("classes", []):
        if isinstance(cls, dict) and cls.get("subClassOf") and cls["subClassOf"] not in class_ids:
            notes.append(f"dropped dangling subClassOf '{cls['subClassOf']}' from '{cls.get('id')}'")
            cls["subClassOf"] = None
    for category, needs_range in (("object_properties", True), ("data_properties", False)):
        kept_props = []
        for prop in merged.get(category, []):
            dangling = isinstance(prop, dict) and (
                prop.get("domain") not in class_ids
                or (needs_range and prop.get("range") not in class_ids)
            )
            if dangling:
                notes.append(f"dropped property '{prop.get('id')}' with undeclared domain or range")
            else:
                kept_props.append(prop)
        merged[category] = kept_props
    kept_inds = []
    for ind in merged.get("individuals", []):
        if isinstance(ind, dict) and ind.get("typeClass") not in class_ids:
            notes.append(f"dropped individual '{ind.get('id')}' of undeclared class '{ind.get('typeClass')}'")
        else:
            kept_inds.append(ind)
    merged["individuals"] = kept_inds

    conforms = _class_conformance_checker(merged)
    object_properties = {
        prop.get("id"): prop for prop in merged.get("object_properties", []) if isinstance(prop, dict)
    }
    data_properties = {
        prop.get("id"): prop for prop in merged.get("data_properties", []) if isinstance(prop, dict)
    }
    individuals = [ind for ind in merged.get("individuals", []) if isinstance(ind, dict)]
    individuals_by_id = {ind.get("id"): ind for ind in individuals}
    for ind in individuals:
        op_assertions = ind.get("objectPropertyAssertions")
        if isinstance(op_assertions, dict):
            for property_id in list(op_assertions):
                prop, targets = object_properties.get(property_id), op_assertions[property_id]
                if not isinstance(prop, dict) or not isinstance(targets, list):
                    notes.append(f"dropped undeclared object property '{property_id}' from '{ind.get('id')}'")
                    del op_assertions[property_id]
                    continue
                if not conforms(ind.get("typeClass"), prop.get("domain", "")):
                    notes.append(
                        f"dropped non-conforming assertion '{property_id}' from '{ind.get('id')}'"
                    )
                    del op_assertions[property_id]
                    continue
                kept = []
                for target in targets:
                    target_ind = individuals_by_id.get(target)
                    if target_ind is None:
                        notes.append(f"dropped dangling target '{target}' from '{ind.get('id')}'.{property_id}")
                    elif not conforms(target_ind.get("typeClass"), prop.get("range", "")):
                        notes.append(
                            f"dropped out-of-range target '{target}' from '{ind.get('id')}'.{property_id}"
                        )
                    else:
                        kept.append(target)
                if kept:
                    op_assertions[property_id] = kept
                else:
                    del op_assertions[property_id]
        dp_assertions = ind.get("dataPropertyAssertions")
        if isinstance(dp_assertions, dict):
            for property_id in list(dp_assertions):
                prop = data_properties.get(property_id)
                if not isinstance(prop, dict):
                    notes.append(f"dropped undeclared data property '{property_id}' from '{ind.get('id')}'")
                    del dp_assertions[property_id]
                elif not conforms(ind.get("typeClass"), prop.get("domain", "")):
                    notes.append(
                        f"dropped non-conforming data property '{property_id}' from '{ind.get('id')}'"
                    )
                    del dp_assertions[property_id]
    return notes


async def validator_node(state: OntologyGenerationState) -> Dict[str, Any]:
    merged = {
        "classes": state.get("classes", []),
        "object_properties": state.get("object_properties", []),
        "data_properties": state.get("data_properties", []),
        "individuals": state.get("individuals", []),
    }
    valid, error = validate_ontonova_json(merged)

    if not valid:
        # Lossless repairs first — none of these discard information, so
        # they're always preferable to spending an LLM retry.
        repair_notes = (
            _dedupe_global_ids(merged)
            + _remap_dangling_class_references(merged)
            + _remap_dangling_individual_references(merged)
            + _swap_inverted_object_assertions(merged)
        )
        if repair_notes:
            logger.info("validator repaired: %s", "; ".join(repair_notes))
            valid, error = validate_ontonova_json(merged)

    if valid:
        # Re-serialize through the validated model so every optional field
        # with a default (e.g. an individual's dataPropertyAssertions) is
        # normalized before reaching the frontend — the LLM's raw JSON is
        # free to omit them (they're not required by the schema), but the
        # frontend's TS types declare them as always present.
        normalized = OntoNovaSchema(**merged).model_dump()
        return {
            "status": "valid",
            "last_error": None,
            "retry_stage": None,
            "classes": normalized["classes"],
            "object_properties": normalized["object_properties"],
            "data_properties": normalized["data_properties"],
            "individuals": normalized["individuals"],
        }

    retries = state.get("retries", 0) + 1
    if retries > MAX_RETRIES:
        prune_notes = _prune_invalid_assertions(merged)
        if prune_notes:
            pruned_valid, _pruned_error = validate_ontonova_json(merged)
            if pruned_valid:
                logger.warning(
                    "validator degraded gracefully after exhausting retries: %s",
                    "; ".join(prune_notes),
                )
                normalized = OntoNovaSchema(**merged).model_dump()
                return {
                    "status": "valid",
                    "last_error": None,
                    "retry_stage": None,
                    "retries": retries,
                    "classes": normalized["classes"],
                    "object_properties": normalized["object_properties"],
                    "data_properties": normalized["data_properties"],
                    "individuals": normalized["individuals"],
                }
        return {"status": "failed", "last_error": error, "retries": retries}

    return {
        "status": "retrying",
        "last_error": error,
        "retry_stage": _stage_from_error(error),
        "retries": retries,
    }


def route_after_validation(state: OntologyGenerationState) -> str:
    if state.get("status") in ("valid", "failed"):
        return END
    return state.get("retry_stage", "taxonomist")


def build_graph():
    graph = StateGraph(OntologyGenerationState)
    graph.add_node("taxonomist", taxonomist_node)
    graph.add_node("relational", relational_node)
    graph.add_node("populator", populator_node)
    graph.add_node("validator", validator_node)

    graph.set_entry_point("taxonomist")
    graph.add_edge("taxonomist", "relational")
    graph.add_edge("relational", "populator")
    graph.add_edge("populator", "validator")
    graph.add_conditional_edges(
        "validator",
        route_after_validation,
        {
            "taxonomist": "taxonomist",
            "relational": "relational",
            "populator": "populator",
            END: END,
        },
    )
    return graph.compile()


_compiled_graph = None


def get_compiled_graph():
    global _compiled_graph
    if _compiled_graph is None:
        _compiled_graph = build_graph()
    return _compiled_graph


async def stream_ontology_generation(text: str, language: str) -> AsyncIterator[Dict[str, Any]]:
    """
    Runs the taxonomist -> relational -> populator -> validator pipeline,
    yielding one progress event per completed stage so the router can push
    each as an SSE frame in real time (REQ-US-FC-02).
    """
    if len(text) > MAX_INPUT_CHARS:
        # `code`/`params` let the frontend render this in the UI language
        # (the `error` text is the English fallback for direct API clients).
        failure = {
            "status": "failed",
            "error": (
                f"The document is too long for the model's context window: "
                f"{len(text):,} characters received, but the maximum is "
                f"{MAX_INPUT_CHARS:,}. Please provide a shorter text or "
                f"extract the relevant section."
            ),
            "code": "input_too_long",
            "params": {"count": len(text), "max": MAX_INPUT_CHARS},
        }
        yield {"stage": "generation", **failure}
        yield {"stage": "done", **failure}
        return

    graph = get_compiled_graph()
    initial_state: OntologyGenerationState = {
        "input_text": text,
        "language": language,
        "classes": [],
        "object_properties": [],
        "data_properties": [],
        "individuals": [],
        "status": "in_progress",
        "last_error": None,
        "retry_stage": None,
        "retries": 0,
    }

    final_state: Dict[str, Any] = dict(initial_state)

    try:
        async for update in graph.astream(initial_state, stream_mode="updates"):
            for node_name, node_output in update.items():
                final_state.update(node_output)
                if node_name == "validator":
                    if final_state["status"] == "valid":
                        yield {"stage": "validator", "status": "completed"}
                    elif final_state["status"] == "failed":
                        yield {
                            "stage": "validator",
                            "status": "failed",
                            "error": final_state.get("last_error"),
                        }
                    else:
                        yield {
                            "stage": "validator",
                            "status": "retrying",
                            "error": final_state.get("last_error"),
                        }
                else:
                    yield {"stage": node_name, "status": "completed"}
    except LLMGenerationError as exc:
        # The client treats ONLY stage "done" as terminal (it drives the
        # spinner/submit state), so every failure path must end with one —
        # without it the UI spins forever on a generation that already died
        # (observed live with an over-length PDF). The "generation" frame is
        # kept as the diagnostic detail.
        failure = {"status": "failed", "error": str(exc), "code": "llm_error"}
        yield {"stage": "generation", **failure}
        yield {"stage": "done", **failure}
        return
    except Exception as exc:  # noqa: BLE001 - last resort so the SSE stream
        # always ends with a terminal event instead of the connection just
        # dying mid-stream (which the client can't distinguish from a
        # network drop) — REQ-US-FC-03's "elegant degradation" applies to
        # unexpected bugs here too, not only known LLM failures.
        failure = {"status": "failed", "error": f"Unexpected error: {exc}", "code": "unexpected_error"}
        yield {"stage": "generation", **failure}
        yield {"stage": "done", **failure}
        return

    if final_state.get("status") == "valid":
        yield {
            "stage": "done",
            "status": "success",
            "payload": {
                "classes": final_state.get("classes", []),
                "object_properties": final_state.get("object_properties", []),
                "data_properties": final_state.get("data_properties", []),
                "individuals": final_state.get("individuals", []),
            },
        }
    else:
        yield {
            "stage": "done",
            "status": "failed",
            "error": final_state.get("last_error", "Ontology generation failed."),
        }
