from .models import OntoNovaSchema
from pydantic import ValidationError
from typing import Dict, List, Optional

# Pipeline order — used to decide who's "at fault" in a cross-category id
# collision: the later-produced entity should have picked a name that didn't
# clash with something already declared earlier, not the other way around.
_PIPELINE_STAGES = ["classes", "object_properties", "data_properties", "individuals"]


def _check_id_uniqueness(schema: OntoNovaSchema) -> List[str]:
    """
    services.rdf_compiler maps every class/object-property/data-property/
    individual id into the SAME flat RDF namespace, so an id reused across
    categories (e.g. a class "Manager" and an individual "Manager") would
    silently collide onto one URI and corrupt the exported ontology.

    Each error is prefixed with the single category that should fix it (the
    latest-produced one) — never a list of all four category names — so
    core.graph's self-healing router can't mistake "classes" appearing in an
    explanatory aside for classes actually being at fault (see graph.py's
    _stage_from_error, which trusts only this leading prefix).
    """
    occurrences: Dict[str, List[str]] = {}
    for cls in schema.classes:
        occurrences.setdefault(cls.id, []).append("classes")
    for prop in schema.object_properties:
        occurrences.setdefault(prop.id, []).append("object_properties")
    for prop in schema.data_properties:
        occurrences.setdefault(prop.id, []).append("data_properties")
    for individual in schema.individuals:
        occurrences.setdefault(individual.id, []).append("individuals")

    errors: List[str] = []
    for id_, categories in occurrences.items():
        if len(categories) <= 1:
            continue
        blamed = max(categories, key=_PIPELINE_STAGES.index)
        earlier = sorted({category for category in categories if category != blamed})
        if earlier:
            errors.append(
                f"{blamed}: id '{id_}' collides with an id already declared in "
                f"{' and '.join(earlier)} — ids must be globally unique, pick a different one"
            )
        else:
            errors.append(
                f"{blamed}: id '{id_}' is declared more than once in {blamed} — "
                "ids must be globally unique"
            )
    return errors


def _check_referential_integrity(schema: OntoNovaSchema) -> List[str]:
    """
    Structural (Pydantic) validation alone lets an LLM reference a class or
    property id that was never declared elsewhere in the same payload
    (e.g. an object property whose `range` doesn't match any known class).
    This catches that dangling-reference class of error so a "well-formed"
    ontology (REQ-US-FC-03) means semantically consistent, not just
    shape-valid, and so the self-healing loop in core.graph can catch it too.
    """
    errors: List[str] = []
    class_ids = {cls.id for cls in schema.classes}
    object_property_ids = {prop.id for prop in schema.object_properties}
    data_property_ids = {prop.id for prop in schema.data_properties}
    individual_ids = {individual.id for individual in schema.individuals}

    for cls in schema.classes:
        if cls.subClassOf and cls.subClassOf not in class_ids:
            errors.append(
                f"classes: class '{cls.id}' has subClassOf '{cls.subClassOf}' "
                "which is not a declared class id"
            )

    for prop in schema.object_properties:
        if prop.domain not in class_ids:
            errors.append(
                f"object_properties: property '{prop.id}' has domain '{prop.domain}' "
                "which is not a declared class id"
            )
        if prop.range not in class_ids:
            errors.append(
                f"object_properties: property '{prop.id}' has range '{prop.range}' "
                "which is not a declared class id"
            )

    for prop in schema.data_properties:
        if prop.domain not in class_ids:
            errors.append(
                f"data_properties: property '{prop.id}' has domain '{prop.domain}' "
                "which is not a declared class id"
            )

    for individual in schema.individuals:
        if individual.typeClass not in class_ids:
            errors.append(
                f"individuals: individual '{individual.id}' has typeClass '{individual.typeClass}' "
                "which is not a declared class id"
            )
        for property_id, target_ids in individual.objectPropertyAssertions.items():
            if property_id not in object_property_ids:
                errors.append(
                    f"individuals: individual '{individual.id}' asserts undeclared "
                    f"object property '{property_id}'"
                )
            for target_id in target_ids:
                if target_id not in individual_ids:
                    errors.append(
                        f"individuals: individual '{individual.id}' asserts a relation to "
                        f"undeclared individual '{target_id}'"
                    )
        for property_id in individual.dataPropertyAssertions:
            if property_id not in data_property_ids:
                errors.append(
                    f"individuals: individual '{individual.id}' asserts undeclared "
                    f"data property '{property_id}'"
                )

    return errors


