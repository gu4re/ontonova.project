"""
Acceptance test: semantic quality of a generated graph vs a gold standard.

Unlike the unit suite (which mocks the LLM), this test drives the REAL
/generate pipeline end-to-end (backend + vLLM must be up: `docker compose up
vllm backend`) with a fixed English domain text whose ideal ontology was
hand-crafted below, then scores the app's output against it with
precision/recall/F1 per category.

Run:
    PYTHONPATH=. ./api/bin/python -m pytest api/acceptance-tests/scrum-3/graph-quality/main.py -v -s

Env knobs:
    BACKEND_BASE_URL              (default http://localhost:8001)
    GRAPH_QUALITY_MIN_MACRO_F1    soft acceptance floor (default 0.5)
"""

import json
import os
import re
import unicodedata
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import httpx
import pytest

BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "http://localhost:8001")
MIN_MACRO_F1 = float(os.getenv("GRAPH_QUALITY_MIN_MACRO_F1", "0.5"))
# "" reproduces the UI's default (auto-detect), which yields a different
# prompt — and different model behavior — than an explicit language hint.
LANGUAGE = os.getenv("GRAPH_QUALITY_LANGUAGE", "English")
REPORT_PATH = Path(__file__).parent / "graph-quality-report.json"

# =====================================================================
# FIXED INPUT + GOLD STANDARD
# The text states every gold fact explicitly, so a perfect extractor
# could reach F1 = 1.0 — every miss below is a genuine extraction gap.
# =====================================================================
DOMAIN_TEXT = (
    "At Cambridge University, which was founded in 1209, the Department of "
    "Computer Science offers several courses. Professors and students are "
    "both persons affiliated with the university. Professor Alan Turing, "
    "who is 41 years old, works for the Department of Computer Science and "
    "teaches the course Computability Theory, which is worth 6 credits. The "
    "student Ada Lovelace is enrolled in Computability Theory. Professor "
    "Turing also supervises Ada Lovelace during her studies. Every course "
    "is offered by exactly one department, and each department is part of "
    "the university. Practical sessions of Computability Theory take place "
    "in the Turing Laboratory, a facility of the department."
)

# Gold classes: key -> (acceptable name/id aliases, gold parent key or None)
GOLD_CLASSES: Dict[str, Tuple[List[str], Optional[str]]] = {
    "person": (["person", "persona"], None),
    "professor": (["professor", "profesor", "teacher"], "person"),
    "student": (["student", "estudiante"], "person"),
    "course": (["course", "curso"], None),
    "department": (["department", "departamento", "dept"], None),
    "university": (["university", "universidad"], None),
    "laboratory": (["laboratory", "lab", "facility", "laboratorio"], None),
}

# Gold object properties: key -> (aliases, domain key, range key).
# Class pairs are unique on purpose, so (domain, range) alone identifies the
# relation and naming differences ("imparte"/"teaches") don't cost points.
GOLD_OBJECT_PROPERTIES: Dict[str, Tuple[List[str], str, str]] = {
    "teaches": (["teaches", "imparte", "teach"], "professor", "course"),
    "enrolledIn": (["enrolledin", "isenrolledin", "matriculadoen", "enrolls"], "student", "course"),
    "supervises": (["supervises", "supervisa", "supervise"], "professor", "student"),
    "worksFor": (["worksfor", "worksat", "trabajapara", "employedby"], "professor", "department"),
    "offeredBy": (["offeredby", "isofferedby", "offers", "ofrecidopor"], "course", "department"),
    "partOf": (["partof", "ispartof", "belongsto", "partede"], "department", "university"),
    "takesPlaceIn": (
        ["takesplacein", "heldin", "conductedin", "takesplaceat", "locatedin"],
        "course",
        "laboratory",
    ),
    # "Professors and students are both persons affiliated with the
    # university" — stated class-level, so no individual assertion is
    # required for it in GOLD_OP_ASSERTIONS.
    "affiliatedWith": (["affiliatedwith", "isaffiliatedwith", "memberof"], "person", "university"),
}

_NUMERIC = {"xsd:integer", "xsd:float"}
# Gold data properties: key -> (aliases, domain key, acceptable xsd ranges)
GOLD_DATA_PROPERTIES: Dict[str, Tuple[List[str], List[str], set]] = {
    # age can legitimately hang off Person or Professor
    "age": (["age", "edad", "hasage", "yearsold"], ["professor", "person"], _NUMERIC),
    "credits": (["credits", "credit", "creditos", "worth"], ["course"], _NUMERIC),
    "foundedYear": (
        ["foundedyear", "founded", "foundingyear", "yearfounded", "fundacion", "foundedin"],
        ["university"],
        _NUMERIC | {"xsd:dateTime", "xsd:string"},
    ),
}

