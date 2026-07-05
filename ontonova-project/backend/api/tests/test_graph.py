from unittest.mock import AsyncMock, patch

import pytest

from api.core.graph import stream_ontology_generation
from api.services.vllm_client import LLMGenerationError

TAXONOMIST_OUT = {"classes": [{"id": "Class_A", "name": "A"}]}
RELATIONAL_OUT = {"object_properties": [], "data_properties": []}
POPULATOR_OUT = {"individuals": []}

# Missing required "range" -> fails OntoNovaSchema validation.
RELATIONAL_BAD = {
    "object_properties": [{"id": "prop_x", "name": "x", "domain": "Class_A"}],
    "data_properties": [],
}
RELATIONAL_FIXED = {
    "object_properties": [{"id": "prop_x", "name": "x", "domain": "Class_A", "range": "Class_A"}],
    "data_properties": [],
}


async def _collect_events(text: str = "Domain description", language: str = "en"):
    return [event async for event in stream_ontology_generation(text, language)]


async def test_pipeline_success_path_yields_every_stage_and_final_payload():
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [TAXONOMIST_OUT, RELATIONAL_OUT, POPULATOR_OUT]
        events = await _collect_events()

    assert [e["stage"] for e in events] == ["taxonomist", "relational", "populator", "validator", "done"]
    assert events[-1]["status"] == "success"
    # The success payload is re-serialized through the validated Pydantic
    # model, so optional-with-default fields (metadata, subClassOf) are
    # normalized in even though the raw LLM output omitted them.
    classes = events[-1]["payload"]["classes"]
    assert len(classes) == 1
    assert classes[0]["id"] == "Class_A"
    assert classes[0]["name"] == "A"
    assert classes[0]["subClassOf"] is None


async def test_pipeline_self_heals_after_a_validation_error():
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [
            TAXONOMIST_OUT,
            RELATIONAL_BAD,
            POPULATOR_OUT,
            RELATIONAL_FIXED,
            POPULATOR_OUT,
        ]
        events = await _collect_events()

    stages = [e["stage"] for e in events]
    assert stages.count("relational") == 2
    assert any(e["status"] == "retrying" for e in events)
    assert events[-1]["status"] == "success"


async def test_pipeline_gives_up_after_max_retries_and_reports_failure():
    # A class without its required name is malformed at the schema level and
    # has no pruning escape hatch — the one kind of defect that must still
    # end in an honest hard failure after the retry budget.
    async def broken_taxonomist(messages, json_schema, base_url):
        if "Taxonomist agent" in messages[0]["content"]:
            return {"classes": [{"id": "Class_A"}]}  # missing required name
        if "Relational agent" in messages[0]["content"]:
            return {"object_properties": [], "data_properties": []}
        return {"individuals": []}

    with patch("api.core.graph.generate_structured", new=AsyncMock(side_effect=broken_taxonomist)):
        events = await _collect_events()

    assert events[-1]["stage"] == "done"
    assert events[-1]["status"] == "failed"
    assert "name" in events[-1]["error"]


async def test_pipeline_degrades_by_pruning_an_unfixable_property():
    # Relational insists on a property without range on every retry — after
    # the budget, the property is amputated and the rest of the graph
    # survives (previously this was a hard failure).
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [TAXONOMIST_OUT] + [RELATIONAL_BAD, POPULATOR_OUT] * 5
        events = await _collect_events()

    assert events[-1]["status"] == "success"
    assert events[-1]["payload"]["object_properties"] == []
    assert [c["id"] for c in events[-1]["payload"]["classes"]] == ["Class_A"]


