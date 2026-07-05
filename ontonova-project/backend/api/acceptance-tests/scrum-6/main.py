"""
Acceptance test: semantic quality on a DENSE Spanish text (nexolabs) vs a
gold standard — the statistical companion to scrum-3.

scrum-3 shows the pipeline reaches the ceiling (macro F1 1.0) on a clean,
well-structured text. This test measures where the CEILING OF THE MODEL is:
the same organizational text that motivated scrum-5's resilience test is
scored against a hand-crafted gold standard. Because generation is not
deterministic across runs (continuous batching + FP reduction order in the
inference engine), quality here is a DISTRIBUTION, not a number: the
campaign script (campaign.py) runs N generations and reports mean/std.

Gold design: only the core facts stated explicitly and unambiguously in the
text are rewarded. Peripheral-but-defensible modeling (Sensortec, the 2018
agreement, project phases as individuals, sensors, funding instruments...)
is NEUTRAL — neither rewarded nor punished — so precision measures real
hallucination, not disagreement with one arbitrary reading of a rich text.

Run (single scored generation, joins the acceptance suite):
    PYTHONPATH=. ./api/bin/python -m pytest api/acceptance-tests/scrum-6/main.py -v -s

Env knobs:
    BACKEND_BASE_URL                    (default http://localhost:8001)
    GRAPH_QUALITY_DENSE_MIN_MACRO_F1    soft floor (default 0.15, smoke gate)
"""

import json
import os
import re
import time
import unicodedata
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import httpx
import pytest

BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "http://localhost:8001")
MIN_MACRO_F1 = float(os.getenv("GRAPH_QUALITY_DENSE_MIN_MACRO_F1", "0.15"))
TEXT_PATH = Path(__file__).resolve().parent.parent / "scrum-5" / "nexolabs.txt"
REPORT_PATH = Path(__file__).parent / "graph-quality-dense-report.json"

# =====================================================================
# GOLD STANDARD (core explicit facts of nexolabs.txt)
# =====================================================================
# Type vocabularies double as (a) gold-class matchers and (b) loose type
# checks for property domains/ranges and individuals.
TYPE: Dict[str, List[str]] = {
    "organization": ["centrodeinvestigacion", "centro", "organizacion", "organization",
                     "empresa", "company", "researchcenter", "centrotecnologico"],
    "department": ["departamento", "department", "dept"],
    "team": ["equipo", "team"],
    "laboratory": ["laboratorio", "laboratory", "lab"],
    "project": ["proyecto", "project"],
    "person": ["persona", "person", "empleado", "employee"],
    "engineer": ["ingeniero", "ingeniera", "engineer"],
    "researcher": ["investigador", "investigadora", "researcher"],
    "director": ["director", "directora", "directorcientifico", "scientificdirector"],
    "university": ["universidad", "university"],
    "phase": ["fase", "phase", "etapa", "stage"],
    "software": ["plataforma", "software", "sistemaoperativo", "operatingsystem", "platform"],
}

# Gold classes: key -> gold parent key (hierarchy stated in the text).
GOLD_CLASSES: Dict[str, Optional[str]] = {
    "organization": None,
    "department": None,
    "team": None,
    "laboratory": None,
    "project": None,
    "person": None,
    "engineer": "person",
    "researcher": "person",
    "director": "person",
    "university": None,
    "phase": None,
    "software": None,
}

# Classes the text supports but whose inclusion is a modeling choice.
NEUTRAL_CLASS_ALIASES = [
    "sensor", "equipamiento", "instrumento", "equipment", "instrument",
    "espectrometro", "camaradevacio", "empresa proveedora", "proveedor", "supplier",
    "fondo", "fund", "inversor", "investor", "convenio", "acuerdo", "agreement",
    "articulo", "publicacion", "publication", "paper", "revista", "journal",
    "subvencion", "grant", "contrato", "contract", "ronda", "inversion",
    "financiacion", "funding", "viadefinanciacion", "planta", "plantapiloto", "plant",
    "cooperativa", "cooperative", "estudiante", "student", "doctorando", "phdstudent",
    "ministerio", "ministry", "cliente", "client", "customer", "robot",
    "brazorobotico", "bateria", "battery", "panel", "panelsolar", "responsable",
    "manager", "teamleader", "lider", "direcciongeneral", "direccion",
    "generalmanagement", "junior", "sede", "ciudad", "city", "normativa",
    "empleado", "employee", "trabajador", "equipodirectivo",
]