# Gold individuals: key -> (aliases, gold class key)
GOLD_INDIVIDUALS: Dict[str, Tuple[List[str], str]] = {
    "turing": (["alanturing", "turing", "profesoralanturing", "professoralanturing"], "professor"),
    "ada": (["adalovelace", "ada", "lovelace"], "student"),
    "computability": (["computabilitytheory", "computability"], "course"),
    "csdept": (
        [
            "departmentofcomputerscience",
            "computersciencedepartment",
            "computerscience",
            "csdepartment",
        ],
        "department",
    ),
    "cambridge": (["cambridgeuniversity", "cambridge"], "university"),
    "turinglab": (["turinglaboratory", "turinglab"], "laboratory"),
}

# Gold relation assertions between individuals: (object property, subject, object)
GOLD_OP_ASSERTIONS = [
    ("teaches", "turing", "computability"),
    ("enrolledIn", "ada", "computability"),
    ("supervises", "turing", "ada"),
    ("worksFor", "turing", "csdept"),
    ("offeredBy", "computability", "csdept"),
    ("partOf", "csdept", "cambridge"),
    ("takesPlaceIn", "computability", "turinglab"),
]

# Gold literal assertions: (data property, individual, expected value)
GOLD_DP_ASSERTIONS = [
    ("age", "turing", 41),
    ("credits", "computability", 6),
    ("foundedYear", "cambridge", 1209),
]

# Generated items matching these are neither rewarded nor punished: the
# individuals' `name` field already carries names, but declaring an explicit
# name/title data property is a stylistic choice, not an extraction error.
NEUTRAL_DATA_PROPERTY_ALIASES = {"name", "hasname", "nombre", "title", "fullname"}