async def test_pipeline_corrects_multiple_stages_in_a_single_retry_pass():
    """
    Regression test: relational and populator each independently produce a
    dangling-reference error in the same pass. Since retrying from
    "relational" cascades through populator too, populator must also receive
    the correction note (not just the one stage whose error happened to be
    listed first) — otherwise it keeps repeating its mistake and the bounded
    retry budget gets exhausted on stages that were each one-shot-correctable.
    """

    async def smart_llm(messages, json_schema, base_url):
        system_content = messages[0]["content"]
        has_correction = "previous attempt failed" in messages[1]["content"]

        if "Relational agent" in system_content:
            range_ = "Class_A" if has_correction else "Class_Ghost"
            return {
                "object_properties": [
                    {"id": "prop_x", "name": "x", "domain": "Class_A", "range": range_}
                ],
                "data_properties": [],
            }
        if "Populator agent" in system_content:
            type_class = "Class_A" if has_correction else "Class_Ghost2"
            return {
                "individuals": [
                    {
                        "id": "inst_a",
                        "name": "A1",
                        "typeClass": type_class,
                        "objectPropertyAssertions": {},
                        "dataPropertyAssertions": {},
                    }
                ]
            }
        return TAXONOMIST_OUT

    with patch("api.core.graph.generate_structured", new=AsyncMock(side_effect=smart_llm)):
        events = await _collect_events()

    assert events[-1]["status"] == "success"
    retrying_events = [e for e in events if e.get("status") == "retrying"]
    assert len(retrying_events) == 1


async def test_pipeline_repairs_id_collision_without_any_retry():
    """
    When populator creates an individual that reuses an already-declared
    class id, the validator renames the individual losslessly — no LLM
    retry is spent at all. (Historically this error was routed to populator
    for a retry; the deterministic rename supersedes that path, so every
    stage must run exactly once here.)
    """

    async def smart_llm(messages, json_schema, base_url):
        system_content = messages[0]["content"]
        if "Taxonomist agent" in system_content:
            return {"classes": [{"id": "Cafe", "name": "Cafe"}]}
        if "Relational agent" in system_content:
            return {"object_properties": [], "data_properties": []}
        assert "Populator agent" in system_content
        return {
            "individuals": [
                {
                    "id": "Cafe",
                    "name": "Cafe",
                    "typeClass": "Cafe",
                    "objectPropertyAssertions": {},
                    "dataPropertyAssertions": {},
                }
            ]
        }

    with patch("api.core.graph.generate_structured", new=AsyncMock(side_effect=smart_llm)):
        events = await _collect_events()

    assert events[-1]["status"] == "success"
    stages = [e["stage"] for e in events]
    assert stages.count("taxonomist") == 1
    assert stages.count("relational") == 1
    assert stages.count("populator") == 1
    individual = events[-1]["payload"]["individuals"][0]
    assert individual["id"] != "Cafe"
    assert individual["typeClass"] == "Cafe"


async def test_pipeline_routes_undeclared_property_assertion_to_relational():
    """
    Regression test ("university roles" investigation): populator can only
    assert object/data properties relational already declared. When it
    references a property id that was never declared at all (relational
    missed a relationship the text implies, e.g. a peer relation between two
    students), retrying populator alone can never produce a valid id — it
    just oscillates between different hallucinated names every retry. The
    error must route back to relational so it gets a chance to declare the
    missing property before populator tries again.
    """

    async def smart_llm(messages, json_schema, base_url):
        system_content = messages[0]["content"]
        has_correction = "previous attempt failed" in messages[1]["content"]

        if "Taxonomist agent" in system_content:
            return TAXONOMIST_OUT
        if "Relational agent" in system_content:
            object_properties = (
                [{"id": "mentors", "name": "Mentors", "domain": "Class_A", "range": "Class_A"}]
                if has_correction
                else []
            )
            return {"object_properties": object_properties, "data_properties": []}
        assert "Populator agent" in system_content
        return {
            "individuals": [
                {
                    "id": "inst_a",
                    "name": "A1",
                    "typeClass": "Class_A",
                    "objectPropertyAssertions": {"mentors": ["inst_b"]},
                    "dataPropertyAssertions": {},
                },
                {
                    "id": "inst_b",
                    "name": "B1",
                    "typeClass": "Class_A",
                    "objectPropertyAssertions": {},
                    "dataPropertyAssertions": {},
                },
            ]
        }

    with patch("api.core.graph.generate_structured", new=AsyncMock(side_effect=smart_llm)):
        events = await _collect_events()

    assert events[-1]["status"] == "success"
    stages = [e["stage"] for e in events]
    assert stages.count("taxonomist") == 1
    assert stages.count("relational") == 2
    assert stages.count("populator") == 2