# Named-entity classes are a REAL extraction error (specific entities must be
# individuals, per the agents' own guidance) — but their suffixes would
# false-match the generic gold classes ("StorageTeam" ends with "team"). They
# are blocked from gold mapping with an exact match and fall through to
# spurious, where they belong.
NAMED_ENTITY_CLASS_ALIASES = [
    "departamentodeenergia", "departamentoderobotica", "departamentodesoftware",
    "energydepartment", "roboticsdepartment", "softwaredepartment",
    "equipodealmacenamiento", "equipodegeneracion", "storageteam", "generationteam",
    "laboratoriocompartido", "sharedlab", "sharedlaboratory",
    "proyectoaria", "proyectoterra", "ariaproject", "terraproject",
    "nexos", "nexolabs", "martaduarte", "universidaddezaragoza",
    "zaragozauniversity", "atlasventures", "atlasventuresfund", "fondoatlasventures",
    "sensortec", "pabloiriarte", "carlospena", "journalofappliedphysics",
    "ministeriodeciencia", "plantapilotohuesca",
]

# Gold object properties: key -> (aliases, domain type key, range type key)
GOLD_OBJECT_PROPERTIES: Dict[str, Tuple[List[str], str, str]] = {
    "partOfOrg": (["partede", "formaparte", "pertenece", "partof", "belongsto",
                   "tienedepartamento", "hasdepartment", "estructurada", "compuesta",
                   "consistsof", "comprende", "sedivideen"], "department", "organization"),
    "partOfDept": (["partede", "pertenece", "partof", "belongsto", "subdividese",
                    "tieneequipo", "hasteam", "subteam", "sedivideen"], "team", "department"),
    "develops": (["desarrolla", "develops", "trabajaen", "workson"], "department", "project"),
    "maintains": (["mantiene", "maintains", "desarrolla", "develops", "crea"],
                  "department", "software"),
    "uses": (["utiliza", "usa", "uses", "depende", "dependson", "daservicio", "serves",
              "poweredby", "ejecuta", "runs", "sirve"], "project", "software"),
    "directs": (["dirige", "directs", "leads", "lidera", "dirigidopor", "directedby"],
                "director", "department"),
    "supervises": (["supervisa", "supervises", "reporta", "reportsto", "reportaa"],
                   "person", "person"),
    "collaborates": (["colabora", "collaborates", "convenio", "partner", "coopera"],
                     "organization", "university"),
    "usesLab": (["comparte", "shares", "usalaboratorio", "haslaboratory", "utiliza",
                 "dispone", "equippedwith", "tienelaboratorio"], "team", "laboratory"),
    "inPhase": (["fase", "phase", "seencuentra", "estado", "state", "pasapor",
                 "currentphase"], "project", "phase"),
}

# Facts about neutral entities are neutral too (correct extraction of a
# peripheral fact must not read as hallucination).
NEUTRAL_OP_ALIASES = [
    "fabricado", "manufactured", "fabrica", "publicado", "published", "publica",
    "financiado", "funded", "financia", "liderada", "led", "cita", "cites",
    "vende", "sells", "vendido", "destinado", "permite", "realiza", "adquirido",
    "acquired", "firmado", "signed", "sucede", "succeeded", "sustituye",
    "proporciona", "provides", "jubilado", "retired", "amplia", "construye",
    "supera", "exige", "obtiene", "usasensor", "tienesensor", "hassensor",
]

_NUMERIC = {"xsd:integer", "xsd:float"}
# Gold data properties: key -> (aliases, domain type key, acceptable xsd ranges)
GOLD_DATA_PROPERTIES: Dict[str, Tuple[List[str], str, set]] = {
    "foundedYear": (["fundado", "fundadoen", "founded", "fundacion", "yearfounded",
                     "foundedyear", "anodefundacion", "creadoen"],
                    "organization", _NUMERIC | {"xsd:dateTime", "xsd:string"}),
    "location": (["ubicacion", "ciudad", "sede", "location", "city", "situado",
                  "localidad", "ubicada"], "organization", {"xsd:string"}),
    "employees": (["empleados", "numerodeempleados", "employees", "plantilla",
                   "staff", "numempleados"], "organization", _NUMERIC),
}

