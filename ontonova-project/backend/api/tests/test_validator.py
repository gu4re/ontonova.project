from api.core.validator import validate_ontonova_json

VALID_PAYLOAD = {
    "classes": [
        {"id": "Class_Persona", "name": "Persona", "subClassOf": None},
        {"id": "Class_Profesor", "name": "Profesor", "subClassOf": "Class_Persona"},
    ],
    "object_properties": [
        {
            "id": "prop_ensenaA",
            "name": "ensena a",
            "domain": "Class_Profesor",
            "range": "Class_Persona",
            "characteristics": ["Functional"],
        }
    ],
    "data_properties": [
        {"id": "attr_tieneEdad", "name": "tiene edad", "domain": "Class_Persona", "range": "xsd:integer"}
    ],
    "individuals": [
        {
            "id": "inst_profesorJuan",
            "name": "Juan Perez",
            "typeClass": "Class_Profesor",
            "objectPropertyAssertions": {},
            "dataPropertyAssertions": {"attr_tieneEdad": 45},
        }
    ],
}


def _with(payload, **overrides):
    merged = {**payload, **overrides}
    return merged


def test_valid_payload_passes():
    valid, error = validate_ontonova_json(VALID_PAYLOAD)
    assert valid is True
    assert error is None


def test_rejects_id_reused_across_categories():
    # "Class_Profesor" is both a class id and (here) an individual id — since
    # rdf_compiler maps every category into the same flat RDF namespace, this
    # would silently collide onto a single URI.
    payload = _with(
        VALID_PAYLOAD,
        individuals=[
            {
                "id": "Class_Profesor",
                "name": "Juan Perez",
                "typeClass": "Class_Profesor",
                "objectPropertyAssertions": {},
                "dataPropertyAssertions": {},
            }
        ],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False
    assert "globally unique" in error
    assert "Class_Profesor" in error
    # The class was declared first and is legitimate — the individual
    # reusing its id is the one that needs to change, so the error must be
    # blamed on "individuals" (populator), not "classes" (taxonomist).
    # core.graph's self-healing router trusts only this leading prefix.
    assert error.startswith("individuals:")


def test_id_collision_within_the_same_category_blames_that_category():
    payload = _with(
        VALID_PAYLOAD,
        individuals=[
            {
                "id": "inst_dup",
                "name": "A",
                "typeClass": "Class_Persona",
                "objectPropertyAssertions": {},
                "dataPropertyAssertions": {},
            },
            {
                "id": "inst_dup",
                "name": "B",
                "typeClass": "Class_Persona",
                "objectPropertyAssertions": {},
                "dataPropertyAssertions": {},
            },
        ],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False
    assert error.startswith("individuals:")
    assert "inst_dup" in error


def test_rejects_id_with_invalid_characters():
    payload = _with(
        VALID_PAYLOAD,
        classes=[{"id": "Class Persona!", "name": "Persona", "subClassOf": None}],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False
    assert "pattern" in error


def test_rejects_unknown_data_property_range():
    payload = _with(
        VALID_PAYLOAD,
        data_properties=[
            {"id": "attr_tieneEdad", "name": "tiene edad", "domain": "Class_Persona", "range": "xsd:int"}
        ],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False


def test_rejects_unknown_object_property_characteristic():
    payload = _with(
        VALID_PAYLOAD,
        object_properties=[
            {
                "id": "prop_ensenaA",
                "name": "ensena a",
                "domain": "Class_Profesor",
                "range": "Class_Persona",
                "characteristics": ["Idempotent"],
            }
        ],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False


def test_rejects_dangling_subclass_reference():
    payload = _with(
        VALID_PAYLOAD,
        classes=[{"id": "Class_Profesor", "name": "Profesor", "subClassOf": "Class_DoesNotExist"}],
        object_properties=[],
        data_properties=[],
        individuals=[],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False
    assert "subClassOf" in error


def test_rejects_object_property_with_unknown_domain_and_range():
    payload = _with(
        VALID_PAYLOAD,
        object_properties=[
            {
                "id": "prop_ensenaA",
                "name": "ensena a",
                "domain": "Class_Ghost",
                "range": "Class_AlsoGhost",
                "characteristics": [],
            }
        ],
        individuals=[],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False
    assert "Class_Ghost" in error
    assert "Class_AlsoGhost" in error


def test_rejects_individual_with_unknown_type_class_and_assertions():
    payload = _with(
        VALID_PAYLOAD,
        individuals=[
            {
                "id": "inst_profesorJuan",
                "name": "Juan Perez",
                "typeClass": "Class_Ghost",
                "objectPropertyAssertions": {"prop_ghost": ["inst_ghost"]},
                "dataPropertyAssertions": {"attr_ghost": 1},
            }
        ],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False
    assert "Class_Ghost" in error
    assert "prop_ghost" in error
    assert "inst_ghost" in error
    assert "attr_ghost" in error


# =====================================================================
# ASSERTION DOMAIN/RANGE CONFORMANCE
# =====================================================================
_CONFORMANCE_INDIVIDUALS = [
    {
        "id": "inst_profesorJuan",
        "name": "Juan Perez",
        "typeClass": "Class_Profesor",
        "objectPropertyAssertions": {},
        "dataPropertyAssertions": {},
    },
    {
        "id": "inst_ana",
        "name": "Ana",
        "typeClass": "Class_Persona",
        "objectPropertyAssertions": {},
        "dataPropertyAssertions": {},
    },
]


def test_accepts_assertion_whose_subject_is_a_subclass_of_the_domain():
    # prop_ensenaA has domain Class_Profesor and range Class_Persona;
    # attr_tieneEdad has domain Class_Persona and the subject is a Profesor
    # (subclass of Persona) — both directions conform.
    individuals = [dict(_CONFORMANCE_INDIVIDUALS[0]), dict(_CONFORMANCE_INDIVIDUALS[1])]
    individuals[0]["objectPropertyAssertions"] = {"prop_ensenaA": ["inst_ana"]}
    individuals[0]["dataPropertyAssertions"] = {"attr_tieneEdad": 45}
    valid, error = validate_ontonova_json(_with(VALID_PAYLOAD, individuals=individuals))
    assert valid is True, error


def test_rejects_inverted_object_property_assertion():
    # The relation is asserted on the Persona pointing at the Profesor —
    # backwards for a Profesor -> Persona property. This is the failure mode
    # observed live in the scrum-3 graph-quality run.
    individuals = [dict(_CONFORMANCE_INDIVIDUALS[0]), dict(_CONFORMANCE_INDIVIDUALS[1])]
    individuals[1]["objectPropertyAssertions"] = {"prop_ensenaA": ["inst_profesorJuan"]}
    valid, error = validate_ontonova_json(_with(VALID_PAYLOAD, individuals=individuals))
    assert valid is False
    assert "inverted" in error
    assert error.startswith("individuals:")  # routes self-healing to populator


def test_rejects_assertion_target_outside_the_property_range():
    payload = _with(
        VALID_PAYLOAD,
        classes=VALID_PAYLOAD["classes"] + [{"id": "Class_Curso", "name": "Curso", "subClassOf": None}],
        individuals=[
            dict(_CONFORMANCE_INDIVIDUALS[0]),
            {
                "id": "inst_algebra",
                "name": "Algebra",
                "typeClass": "Class_Curso",
                "objectPropertyAssertions": {},
                "dataPropertyAssertions": {},
            },
        ],
    )
    # Target is a Curso, but the property's range is Class_Persona.
    payload["individuals"][0]["objectPropertyAssertions"] = {"prop_ensenaA": ["inst_algebra"]}
    valid, error = validate_ontonova_json(payload)
    assert valid is False
    assert "range is 'Class_Persona'" in error


def test_rejects_data_property_assertion_on_wrong_class():
    payload = _with(
        VALID_PAYLOAD,
        classes=VALID_PAYLOAD["classes"] + [{"id": "Class_Curso", "name": "Curso", "subClassOf": None}],
        data_properties=[
            {"id": "attr_creditos", "name": "creditos", "domain": "Class_Curso", "range": "xsd:integer"}
        ],
        individuals=[
            {
                "id": "inst_profesorJuan",
                "name": "Juan Perez",
                "typeClass": "Class_Profesor",
                "objectPropertyAssertions": {},
                # A course-only attribute asserted on a person.
                "dataPropertyAssertions": {"attr_creditos": 6},
            }
        ],
    )
    valid, error = validate_ontonova_json(payload)
    assert valid is False
    assert "attr_creditos" in error