async def test_success_payload_normalizes_omitted_optional_individual_fields():
    """
    Regression test: objectPropertyAssertions/dataPropertyAssertions have
    Pydantic defaults, so the LLM can legally omit them from its raw JSON
    and still pass validation — but the frontend's TS types declare both as
    always-present. The final payload must fill them in, not forward the
    LLM's raw (possibly incomplete) dict as-is.
    """
    populator_out_missing_assertions = {
        "individuals": [{"id": "inst_a", "name": "A1", "typeClass": "Class_A"}]
    }
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [TAXONOMIST_OUT, RELATIONAL_OUT, populator_out_missing_assertions]
        events = await _collect_events()

    assert events[-1]["status"] == "success"
    individual = events[-1]["payload"]["individuals"][0]
    assert individual["objectPropertyAssertions"] == {}
    assert individual["dataPropertyAssertions"] == {}


async def test_pipeline_reports_llm_connectivity_failure():
    with patch(
        "api.core.graph.generate_structured", new=AsyncMock(side_effect=LLMGenerationError("endpoint down"))
    ):
        events = await _collect_events()

    assert events[-1]["status"] == "failed"
    assert "endpoint down" in events[-1]["error"]


# =====================================================================
# DETERMINISTIC REFERENCE REPAIR (graceful degradation, REQ-US-FC-03)
# =====================================================================
POPULATOR_MISSPELLED_TARGET = {
    # Declares "alanTuring" but asserts a relation to "professorAlanTuring" —
    # the exact failure mode observed in the scrum-3 graph-quality run.
    "individuals": [
        {"id": "alanTuring", "name": "Alan Turing", "typeClass": "Class_A"},
        {
            "id": "adaLovelace",
            "name": "Ada Lovelace",
            "typeClass": "Class_A",
            "objectPropertyAssertions": {"prop_x": ["professorAlanTuring"]},
        },
    ]
}


async def test_validator_remaps_misspelled_individual_reference_without_a_retry():
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [TAXONOMIST_OUT, RELATIONAL_FIXED, POPULATOR_MISSPELLED_TARGET]
        events = await _collect_events()

    # No retry was needed: the validator repaired the reference in place.
    assert not any(event["status"] == "retrying" for event in events)
    assert events[-1]["status"] == "success"
    ada = next(
        ind for ind in events[-1]["payload"]["individuals"] if ind["id"] == "adaLovelace"
    )
    assert ada["objectPropertyAssertions"]["prop_x"] == ["alanTuring"]


async def test_validator_prunes_unmatchable_assertions_after_exhausting_retries():
    unmatchable = {
        "individuals": [
            {
                "id": "adaLovelace",
                "name": "Ada Lovelace",
                "typeClass": "Class_A",
                "objectPropertyAssertions": {"prop_x": ["somethingCompletelyUnrelated"]},
            }
        ]
    }
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        # Populator returns the same unrepairable output on every retry.
        mock_gen.side_effect = [TAXONOMIST_OUT, RELATIONAL_FIXED] + [unmatchable] * 5
        events = await _collect_events()

    # Retries were spent, but the run still ends valid: the dangling
    # assertion was pruned instead of failing the whole generation.
    assert any(event["status"] == "retrying" for event in events)
    assert events[-1]["status"] == "success"
    ada = events[-1]["payload"]["individuals"][0]
    assert ada["objectPropertyAssertions"] == {}


async def test_validator_prunes_property_with_hallucinated_domain_after_retries():
    # A dangling `domain` the retries never fix (the live nexolabs failure:
    # the model hallucinated English class names for a Spanish taxonomy) is
    # amputated as the last resort instead of failing the whole generation.
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [TAXONOMIST_OUT] + [
            {
                "object_properties": [
                    {"id": "prop_x", "name": "x", "domain": "Class_Ghost", "range": "Class_A"}
                ],
                "data_properties": [],
            },
            POPULATOR_OUT,
        ] * 5
        events = await _collect_events()

    assert events[-1]["status"] == "success"
    assert any(event["status"] == "retrying" for event in events)
    assert events[-1]["payload"]["object_properties"] == []


