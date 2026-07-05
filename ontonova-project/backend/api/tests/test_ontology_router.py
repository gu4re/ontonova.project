from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient

from api.main import app

client = TestClient(app)

VALID_ONTOLOGY = {
    "classes": [{"id": "Class_Persona", "name": "Persona", "subClassOf": None}],
    "object_properties": [],
    "data_properties": [],
    "individuals": [],
}


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_validate_accepts_a_valid_ontology():
    response = client.post("/api/ontologies/validate", json=VALID_ONTOLOGY)
    assert response.status_code == 200
    assert response.json() == {"valid": True, "errors": None}


def test_validate_reports_structured_errors_without_422():
    response = client.post("/api/ontologies/validate", json={"classes": [{"id": "X"}]})
    assert response.status_code == 200
    body = response.json()
    assert body["valid"] is False
    assert "name" in body["errors"]


def test_export_turtle_returns_a_downloadable_file():
    response = client.post(
        "/api/ontologies/export", json={"ontology": VALID_ONTOLOGY, "format": "turtle"}
    )
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/turtle")
    assert "ontology.ttl" in response.headers["content-disposition"]
    assert b"Class_Persona" in response.content


def test_export_rdf_xml_returns_a_downloadable_file():
    response = client.post(
        "/api/ontologies/export", json={"ontology": VALID_ONTOLOGY, "format": "rdf-xml"}
    )
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/rdf+xml")
    assert "ontology.rdf" in response.headers["content-disposition"]


def test_export_rejects_an_invalid_ontology_with_422():
    response = client.post(
        "/api/ontologies/export",
        json={"ontology": {"classes": [{"id": "X"}]}, "format": "turtle"},
    )
    assert response.status_code == 422


def test_generate_streams_sse_events_through_to_success():
    with patch("api.core.graph.generate_structured", new=AsyncMock()) as mock_gen:
        mock_gen.side_effect = [
            {"classes": [{"id": "Class_A", "name": "A"}]},
            {"object_properties": [], "data_properties": []},
            {"individuals": []},
        ]
        with client.stream(
            "POST", "/api/ontologies/generate", json={"text": "hi", "language": "en"}
        ) as response:
            assert response.status_code == 200
            lines = [line for line in response.iter_lines() if line]

    assert any('"stage": "taxonomist"' in line for line in lines)
    assert any('"status": "success"' in line for line in lines)
