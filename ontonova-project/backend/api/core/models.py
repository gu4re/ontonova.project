from typing import List, Dict, Any, Literal, Optional
from pydantic import BaseModel, Field, ConfigDict

# Enforced per prompts/GUIDANCE.md naming convention and OWASP LLM05 (Improper
# Output Handling): identifiers flow verbatim into RDF URI local names in
# services/rdf_compiler.py, so they must be constrained at the schema boundary
# rather than trusted as free text from the LLM.
_ID_PATTERN = r"^[A-Za-z0-9_]+$"

XsdDatatype = Literal["xsd:string", "xsd:integer", "xsd:float", "xsd:boolean", "xsd:dateTime"]
ObjectPropertyCharacteristic = Literal[
    "Functional",
    "InverseFunctional",
    "Transitive",
    "Symmetric",
    "Asymmetric",
    "Reflexive",
    "Irreflexive",
]

# =====================================================================
# CONFIGURACIÓN BASE PARA ESCALABILIDAD
# =====================================================================
class OntoBaseModel(BaseModel):
    # 'forbid' garantiza que si el LLM genera campos inventados, falle la validación.
    # El campo 'metadata' es el cajón de sastre para futuras extensiones (Protégé, UI, etc.)
    model_config = ConfigDict(extra="forbid")
    metadata: Dict[str, Any] = Field(
        default_factory=dict, 
        description="Espacio de almacenamiento dinámico para futuras extensiones del sistema."
    )

# =====================================================================
# COMPONENTES DE LA ONTOLOGÍA (Tus $defs del esquema)
# =====================================================================

class OntoClass(OntoBaseModel):
    id: str = Field(..., pattern=_ID_PATTERN, description="Identificador único de la clase (ID_CamelCase).")
    name: str = Field(..., description="Nombre legible por humanos en inglés o español.")
    subClassOf: Optional[str] = Field(
        None,
        pattern=_ID_PATTERN,
        description="ID de la clase padre si existe una jerarquía taxonómica."
    )


class ObjectProperty(OntoBaseModel):
    id: str = Field(..., pattern=_ID_PATTERN, description="Identificador único de la propiedad de objeto (prop_camelCase).")
    name: str = Field(..., description="Nombre de la relación.")
    domain: str = Field(..., pattern=_ID_PATTERN, description="ID de la Clase origen (Domain).")
    range: str = Field(..., pattern=_ID_PATTERN, description="ID de la Clase destino (Range).")
    characteristics: List[ObjectPropertyCharacteristic] = Field(
        default_factory=list,
        description="Características OWL opcionales (ej. Transitive, Symmetric, Functional)."
    )


class DataProperty(OntoBaseModel):
    id: str = Field(..., pattern=_ID_PATTERN, description="Identificador único del atributo de datos (attr_camelCase).")
    name: str = Field(..., description="Nombre del atributo.")
    domain: str = Field(..., pattern=_ID_PATTERN, description="ID de la Clase a la que pertenece el atributo.")
    range: XsdDatatype = Field(
        ...,
        description="Tipo de dato primitivo XML Schema (xsd:string, xsd:integer, xsd:float, xsd:boolean o xsd:dateTime)."
    )


class Individual(OntoBaseModel):
    id: str = Field(..., pattern=_ID_PATTERN, description="Identificador único de la instancia (inst_camelCase o slug).")
    name: str = Field(..., description="Nombre real de la entidad concreta.")
    typeClass: str = Field(..., pattern=_ID_PATTERN, description="ID de la Clase a la que pertenece este individuo.")
    
    # Asignaciones de relaciones con otros individuos: {"id_propiedad": ["id_individuo_destino"]}
    objectPropertyAssertions: Dict[str, List[str]] = Field(
        default_factory=dict,
        description="Relaciones de este individuo con otros individuos."
    )
    
    # Asignaciones de valores a atributos: {"id_atributo": "valor_primitivo"}
    dataPropertyAssertions: Dict[str, Any] = Field(
        default_factory=dict,
        description="Valores reales asignados a sus atributos de datos."
    )

# =====================================================================
# CONTRATO UNIVERSAL ONTONOVA (El esquema completo)
# =====================================================================

class OntoNovaSchema(BaseModel):
    """
    Contrato de datos definitivo para OntoNova. 
    Gobierna la IA, el Frontend interactivo y el exportador final a Protégé.
    """
    model_config = ConfigDict(extra="forbid")
    
    classes: List[OntoClass] = Field(default_factory=list)
    object_properties: List[ObjectProperty] = Field(default_factory=list)
    data_properties: List[DataProperty] = Field(default_factory=list)
    individuals: List[Individual] = Field(default_factory=list)

    @classmethod
    def generate_json_schema_file(cls, output_path: str = "ontonova_schema.json"):
        """Método de utilidad para exportar el JSON Schema físico para la documentación del TFM."""
        import json
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(cls.model_json_schema(), f, indent=4, ensure_ascii=False)