NEUTRAL_DATA_PROPERTY_ALIASES = [
    "name", "hasname", "nombre", "title", "fullname", "descripcion", "description",
    "ano", "year", "fecha", "date", "valor", "amount", "importe", "cantidad",
    "numero", "tipo", "type", "especializacion", "specialization", "estado",
    "status", "fase", "phase",
]

# Gold individuals: key -> (aliases, accepted type aliases)
GOLD_INDIVIDUALS: Dict[str, Tuple[List[str], List[str]]] = {
    "nexolabs": (["nexolabs", "nexolab"], TYPE["organization"]),
    "deptEnergia": (["departamentodeenergia", "deptenergia", "energia",
                     "energydepartment"], TYPE["department"]),
    "deptRobotica": (["departamentoderobotica", "deptrobotica", "robotica",
                      "roboticsdepartment"], TYPE["department"]),
    "deptSoftware": (["departamentodesoftware", "deptsoftware", "software",
                      "softwaredepartment"], TYPE["department"]),
    "equipoAlmacenamiento": (["equipodealmacenamiento", "almacenamiento",
                              "storageteam"], TYPE["team"]),
    "equipoGeneracion": (["equipodegeneracion", "generacion", "generationteam"],
                         TYPE["team"]),
    "aria": (["aria", "proyectoaria"], TYPE["project"] + ["robot", "brazorobotico",
             "brazoroboticocolaborativo", "roboticarm"]),
    "terra": (["terra", "proyectoterra"], TYPE["project"] + ["robot", "robotautonomo",
              "autonomousrobot"]),
    "nexos": (["nexos", "plataformanexos"], TYPE["software"]),
    "martaDuarte": (["martaduarte", "marta", "duarte"],
                    TYPE["engineer"] + TYPE["director"] + TYPE["person"]),
    "universidadZaragoza": (["universidaddezaragoza", "universidadzaragoza",
                             "zaragozauniversity", "unizar"], TYPE["university"]),
    "labCompartido": (["laboratoriocompartido", "laboratorio", "sharedlab",
                       "sharedlaboratory", "lab"], TYPE["laboratory"]),
}

NEUTRAL_INDIVIDUAL_ALIASES = [
    "sensortec", "atlasventures", "atlas", "carlospena", "carlos", "pena",
    "pabloiriarte", "pablo", "iriarte", "ministerio", "ministeriodeciencia",
    "journalofappliedphysics", "journal", "revista", "plantahuesca", "huesca",
    "plantapiloto", "direcciongeneral", "espectrometro", "espectrometrodemasas",
    "camaradevacio", "investigacion", "prototipado", "validacion", "produccion",
    "convenio", "articulo", "ronda", "rondadeinversion", "zaragoza", "aragon",
    "navarra", "cooperativa", "espana", "lidar", "sensor",
]

# Gold relation assertions: (object property, subject, object)
GOLD_OP_ASSERTIONS = [
    ("partOfOrg", "deptEnergia", "nexolabs"),
    ("partOfOrg", "deptRobotica", "nexolabs"),
    ("partOfOrg", "deptSoftware", "nexolabs"),
    ("partOfDept", "equipoAlmacenamiento", "deptEnergia"),
    ("partOfDept", "equipoGeneracion", "deptEnergia"),
    ("develops", "deptRobotica", "aria"),
    ("develops", "deptRobotica", "terra"),
    ("maintains", "deptSoftware", "nexos"),
    ("uses", "aria", "nexos"),
    ("uses", "terra", "nexos"),
    ("directs", "martaDuarte", "deptRobotica"),
    ("collaborates", "nexolabs", "universidadZaragoza"),
    ("usesLab", "equipoAlmacenamiento", "labCompartido"),
    ("usesLab", "equipoGeneracion", "labCompartido"),
]

# Gold literal assertions: (data property, individual, value that must appear)
GOLD_DP_ASSERTIONS = [
    ("foundedYear", "nexolabs", 2015),
    ("location", "nexolabs", "aragoza"),  # matches Zaragoza case-insensitively
    ("employees", "nexolabs", 62),
]


