import pytest
from rdflib import Graph
from rdflib.namespace import OWL, RDF, RDFS, XSD

from api.core.models import OntoNovaSchema
from api.services.rdf_compiler import ONTO, compile_to_rdf


def _sample_schema() -> OntoNovaSchema:
    return OntoNovaSchema(
        **{
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
                {
                    "id": "attr_tieneEdad",
                    "name": "tiene edad",
                    "domain": "Class_Persona",
                    "range": "xsd:integer",
                }
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
    )


def _compile_and_parse(fmt: str) -> Graph:
    body = compile_to_rdf(_sample_schema(), fmt)
    graph = Graph()
    graph.parse(data=body, format=fmt)
    return graph


def test_compile_to_rdf_xml_contains_expected_triples():
    graph = _compile_and_parse("xml")

    assert (ONTO.Class_Profesor, RDF.type, OWL.Class) in graph
    assert (ONTO.Class_Profesor, RDFS.subClassOf, ONTO.Class_Persona) in graph
    assert (ONTO.prop_ensenaA, RDF.type, OWL.ObjectProperty) in graph
    assert (ONTO.prop_ensenaA, RDF.type, OWL.FunctionalProperty) in graph
    assert (ONTO.attr_tieneEdad, RDF.type, OWL.DatatypeProperty) in graph
    assert (ONTO.attr_tieneEdad, RDFS.range, XSD.integer) in graph
    assert (ONTO.inst_profesorJuan, RDF.type, ONTO.Class_Profesor) in graph
    assert (ONTO.inst_profesorJuan, RDF.type, OWL.NamedIndividual) in graph
    assert (ONTO.inst_profesorJuan, ONTO.attr_tieneEdad, None) in graph


def test_compile_to_rdf_turtle_has_same_triples_as_xml():
    xml_graph = _compile_and_parse("xml")
    turtle_graph = _compile_and_parse("turtle")

    assert set(xml_graph) == set(turtle_graph)


def test_compile_to_rdf_rejects_unsupported_format():
    with pytest.raises(ValueError):
        compile_to_rdf(_sample_schema(), "json-ld")