def _check_assertion_conformance(schema: OntoNovaSchema) -> List[str]:
    """
    Checks that every assertion respects the declared property's domain and
    range (subclass-aware). In pure OWL semantics domain/range axioms infer
    types rather than constrain them, but under this app's closed contract a
    mismatch almost always means the LLM asserted the relation on the wrong
    subject — e.g. `department.worksFor = [professor]` for a Professor ->
    Department property (observed in the scrum-3 graph-quality run, where
    most relation assertions came out inverted and validated silently).
    Flagging it lets the self-healing loop repair the direction.
    """
    class_parent = {cls.id: cls.subClassOf for cls in schema.classes}

    def conforms(candidate: Optional[str], ancestor: str) -> bool:
        seen = set()
        while candidate and candidate not in seen:
            if candidate == ancestor:
                return True
            seen.add(candidate)
            candidate = class_parent.get(candidate)
        return False

    object_properties = {prop.id: prop for prop in schema.object_properties}
    data_properties = {prop.id: prop for prop in schema.data_properties}
    individuals = {individual.id: individual for individual in schema.individuals}

    errors: List[str] = []
    for individual in schema.individuals:
        for property_id, target_ids in individual.objectPropertyAssertions.items():
            prop = object_properties.get(property_id)
            if prop is None:
                continue  # undeclared ids are _check_referential_integrity's job
            if not conforms(individual.typeClass, prop.domain):
                errors.append(
                    f"individuals: individual '{individual.id}' (class '{individual.typeClass}') "
                    f"asserts '{property_id}' whose domain is '{prop.domain}' — the assertion "
                    f"direction is probably inverted; assert it on the '{prop.domain}' "
                    "individual pointing at this one instead"
                )
            for target_id in target_ids:
                target = individuals.get(target_id)
                if target is not None and not conforms(target.typeClass, prop.range):
                    errors.append(
                        f"individuals: individual '{individual.id}' asserts '{property_id}' "
                        f"towards '{target_id}' (class '{target.typeClass}') but the "
                        f"property's range is '{prop.range}'"
                    )
        for property_id in individual.dataPropertyAssertions:
            prop = data_properties.get(property_id)
            if prop is not None and not conforms(individual.typeClass, prop.domain):
                errors.append(
                    f"individuals: individual '{individual.id}' (class '{individual.typeClass}') "
                    f"asserts data property '{property_id}' whose domain is '{prop.domain}'"
                )
    return errors


def _format_pydantic_errors(errors: List[dict]) -> str:
    """
    Reformats Pydantic's error list into the same "{category}: ..." leading
    prefix convention used by the checks above, so core.graph's
    self-healing router only ever has to understand one error format
    (see graph.py's _stage_from_error) instead of Pydantic's raw repr.
    """
    formatted = []
    for error in errors:
        loc = error.get("loc", ())
        category = str(loc[0]) if loc else "schema"
        path = ".".join(str(part) for part in loc[1:])
        location = f"{category}[{path}]" if path else category
        formatted.append(f"{category}: {location} — {error.get('msg', 'invalid value')}")
    return "; ".join(formatted)


def validate_ontonova_json(raw_json: dict) -> tuple[bool, Optional[str]]:
    """
    Valida sintáctica y semánticamente si un JSON cumple con el contrato
    OntoNova. Devuelve (True, None) si es válido, o (False, "Mensaje de
    error") si falla.
    """
    try:
        # Intenta parsear el JSON crudo en nuestro modelo estricto
        schema = OntoNovaSchema(**raw_json)
    except ValidationError as e:
        # Extrae el error estructurado ideal para el Self-Healing de la SCRUM-6
        return False, _format_pydantic_errors(e.errors())

    errors = (
        _check_id_uniqueness(schema)
        + _check_referential_integrity(schema)
        + _check_assertion_conformance(schema)
    )
    if errors:
        return False, "; ".join(errors)

    return True, None