# =====================================================================
# NORMALIZATION + MATCHING HELPERS
# =====================================================================
def norm(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    value = re.sub(r"[^a-z0-9]", "", value.lower())
    # naive singular so "professors" still hits "professor"
    return value[:-1] if value.endswith("s") and len(value) > 3 else value


def strip_prefix(identifier: str) -> str:
    return re.sub(r"^(class|prop|attr|inst)_?", "", identifier, flags=re.IGNORECASE)


def matches(candidates: List[str], aliases: List[str]) -> bool:
    for candidate in candidates:
        n = norm(candidate)
        if not n:
            continue
        for alias in aliases:
            a = norm(alias)
            if n == a or n.endswith(a) or a.endswith(n):
                return True
    return False


def f1(precision: float, recall: float) -> float:
    return 0.0 if precision + recall == 0 else 2 * precision * recall / (precision + recall)


def score(matched: int, generated: int, gold: int) -> Dict[str, float]:
    precision = matched / generated if generated else 0.0
    recall = matched / gold if gold else 1.0
    return {
        "matched": matched,
        "generated": generated,
        "gold": gold,
        "precision": round(precision, 3),
        "recall": round(recall, 3),
        "f1": round(f1(precision, recall), 3),
    }


# =====================================================================
# PIPELINE DRIVER
# =====================================================================
def generate_ontology(text: str) -> Dict[str, Any]:
    """POSTs /generate and returns the final 'done' SSE payload."""
    events: List[Dict[str, Any]] = []
    with httpx.Client(timeout=900) as client:
        with client.stream(
            "POST",
            f"{BACKEND_BASE_URL}/api/ontologies/generate",
            json={"text": text, "language": LANGUAGE},
        ) as response:
            response.raise_for_status()
            for line in response.iter_lines():
                line = line.strip()
                if line.startswith("data:"):
                    events.append(json.loads(line[len("data:") :].strip()))

    done = next((event for event in events if event.get("stage") == "done"), None)
    assert done is not None, f"stream ended without a terminal event: {events}"
    assert done.get("status") == "success", f"generation failed: {done.get('error')}"
    retries = sum(1 for event in events if event.get("status") == "retrying")
    return {"payload": done["payload"], "retries": retries, "events": events}


# =====================================================================
# SCORING
# =====================================================================
def evaluate(payload: Dict[str, Any]) -> Dict[str, Any]:
    report: Dict[str, Any] = {"categories": {}, "misses": {}, "spurious": {}}

    # ---- classes ----------------------------------------------------
    class_map: Dict[str, str] = {}  # generated class id -> gold key
    for cls in payload["classes"]:
        for key, (aliases, _parent) in GOLD_CLASSES.items():
            if key not in class_map.values() and matches([cls["name"], strip_prefix(cls["id"])], aliases):
                class_map[cls["id"]] = key
                break
    report["categories"]["classes"] = score(
        len(class_map), len(payload["classes"]), len(GOLD_CLASSES)
    )
    report["misses"]["classes"] = sorted(set(GOLD_CLASSES) - set(class_map.values()))
    report["spurious"]["classes"] = [
        cls["name"] for cls in payload["classes"] if cls["id"] not in class_map
    ]

    # ---- hierarchy (subClassOf edges among matched classes) ---------
    gold_edges = {(child, parent) for child, (_a, parent) in GOLD_CLASSES.items() if parent}
    found_edges = set()
    for cls in payload["classes"]:
        child = class_map.get(cls["id"])
        parent = class_map.get(cls.get("subClassOf") or "")
        if child and parent and (child, parent) in gold_edges:
            found_edges.add((child, parent))
    report["categories"]["hierarchy"] = score(len(found_edges), len(found_edges), len(gold_edges))
    report["misses"]["hierarchy"] = sorted(
        f"{child} subClassOf {parent}" for child, parent in gold_edges - found_edges
    )

    # ---- object properties (matched primarily by class pair) --------
    def compatible(generated_key: Optional[str], gold_key: str) -> bool:
        # Declaring a property one level up the gold hierarchy (e.g. domain
        # Person instead of Professor for `teaches`) is looser modeling,
        # not a wrong fact — accept parent/child of the gold class.
        if generated_key == gold_key:
            return True
        if generated_key is None:
            return False
        return (
            GOLD_CLASSES[gold_key][1] == generated_key
            or GOLD_CLASSES[generated_key][1] == gold_key
        )

    op_map: Dict[str, Tuple[str, bool]] = {}  # generated op id -> (gold key, inverted?)
    # Two passes: name-alias agreement first, class-pair-only as fallback —
    # otherwise a widened pair like Person -> Course is ambiguous between
    # `teaches` and `enrolledIn` and first-declared wins arbitrarily.
    for require_alias in (True, False):
        for op in payload["object_properties"]:
            if op["id"] in op_map:
                continue
            domain, range_ = class_map.get(op["domain"]), class_map.get(op["range"])
            for key, (aliases, gold_domain, gold_range) in GOLD_OBJECT_PROPERTIES.items():
                if key in (k for k, _inv in op_map.values()):
                    continue
                if require_alias and not matches([op["name"], strip_prefix(op["id"])], aliases):
                    continue
                if compatible(domain, gold_domain) and compatible(range_, gold_range):
                    op_map[op["id"]] = (key, False)
                    break
                if compatible(domain, gold_range) and compatible(range_, gold_domain):
                    op_map[op["id"]] = (key, True)  # inverse orientation still conveys the fact
                    break
    report["categories"]["object_properties"] = score(
        len(op_map), len(payload["object_properties"]), len(GOLD_OBJECT_PROPERTIES)
    )
    report["misses"]["object_properties"] = sorted(
        set(GOLD_OBJECT_PROPERTIES) - {k for k, _inv in op_map.values()}
    )
    report["spurious"]["object_properties"] = [
        f'{op["name"]} ({op["domain"]} -> {op["range"]})'
        for op in payload["object_properties"]
        if op["id"] not in op_map
    ]

    # ---- data properties ---------------------------------------------
    dp_map: Dict[str, str] = {}
    neutral = 0
    for dp in payload["data_properties"]:
        candidates = [dp["name"], strip_prefix(dp["id"])]
        if matches(candidates, sorted(NEUTRAL_DATA_PROPERTY_ALIASES)):
            neutral += 1
            continue
        domain = class_map.get(dp["domain"])
        for key, (aliases, gold_domains, gold_ranges) in GOLD_DATA_PROPERTIES.items():
            if key in dp_map.values():
                continue
            if domain in gold_domains and dp["range"] in gold_ranges and matches(candidates, aliases):
                dp_map[dp["id"]] = key
                break
    report["categories"]["data_properties"] = score(
        len(dp_map), len(payload["data_properties"]) - neutral, len(GOLD_DATA_PROPERTIES)
    )
    report["misses"]["data_properties"] = sorted(set(GOLD_DATA_PROPERTIES) - set(dp_map.values()))
    report["spurious"]["data_properties"] = [
        f'{dp["name"]} ({dp["domain"]}: {dp["range"]})'
        for dp in payload["data_properties"]
        if dp["id"] not in dp_map and not matches([dp["name"]], sorted(NEUTRAL_DATA_PROPERTY_ALIASES))
    ]

    # ---- individuals --------------------------------------------------
    ind_map: Dict[str, str] = {}
    for ind in payload["individuals"]:
        for key, (aliases, gold_class) in GOLD_INDIVIDUALS.items():
            if key in ind_map.values():
                continue
            if matches([ind["name"], strip_prefix(ind["id"])], aliases) and class_map.get(
                ind["typeClass"]
            ) == gold_class:
                ind_map[ind["id"]] = key
                break
    report["categories"]["individuals"] = score(
        len(ind_map), len(payload["individuals"]), len(GOLD_INDIVIDUALS)
    )
    report["misses"]["individuals"] = sorted(set(GOLD_INDIVIDUALS) - set(ind_map.values()))
    report["spurious"]["individuals"] = [
        ind["name"] for ind in payload["individuals"] if ind["id"] not in ind_map
    ]

    # ---- assertions ----------------------------------------------------
    inverse_ind = {v: k for k, v in ind_map.items()}
    found_ops = 0
    op_misses = []
    for gold_op, gold_subject, gold_object in GOLD_OP_ASSERTIONS:
        hit = False
        for ind in payload["individuals"]:
            for prop_id, targets in ind.get("objectPropertyAssertions", {}).items():
                key, inverted = op_map.get(prop_id, (None, False))
                if key != gold_op:
                    continue
                subject, object_ = (gold_object, gold_subject) if inverted else (gold_subject, gold_object)
                if ind_map.get(ind["id"]) == subject and inverse_ind.get(object_) in targets:
                    hit = True
        found_ops += hit
        if not hit:
            op_misses.append(f"{gold_subject} --{gold_op}--> {gold_object}")
    report["categories"]["op_assertions"] = score(found_ops, found_ops, len(GOLD_OP_ASSERTIONS))
    report["misses"]["op_assertions"] = op_misses

    found_dps = 0
    dp_misses = []
    for gold_dp, gold_ind, expected in GOLD_DP_ASSERTIONS:
        hit = False
        for ind in payload["individuals"]:
            if ind_map.get(ind["id"]) != gold_ind:
                continue
            for prop_id, value in ind.get("dataPropertyAssertions", {}).items():
                if dp_map.get(prop_id) == gold_dp and str(expected) in str(value):
                    hit = True
        found_dps += hit
        if not hit:
            dp_misses.append(f"{gold_ind}.{gold_dp} = {expected}")
    report["categories"]["dp_assertions"] = score(found_dps, found_dps, len(GOLD_DP_ASSERTIONS))
    report["misses"]["dp_assertions"] = dp_misses

    scores = [category["f1"] for category in report["categories"].values()]
    report["macro_f1"] = round(sum(scores) / len(scores), 3)
    return report


# =====================================================================
# ACCEPTANCE TEST
# =====================================================================
def test_graph_quality_against_gold_standard():
    try:
        httpx.get(f"{BACKEND_BASE_URL}/health", timeout=5).raise_for_status()
    except httpx.HTTPError:
        pytest.skip(f"backend not reachable at {BACKEND_BASE_URL} — start it with `docker compose up vllm backend`")

    print("\n=========================================")
    print("📊 RUNNING ACCEPTANCE TEST: GRAPH QUALITY")
    print("=========================================")

    result = generate_ontology(DOMAIN_TEXT)
    payload, retries = result["payload"], result["retries"]
    print(
        f"generated: {len(payload['classes'])} classes, "
        f"{len(payload['object_properties'])} object properties, "
        f"{len(payload['data_properties'])} data properties, "
        f"{len(payload['individuals'])} individuals "
        f"({retries} self-healing retr{'y' if retries == 1 else 'ies'})"
    )

    report = evaluate(payload)
    report["retries"] = retries
    report["payload"] = payload

    print(f"\n{'category':<20}{'P':>7}{'R':>7}{'F1':>7}")
    for name, category in report["categories"].items():
        print(f"{name:<20}{category['precision']:>7.2f}{category['recall']:>7.2f}{category['f1']:>7.2f}")
    print(f"{'macro F1':<20}{report['macro_f1']:>21.2f}")

    for section in ("misses", "spurious"):
        for name, items in report[section].items():
            if items:
                print(f"{section}.{name}: {items}")

    REPORT_PATH.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nfull report: {REPORT_PATH}")

    assert report["macro_f1"] >= MIN_MACRO_F1, (
        f"macro F1 {report['macro_f1']} below acceptance floor {MIN_MACRO_F1} "
        f"(misses: {report['misses']})"
    )