# =====================================================================
# NORMALIZATION + MATCHING (shared approach with scrum-3)
# =====================================================================
def norm(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    value = re.sub(r"[^a-z0-9]", "", value.lower())
    return value[:-1] if value.endswith("s") and len(value) > 3 else value


def strip_prefix(identifier: str) -> str:
    return re.sub(r"^(class|prop|attr|inst)_?", "", identifier or "", flags=re.IGNORECASE)


def matches_exact(candidates: List[str], aliases: List[str]) -> bool:
    normalized_aliases = {norm(a) for a in aliases}
    return any(norm(c) in normalized_aliases for c in candidates if norm(c))


def matches(candidates: List[str], aliases: List[str]) -> bool:
    for candidate in candidates:
        n = norm(candidate)
        if not n:
            continue
        for alias in aliases:
            a = norm(alias)
            if not a:
                continue
            if n == a or n.endswith(a) or a.endswith(n):
                return True
    return False


def f1(precision: float, recall: float) -> float:
    return 0.0 if precision + recall == 0 else 2 * precision * recall / (precision + recall)


def score(matched: int, generated: int, gold: int) -> Dict[str, float]:
    precision = matched / generated if generated else 0.0
    recall = matched / gold if gold else 1.0
    return {
        "matched": matched, "generated": generated, "gold": gold,
        "precision": round(precision, 3), "recall": round(recall, 3),
        "f1": round(f1(precision, recall), 3),
    }


# =====================================================================
# PIPELINE DRIVER
# =====================================================================
def generate_ontology(text: str) -> Dict[str, Any]:
    events: List[Dict[str, Any]] = []
    started = time.monotonic()
    with httpx.Client(timeout=1800) as client:
        with client.stream(
            "POST",
            f"{BACKEND_BASE_URL}/api/ontologies/generate",
            json={"text": text, "language": ""},  # UI default: auto-detect
        ) as response:
            response.raise_for_status()
            for line in response.iter_lines():
                line = line.strip()
                if line.startswith("data:"):
                    events.append(json.loads(line[len("data:") :].strip()))
    duration = time.monotonic() - started

    done = next((event for event in events if event.get("stage") == "done"), None)
    assert done is not None, f"stream ended without a terminal event: {events}"
    assert done.get("status") == "success", f"generation failed: {done.get('error')}"
    retries = sum(1 for event in events if event.get("status") == "retrying")
    return {"payload": done["payload"], "retries": retries, "duration_s": round(duration, 1)}


# =====================================================================
# SCORING
# =====================================================================
def evaluate(payload: Dict[str, Any]) -> Dict[str, Any]:
    report: Dict[str, Any] = {"categories": {}, "misses": {}, "spurious": {}}
    # generated class id -> [name, stripped id] for loose type checks
    class_text = {c["id"]: [c.get("name", ""), strip_prefix(c["id"])] for c in payload["classes"]}

    # ---- classes ----------------------------------------------------
    class_map: Dict[str, str] = {}
    neutral_classes = 0
    for cls in payload["classes"]:
        texts = class_text[cls["id"]]
        if matches_exact(texts, NAMED_ENTITY_CLASS_ALIASES):
            continue  # counted as spurious below — a named entity is not a kind
        for key in GOLD_CLASSES:
            if key not in class_map.values() and matches(texts, TYPE[key]):
                class_map[cls["id"]] = key
                break
        else:
            if matches(texts, NEUTRAL_CLASS_ALIASES):
                neutral_classes += 1
    report["categories"]["classes"] = score(
        len(class_map), len(payload["classes"]) - neutral_classes, len(GOLD_CLASSES)
    )
    report["misses"]["classes"] = sorted(set(GOLD_CLASSES) - set(class_map.values()))
    report["spurious"]["classes"] = [
        c["name"] for c in payload["classes"]
        if c["id"] not in class_map and not matches(class_text[c["id"]], NEUTRAL_CLASS_ALIASES)
    ]

    # ---- hierarchy ---------------------------------------------------
    gold_edges = {(child, parent) for child, parent in GOLD_CLASSES.items() if parent}
    found_edges = set()
    for cls in payload["classes"]:
        child = class_map.get(cls["id"])
        parent = class_map.get(cls.get("subClassOf") or "")
        if child and parent and (child, parent) in gold_edges:
            found_edges.add((child, parent))
    report["categories"]["hierarchy"] = score(len(found_edges), len(found_edges), len(gold_edges))
    report["misses"]["hierarchy"] = sorted(
        f"{c} subClassOf {p}" for c, p in gold_edges - found_edges
    )

    # ---- object properties -------------------------------------------
    def class_is(cid: Optional[str], type_key: str) -> bool:
        if not cid or cid not in class_text:
            return False
        aliases = list(TYPE[type_key])
        # a property declared one level up the gold hierarchy is looser
        # modeling, not a wrong fact
        parent = GOLD_CLASSES.get(type_key)
        if parent:
            aliases += TYPE[parent]
        for child, par in GOLD_CLASSES.items():
            if par == type_key:
                aliases += TYPE[child]
        return matches(class_text[cid], aliases)

    op_map: Dict[str, Tuple[str, bool]] = {}
    for require_alias in (True, False):
        for op in payload["object_properties"]:
            if op["id"] in op_map:
                continue
            op_texts = [op.get("name", ""), strip_prefix(op["id"])]
            for key, (aliases, gold_domain, gold_range) in GOLD_OBJECT_PROPERTIES.items():
                if key in (k for k, _inv in op_map.values()):
                    continue
                if require_alias and not matches(op_texts, aliases):
                    continue
                if class_is(op.get("domain"), gold_domain) and class_is(op.get("range"), gold_range):
                    op_map[op["id"]] = (key, False)
                    break
                if class_is(op.get("domain"), gold_range) and class_is(op.get("range"), gold_domain):
                    op_map[op["id"]] = (key, True)
                    break
    neutral_ops = sum(
        1 for op in payload["object_properties"]
        if op["id"] not in op_map
        and matches([op.get("name", ""), strip_prefix(op["id"])], NEUTRAL_OP_ALIASES)
    )
    report["categories"]["object_properties"] = score(
        len(op_map), len(payload["object_properties"]) - neutral_ops, len(GOLD_OBJECT_PROPERTIES)
    )
    report["misses"]["object_properties"] = sorted(
        set(GOLD_OBJECT_PROPERTIES) - {k for k, _inv in op_map.values()}
    )
    report["spurious"]["object_properties"] = [
        f'{op["name"]} ({op["domain"]} -> {op["range"]})'
        for op in payload["object_properties"]
        if op["id"] not in op_map
        and not matches([op.get("name", ""), strip_prefix(op["id"])], NEUTRAL_OP_ALIASES)
    ]

    # ---- data properties ----------------------------------------------
    dp_map: Dict[str, str] = {}
    neutral_dps = 0
    for dp in payload["data_properties"]:
        candidates = [dp.get("name", ""), strip_prefix(dp["id"])]
        matched_key = None
        for key, (aliases, gold_domain, gold_ranges) in GOLD_DATA_PROPERTIES.items():
            if key in dp_map.values():
                continue
            if (matches(candidates, aliases) and class_is(dp.get("domain"), gold_domain)
                    and dp.get("range") in gold_ranges):
                matched_key = key
                break
        if matched_key:
            dp_map[dp["id"]] = matched_key
        elif matches(candidates, NEUTRAL_DATA_PROPERTY_ALIASES):
            neutral_dps += 1
    report["categories"]["data_properties"] = score(
        len(dp_map), len(payload["data_properties"]) - neutral_dps, len(GOLD_DATA_PROPERTIES)
    )
    report["misses"]["data_properties"] = sorted(set(GOLD_DATA_PROPERTIES) - set(dp_map.values()))
    report["spurious"]["data_properties"] = [
        f'{dp["name"]} ({dp["domain"]}: {dp["range"]})'
        for dp in payload["data_properties"]
        if dp["id"] not in dp_map
        and not matches([dp.get("name", ""), strip_prefix(dp["id"])], NEUTRAL_DATA_PROPERTY_ALIASES)
    ]

    # ---- individuals ----------------------------------------------------
    ind_map: Dict[str, str] = {}
    neutral_inds = 0
    for ind in payload["individuals"]:
        texts = [ind.get("name", ""), strip_prefix(ind["id"])]
        matched_key = None
        for key, (aliases, type_aliases) in GOLD_INDIVIDUALS.items():
            if key in ind_map.values():
                continue
            type_texts = class_text.get(ind.get("typeClass"), [])
            if matches(texts, aliases) and matches(type_texts, type_aliases):
                matched_key = key
                break
        if matched_key:
            ind_map[ind["id"]] = matched_key
        elif matches(texts, NEUTRAL_INDIVIDUAL_ALIASES):
            neutral_inds += 1
    report["categories"]["individuals"] = score(
        len(ind_map), len(payload["individuals"]) - neutral_inds, len(GOLD_INDIVIDUALS)
    )
    report["misses"]["individuals"] = sorted(set(GOLD_INDIVIDUALS) - set(ind_map.values()))
    report["spurious"]["individuals"] = [
        ind["name"] for ind in payload["individuals"]
        if ind["id"] not in ind_map
        and not matches([ind.get("name", ""), strip_prefix(ind["id"])], NEUTRAL_INDIVIDUAL_ALIASES)
    ]

    # ---- assertions ------------------------------------------------------
    inverse_ind = {v: k for k, v in ind_map.items()}
    found_ops, op_misses = 0, []
    for gold_op, gold_subject, gold_object in GOLD_OP_ASSERTIONS:
        hit = False
        for ind in payload["individuals"]:
            for prop_id, targets in (ind.get("objectPropertyAssertions") or {}).items():
                key, inverted = op_map.get(prop_id, (None, False))
                if key != gold_op:
                    continue
                subject, object_ = (
                    (gold_object, gold_subject) if inverted else (gold_subject, gold_object)
                )
                if ind_map.get(ind["id"]) == subject and inverse_ind.get(object_) in targets:
                    hit = True
        found_ops += hit
        if not hit:
            op_misses.append(f"{gold_subject} --{gold_op}--> {gold_object}")
    report["categories"]["op_assertions"] = score(found_ops, found_ops, len(GOLD_OP_ASSERTIONS))
    report["misses"]["op_assertions"] = op_misses

    found_dps, dp_misses = 0, []
    for gold_dp, gold_ind, expected in GOLD_DP_ASSERTIONS:
        hit = False
        for ind in payload["individuals"]:
            if ind_map.get(ind["id"]) != gold_ind:
                continue
            for prop_id, value in (ind.get("dataPropertyAssertions") or {}).items():
                if dp_map.get(prop_id) == gold_dp and str(expected).lower() in str(value).lower():
                    hit = True
        found_dps += hit
        if not hit:
            dp_misses.append(f"{gold_ind}.{gold_dp} ~ {expected}")
    report["categories"]["dp_assertions"] = score(found_dps, found_dps, len(GOLD_DP_ASSERTIONS))
    report["misses"]["dp_assertions"] = dp_misses

    scores = [category["f1"] for category in report["categories"].values()]
    report["macro_f1"] = round(sum(scores) / len(scores), 3)
    report["macro_precision"] = round(
        sum(c["precision"] for c in report["categories"].values()) / len(report["categories"]), 3
    )
    report["macro_recall"] = round(
        sum(c["recall"] for c in report["categories"].values()) / len(report["categories"]), 3
    )
    return report


# =====================================================================
# ACCEPTANCE TEST (single scored generation)
# =====================================================================
def test_graph_quality_on_dense_text():
    try:
        httpx.get(f"{BACKEND_BASE_URL}/health", timeout=5).raise_for_status()
    except httpx.HTTPError:
        pytest.skip(f"backend not reachable at {BACKEND_BASE_URL}")

    print("\n===============================================")
    print("📊 ACCEPTANCE TEST: GRAPH QUALITY (DENSE TEXT)")
    print("===============================================")

    result = generate_ontology(TEXT_PATH.read_text(encoding="utf-8"))
    payload = result["payload"]
    print(
        f"generated: {len(payload['classes'])} classes, "
        f"{len(payload['object_properties'])} object properties, "
        f"{len(payload['data_properties'])} data properties, "
        f"{len(payload['individuals'])} individuals "
        f"({result['retries']} retries, {result['duration_s']}s)"
    )

    report = evaluate(payload)
    report["retries"] = result["retries"]
    report["duration_s"] = result["duration_s"]

    print(f"\n{'category':<20}{'P':>7}{'R':>7}{'F1':>7}")
    for name, category in report["categories"].items():
        print(f"{name:<20}{category['precision']:>7.2f}{category['recall']:>7.2f}{category['f1']:>7.2f}")
    print(f"{'macro F1':<20}{report['macro_f1']:>21.2f}")
    for section in ("misses", "spurious"):
        for name, items in report[section].items():
            if items:
                print(f"{section}.{name}: {items}")

    report["payload"] = payload
    REPORT_PATH.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nfull report: {REPORT_PATH}")

    assert report["macro_f1"] >= MIN_MACRO_F1, (
        f"macro F1 {report['macro_f1']} below smoke floor {MIN_MACRO_F1}"
    )