def test_correction_note_includes_previous_output_for_editing():
    from api.core.graph import _correction_note

    state = {
        "retry_stage": "populator",
        "last_error": "individuals: individual 'x' asserts a relation to undeclared individual 'y'",
        "individuals": [{"id": "x", "name": "X", "typeClass": "Class_A"}],
    }
    note = _correction_note(state, "populator")
    # The retrying stage sees its own previous output and is told to edit it,
    # not regenerate — the countermeasure to fixing errors by omission.
    assert "'id': 'x'" in note
    assert "keep every entry" in note
    assert "undeclared individual 'y'" in note

    # Stages before the retry point don't re-run, so they get no note.
    assert _correction_note(state, "taxonomist") == ""


# =====================================================================
# LOSSLESS REPAIRS FOR THE FAILURE MODES OBSERVED IN THE LIVE UI RUN
# (id collisions with class ids; inverted assertions; non-conforming
# data properties when the hierarchy is missing)
# =====================================================================
TAXONOMIST_TWO_CLASSES = {
    "classes": [
        {"id": "Department", "name": "Department"},
        {"id": "Laboratory", "name": "Laboratory"},
    ]
}


async def test_validator_renames_individual_colliding_with_a_class_id():
    populator_out = {
        "individuals": [
            # Reuses the class id verbatim — must be renamed, and the
            # assertion pointing at it must follow the rename.
            {"id": "Laboratory", "name": "Turing Laboratory", "typeClass": "Laboratory"},
            {
                "id": "csDept",
                "name": "CS Department",
                "typeClass": "Department",
                "objectPropertyAssertions": {"prop_uses": ["Laboratory"]},
            },
        ]
    }
    relational_out = {
        "object_properties": [
            {"id": "prop_uses", "name": "uses", "domain": "Department", "range": "Laboratory"}
        ],
        "data_properties": [],
    }
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [TAXONOMIST_TWO_CLASSES, relational_out, populator_out]
        events = await _collect_events()

    assert not any(event["status"] == "retrying" for event in events)
    assert events[-1]["status"] == "success"
    individuals = {ind["id"]: ind for ind in events[-1]["payload"]["individuals"]}
    assert "Laboratory" not in individuals  # renamed away from the class id
    renamed = next(id_ for id_ in individuals if id_.startswith("Laboratory_"))
    assert individuals["csDept"]["objectPropertyAssertions"]["prop_uses"] == [renamed]


async def test_validator_swaps_a_cleanly_inverted_assertion():
    relational_out = {
        "object_properties": [
            # worksFor: Professor -> Department
            {"id": "worksFor", "name": "works for", "domain": "Professor", "range": "Department"}
        ],
        "data_properties": [],
    }
    populator_out = {
        "individuals": [
            {"id": "turing", "name": "Alan Turing", "typeClass": "Professor"},
            {
                "id": "csDept",
                "name": "CS Department",
                "typeClass": "Department",
                # Asserted backwards, exactly as observed live.
                "objectPropertyAssertions": {"worksFor": ["turing"]},
            },
        ]
    }
    taxonomist_out = {
        "classes": [
            {"id": "Professor", "name": "Professor"},
            {"id": "Department", "name": "Department"},
        ]
    }
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [taxonomist_out, relational_out, populator_out]
        events = await _collect_events()

    assert not any(event["status"] == "retrying" for event in events)
    assert events[-1]["status"] == "success"
    individuals = {ind["id"]: ind for ind in events[-1]["payload"]["individuals"]}
    assert individuals["turing"]["objectPropertyAssertions"]["worksFor"] == ["csDept"]
    assert individuals["csDept"]["objectPropertyAssertions"] == {}


