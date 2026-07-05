"""
Acceptance test: graph quality for a REAL-WORLD PDF (a 2-page Simple
Wikipedia article on the okapi, ~193 KB) driven through the full stack.

Two modes:
  * If OKAPI_GRAPH_PATH points at a graph captured by the Playwright
    full-stack e2e (frontend/e2e/okapi-pdf.spec.ts), it grades exactly the
    graph the browser rendered from the in-browser pdf.js extraction.
  * Otherwise, if the backend is reachable, it generates from the same PDF's
    extracted text directly (pdf.js and pypdf produce equivalent text for a
    digitally-authored PDF like this one) and grades that.
  * If neither is available, it skips.

Unlike scrum-3 (a clean synthetic text with a fully determinable ideal),
this measures a messy real document: the gold below is a defensible ideal,
and the point is as much to surface pipeline behavior on real input as to
hit a number. The acceptance floor is deliberately lower.

Run (after `docker compose up`):
    PYTHONPATH=. ./api/bin/python -m pytest api/acceptance-tests/scrum-4/graph-quality-okapi/main.py -v -s
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
# A smoke-level floor, NOT a quality target: it asserts the full-stack path
# produces a non-degenerate, partially-correct graph and never hard-fails on
# this messy real document. Clean synthetic text scores ~1.0 (scrum-3); this
# encyclopedic PDF scores ~0.2 because the model encodes the taxonomy as
# object-property assertions to class ids (which can't resolve to individuals)
# and bundles specific numeric facts into vague string properties — see the
# analysis in the project history. Chasing a higher number here would mean
# overfitting the prompt to one article.
MIN_MACRO_F1 = float(os.getenv("OKAPI_MIN_MACRO_F1", "0.15"))
GRAPH_PATH = os.getenv("OKAPI_GRAPH_PATH", "")
REPORT_PATH = Path(__file__).parent / "okapi-quality-report.json"

# The PDF's extracted text (pypdf), used only for the backend-generate
# fallback so the test is deterministic without the PDF file at runtime.
EXTRACTED_TEXT = (
    "The okapi (Okapia johnstoni), also known as the forest giraffe, zebra "
    "giraffe, and Congolese giraffe, is an even-toed ungulate mammal from "
    "central Africa. With the giraffe they form the family Giraffidae. The "
    "okapi has a reddish brown body, a whitish gray face, and white and black "
    "stripes on its legs. The okapi has a few features that show its link to "
    "giraffes. Its height is not as large as giraffes. Okapis live in the "
    "rainforests of central Africa, in the Democratic Republic of the Congo. "
    "They are mostly active during the day. Okapis eat mostly leaves and buds "
    "from trees, but also grass, ferns, fruit, and fungi. Okapis usually live "
    "alone. After 420 to 450 days of pregnancy the mother gives birth to one "
    "baby okapi, which drinks milk for up to 6 months. Okapis become mature "
    "when they are 4 to 5 years old. In captivity, okapis can live for 30 "
    "years or so. In the past, scientists thought that the okapi was a mix "
    "between the giraffe and the zebra."
)

# =====================================================================
# GOLD STANDARD (an ideal ontology for the text above)
# =====================================================================
GOLD_CLASSES: Dict[str, Tuple[List[str], Optional[str]]] = {
    "animal": (["animal", "mammal", "ungulate", "artiodactyl", "species"], None),
    # The okapi is the genus Okapia / species Okapia johnstoni; models
    # commonly anchor the concept on any of these (and misspell the
    # binomial), so all are valid names for this class.
    "okapi": (["okapi", "forestgiraffe", "okapia", "okapiajohnstoni", "okapiajohnsonii"], "animal"),
    "giraffe": (["giraffe"], "animal"),
    "zebra": (["zebra"], "animal"),
    "family": (["family", "giraffidae", "taxonomicfamily"], None),
    "habitat": (["habitat", "rainforest", "forest"], None),
    "region": (["region", "africa", "centralafrica", "congo", "location", "area"], None),
    "food": (["food", "plant", "diet", "leaf", "leaves", "vegetation", "forage"], None),
}

GOLD_OBJECT_PROPERTIES: Dict[str, Tuple[List[str], str, str]] = {
    "belongsToFamily": (
        ["belongstofamily", "memberoffamily", "family", "formsfamily", "partoffamily", "infamily"],
        "okapi",
        "family",
    ),
    "livesIn": (["livesin", "inhabits", "habitat", "livein", "residesin"], "okapi", "habitat"),
    "eats": (["eats", "feedson", "eat", "consumes", "diet"], "okapi", "food"),
    "relatedTo": (["relatedto", "linkedto", "similarto", "linkto", "relatedspecies"], "okapi", "giraffe"),
    "locatedIn": (["locatedin", "foundin", "inregion", "situatedin"], "habitat", "region"),
}

_NUMERIC = {"xsd:integer", "xsd:float"}
_NUM_OR_STR = _NUMERIC | {"xsd:string", "xsd:dateTime"}
GOLD_DATA_PROPERTIES: Dict[str, Tuple[List[str], List[str], set]] = {
    "gestationPeriod": (
        ["gestation", "pregnancy", "gestationperiod", "pregnancydays", "gestationdays"],
        ["okapi", "animal"],
        _NUM_OR_STR,
    ),
    "nursingPeriod": (
        ["nursing", "milk", "milkmonths", "weaning", "nursingperiod", "drinksmilk"],
        ["okapi", "animal"],
        _NUM_OR_STR,
    ),
    "maturityAge": (
        ["maturity", "matureage", "maturityage", "adultage", "maturesat"],
        ["okapi", "animal"],
        _NUM_OR_STR,
    ),
    "lifespan": (
        ["lifespan", "longevity", "lifeexpectancy", "liveyears", "maxage"],
        ["okapi", "animal"],
        _NUM_OR_STR,
    ),
    "scientificName": (
        ["scientificname", "binomialname", "binomial", "speciesname", "latinname"],
        ["okapi", "animal"],
        {"xsd:string"},
    ),
}

# Descriptive text yields few clean individuals — this category is expected
# to be the weakest, which is itself a finding worth reporting.
GOLD_INDIVIDUALS: Dict[str, Tuple[List[str], str]] = {
    "okapiaJohnstoni": (["okapiajohnstoni", "okapi"], "okapi"),
    "giraffidae": (["giraffidae"], "family"),
    "drCongo": (["democraticrepublicofthecongo", "drc", "congo", "drcongo"], "region"),
}

NEUTRAL_DATA_PROPERTY_ALIASES = {"name", "hasname", "nombre", "title", "fullname", "commonname"}


# =====================================================================
# GENERIC SCORING (gold-agnostic helpers)
# =====================================================================
def norm(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    value = re.sub(r"[^a-z0-9]", "", value.lower())
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


def evaluate(payload: Dict[str, Any]) -> Dict[str, Any]:
    report: Dict[str, Any] = {"categories": {}, "misses": {}, "spurious": {}}

    # ---- classes ----------------------------------------------------
    # class_map is strict 1:1 (each gold class matched once) for P/R/hierarchy.
    # class_lookup is many:1 — a model may legitimately split one gold concept
    # across several classes (e.g. genus 'Okapia' + species 'Okapia johnstoni'
    # both mean okapi). Downstream categories resolve domains/ranges through
    # class_lookup so property/individual scores aren't hostage to which single
    # class won the strict anchor.
    class_map: Dict[str, str] = {}
    class_lookup: Dict[str, str] = {}
    for cls in payload["classes"]:
        candidates = [cls["name"], strip_prefix(cls["id"])]
        for key, (aliases, _parent) in GOLD_CLASSES.items():
            if matches(candidates, aliases):
                class_lookup[cls["id"]] = key
                if key not in class_map.values():
                    class_map[cls["id"]] = key
                break
    report["categories"]["classes"] = score(len(class_map), len(payload["classes"]), len(GOLD_CLASSES))
    report["misses"]["classes"] = sorted(set(GOLD_CLASSES) - set(class_map.values()))
    report["spurious"]["classes"] = [c["name"] for c in payload["classes"] if c["id"] not in class_lookup]

    def compatible(generated_key: Optional[str], gold_key: str) -> bool:
        if generated_key == gold_key:
            return True
        if generated_key is None:
            return False
        return GOLD_CLASSES[gold_key][1] == generated_key or GOLD_CLASSES[generated_key][1] == gold_key

    # ---- hierarchy --------------------------------------------------
    gold_edges = {(child, parent) for child, (_a, parent) in GOLD_CLASSES.items() if parent}
    found_edges = set()
    for cls in payload["classes"]:
        child = class_map.get(cls["id"])
        parent = class_map.get(cls.get("subClassOf") or "")
        if child and parent and (child, parent) in gold_edges:
            found_edges.add((child, parent))
    report["categories"]["hierarchy"] = score(len(found_edges), len(found_edges), len(gold_edges))
    report["misses"]["hierarchy"] = sorted(f"{c} < {p}" for c, p in gold_edges - found_edges)

    # ---- object properties ------------------------------------------
    op_map: Dict[str, Tuple[str, bool]] = {}
    for require_alias in (True, False):
        for op in payload["object_properties"]:
            if op["id"] in op_map:
                continue
            domain, range_ = class_lookup.get(op["domain"]), class_lookup.get(op["range"])
            for key, (aliases, gd, gr) in GOLD_OBJECT_PROPERTIES.items():
                if key in (k for k, _ in op_map.values()):
                    continue
                if require_alias and not matches([op["name"], strip_prefix(op["id"])], aliases):
                    continue
                if compatible(domain, gd) and compatible(range_, gr):
                    op_map[op["id"]] = (key, False)
                    break
                if compatible(domain, gr) and compatible(range_, gd):
                    op_map[op["id"]] = (key, True)
                    break
    report["categories"]["object_properties"] = score(
        len(op_map), len(payload["object_properties"]), len(GOLD_OBJECT_PROPERTIES)
    )
    report["misses"]["object_properties"] = sorted(set(GOLD_OBJECT_PROPERTIES) - {k for k, _ in op_map.values()})
    report["spurious"]["object_properties"] = [
        f'{op["name"]} ({op["domain"]} -> {op["range"]})'
        for op in payload["object_properties"]
        if op["id"] not in op_map
    ]

    # ---- data properties --------------------------------------------
    dp_map: Dict[str, str] = {}
    neutral = 0
    for dp in payload["data_properties"]:
        candidates = [dp["name"], strip_prefix(dp["id"])]
        if matches(candidates, sorted(NEUTRAL_DATA_PROPERTY_ALIASES)):
            neutral += 1
            continue
        domain = class_lookup.get(dp["domain"])
        for key, (aliases, gold_domains, gold_ranges) in GOLD_DATA_PROPERTIES.items():
            if key in dp_map.values():
                continue
            domain_ok = any(compatible(domain, gd) for gd in gold_domains)
            if domain_ok and dp["range"] in gold_ranges and matches(candidates, aliases):
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

    # ---- individuals -------------------------------------------------
    ind_map: Dict[str, str] = {}
    for ind in payload["individuals"]:
        for key, (aliases, gold_class) in GOLD_INDIVIDUALS.items():
            if key in ind_map.values():
                continue
            if matches([ind["name"], strip_prefix(ind["id"])], aliases) and compatible(
                class_lookup.get(ind["typeClass"]), gold_class
            ):
                ind_map[ind["id"]] = key
                break
    report["categories"]["individuals"] = score(len(ind_map), len(payload["individuals"]), len(GOLD_INDIVIDUALS))
    report["misses"]["individuals"] = sorted(set(GOLD_INDIVIDUALS) - set(ind_map.values()))
    report["spurious"]["individuals"] = [i["name"] for i in payload["individuals"] if i["id"] not in ind_map]

    scores = [c["f1"] for c in report["categories"].values()]
    report["macro_f1"] = round(sum(scores) / len(scores), 3)
    return report


# =====================================================================
# PIPELINE DRIVER (fallback when no captured graph is provided)
# =====================================================================
def generate_ontology(text: str) -> Dict[str, Any]:
    events: List[Dict[str, Any]] = []
    with httpx.Client(timeout=900) as client:
        with client.stream(
            "POST",
            f"{BACKEND_BASE_URL}/api/ontologies/generate",
            json={"text": text, "language": ""},
        ) as response:
            response.raise_for_status()
            for line in response.iter_lines():
                line = line.strip()
                if line.startswith("data:"):
                    events.append(json.loads(line[len("data:") :].strip()))
    done = next((event for event in events if event.get("stage") == "done"), None)
    assert done is not None, f"stream ended without a terminal event: {events}"
    assert done.get("status") == "success", f"generation failed: {done.get('error')}"
    return {
        "payload": done["payload"],
        "retries": sum(1 for event in events if event.get("status") == "retrying"),
    }


def _load_graph() -> Dict[str, Any]:
    if GRAPH_PATH and Path(GRAPH_PATH).exists():
        data = json.loads(Path(GRAPH_PATH).read_text(encoding="utf-8"))
        print(f"scoring browser-captured graph from {GRAPH_PATH}")
        return {"payload": data["payload"], "retries": data.get("retries", 0)}
    try:
        httpx.get(f"{BACKEND_BASE_URL}/health", timeout=5).raise_for_status()
    except httpx.HTTPError:
        pytest.skip(
            "no captured graph (OKAPI_GRAPH_PATH) and backend unreachable — "
            "run the Playwright e2e or `docker compose up`"
        )
    print("no captured graph; generating from the PDF's extracted text via the live backend")
    return generate_ontology(EXTRACTED_TEXT)


# =====================================================================
# ACCEPTANCE TEST
# =====================================================================
def test_okapi_pdf_graph_quality():
    print("\n=========================================")
    print("📊 ACCEPTANCE TEST: OKAPI PDF GRAPH QUALITY")
    print("=========================================")

    result = _load_graph()
    payload, retries = result["payload"], result["retries"]
    print(
        f"graph: {len(payload['classes'])} classes, "
        f"{len(payload['object_properties'])} object properties, "
        f"{len(payload['data_properties'])} data properties, "
        f"{len(payload['individuals'])} individuals ({retries} retries)"
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
        f"macro F1 {report['macro_f1']} below floor {MIN_MACRO_F1}; misses: {report['misses']}"
    )
