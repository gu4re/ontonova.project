from typing import Dict, Optional

from rdflib import OWL, RDF, RDFS, XSD, Graph, Literal, Namespace, URIRef

from api.core.models import OntoNovaSchema

ONTO = Namespace("http://ontonova.local/ontology#")

SUPPORTED_FORMATS = ("xml", "turtle")

_CHARACTERISTIC_TO_OWL = {
    "Functional": OWL.FunctionalProperty,
    "InverseFunctional": OWL.InverseFunctionalProperty,
    "Transitive": OWL.TransitiveProperty,
    "Symmetric": OWL.SymmetricProperty,
    "Asymmetric": OWL.AsymmetricProperty,
    "Reflexive": OWL.ReflexiveProperty,
    "Irreflexive": OWL.IrreflexiveProperty,
}

_XSD_RANGE = {
    "xsd:string": XSD.string,
    "xsd:integer": XSD.integer,
    "xsd:float": XSD.float,
    "xsd:boolean": XSD.boolean,
    "xsd:dateTime": XSD.dateTime,
}


def _uri(local_id: str) -> URIRef:
    return ONTO[local_id]


def compile_to_rdf(schema: OntoNovaSchema, fmt: str) -> bytes:
    """
    Compiles a validated OntoNovaSchema (core.models) into an RDF/OWL graph
    and serializes it to a W3C standard format for the export use case
    (REQ-US-FC-05). `fmt` must be one of "xml" (RDF/XML) or "turtle".
    """
    if fmt not in SUPPORTED_FORMATS:
        raise ValueError(f"Unsupported RDF serialization format: {fmt!r}")

    graph = Graph()
    graph.bind("owl", OWL)
    graph.bind("onto", ONTO)

    for cls in schema.classes:
        subject = _uri(cls.id)
        graph.add((subject, RDF.type, OWL.Class))
        graph.add((subject, RDFS.label, Literal(cls.name)))
        if cls.subClassOf:
            graph.add((subject, RDFS.subClassOf, _uri(cls.subClassOf)))

    for prop in schema.object_properties:
        subject = _uri(prop.id)
        graph.add((subject, RDF.type, OWL.ObjectProperty))
        graph.add((subject, RDFS.label, Literal(prop.name)))
        graph.add((subject, RDFS.domain, _uri(prop.domain)))
        graph.add((subject, RDFS.range, _uri(prop.range)))
        for characteristic in prop.characteristics:
            owl_type = _CHARACTERISTIC_TO_OWL.get(characteristic)
            if owl_type is not None:
                graph.add((subject, RDF.type, owl_type))

    data_properties_by_id: Dict[str, object] = {}
    for prop in schema.data_properties:
        subject = _uri(prop.id)
        graph.add((subject, RDF.type, OWL.DatatypeProperty))
        graph.add((subject, RDFS.label, Literal(prop.name)))
        graph.add((subject, RDFS.domain, _uri(prop.domain)))
        graph.add((subject, RDFS.range, _XSD_RANGE.get(prop.range, XSD.string)))
        data_properties_by_id[prop.id] = prop

    for individual in schema.individuals:
        subject = _uri(individual.id)
        graph.add((subject, RDF.type, OWL.NamedIndividual))
        graph.add((subject, RDF.type, _uri(individual.typeClass)))
        graph.add((subject, RDFS.label, Literal(individual.name)))

        for property_id, target_ids in individual.objectPropertyAssertions.items():
            predicate = _uri(property_id)
            for target_id in target_ids:
                graph.add((subject, predicate, _uri(target_id)))

        for property_id, value in individual.dataPropertyAssertions.items():
            predicate = _uri(property_id)
            declared_property = data_properties_by_id.get(property_id)
            datatype: Optional[URIRef] = (
                _XSD_RANGE.get(declared_property.range) if declared_property else None
            )
            graph.add((subject, predicate, Literal(value, datatype=datatype)))

    return graph.serialize(format=fmt, encoding="utf-8")