async def test_validator_prunes_non_conforming_data_property_after_retries():
    # fullName's domain is Person, but the taxonomist never declared
    # Professor as a subclass of Person — the populator can't fix that, so
    # after the retry budget the assertion is dropped rather than failing
    # the entire generation (the live UI failure mode).
    taxonomist_out = {
        "classes": [
            {"id": "Person", "name": "Person"},
            {"id": "Professor", "name": "Professor"},  # note: no subClassOf
        ]
    }
    relational_out = {
        "object_properties": [],
        "data_properties": [
            {"id": "fullName", "name": "full name", "domain": "Person", "range": "xsd:string"}
        ],
    }
    populator_out = {
        "individuals": [
            {
                "id": "turing",
                "name": "Alan Turing",
                "typeClass": "Professor",
                "dataPropertyAssertions": {"fullName": "Alan Turing"},
            }
        ]
    }
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [taxonomist_out, relational_out] + [populator_out] * 6
        events = await _collect_events()

    assert events[-1]["status"] == "success"
    turing = events[-1]["payload"]["individuals"][0]
    assert turing["dataPropertyAssertions"] == {}


async def test_validator_dedupes_duplicate_object_property_ids_without_a_retry():
    # Two object properties sharing an id 'isRelatedTo' — a flat-namespace
    # collision observed live on the okapi PDF. The later one is renamed
    # losslessly instead of failing the generation.
    relational_out = {
        "object_properties": [
            {"id": "isRelatedTo", "name": "is related to", "domain": "Class_A", "range": "Class_A"},
            {"id": "isRelatedTo", "name": "is akin to", "domain": "Class_A", "range": "Class_A"},
        ],
        "data_properties": [],
    }
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [TAXONOMIST_OUT, relational_out, POPULATOR_OUT]
        events = await _collect_events()

    assert not any(event["status"] == "retrying" for event in events)
    assert events[-1]["status"] == "success"
    ids = [op["id"] for op in events[-1]["payload"]["object_properties"]]
    assert len(ids) == 2 and len(set(ids)) == 2  # collision resolved
    assert "isRelatedTo" in ids


async def test_validator_drops_byte_identical_duplicate_entry():
    relational_out = {
        "object_properties": [
            {"id": "prop_x", "name": "x", "domain": "Class_A", "range": "Class_A", "characteristics": []},
            {"id": "prop_x", "name": "x", "domain": "Class_A", "range": "Class_A", "characteristics": []},
        ],
        "data_properties": [],
    }
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [TAXONOMIST_OUT, relational_out, POPULATOR_OUT]
        events = await _collect_events()

    assert events[-1]["status"] == "success"
    assert len(events[-1]["payload"]["object_properties"]) == 1  # exact dup dropped


async def test_pipeline_rejects_over_length_input_fast_with_terminal_event():
    # A ~30k-token document can never fit the 16k context window — the
    # pipeline must refuse it instantly with an actionable message and a
    # terminal 'done' frame (the UI only stops its spinner on 'done'),
    # without ever calling the LLM.
    from api.core.graph import MAX_INPUT_CHARS

    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        events = await _collect_events(text="x" * (MAX_INPUT_CHARS + 1))

    mock_gen.assert_not_called()
    assert events[-1]["stage"] == "done"
    assert events[-1]["status"] == "failed"
    assert "too long" in events[-1]["error"]
    # Machine-readable code + params let the frontend localize the message.
    assert events[-1]["code"] == "input_too_long"
    assert events[-1]["params"] == {"count": MAX_INPUT_CHARS + 1, "max": MAX_INPUT_CHARS}


async def test_llm_failure_ends_with_a_terminal_done_frame():
    # Regression: this failure path used to emit only a 'generation' frame,
    # which the client doesn't treat as terminal — the UI span forever on a
    # generation that had already died (observed live with a long PDF).
    with patch(
        "api.core.graph.generate_structured", new=AsyncMock(side_effect=LLMGenerationError("boom"))
    ):
        events = await _collect_events()

    assert [e["stage"] for e in events[-2:]] == ["generation", "done"]
    assert events[-1]["status"] == "failed"
    assert "boom" in events[-1]["error"]
    assert events[-1]["code"] == "llm_error"

