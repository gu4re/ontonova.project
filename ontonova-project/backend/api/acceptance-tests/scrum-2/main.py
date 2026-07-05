import os
import time
import pytest
from api.core.models import OntoNovaSchema
from api.core.validator import validate_ontonova_json

# =====================================================================
# MOCK PAYLOAD: Adaptado al Contrato Definitivo de Pydantic v2
# =====================================================================
@pytest.fixture
def otonova_mock_payload():
    return {
        "classes": [
            {"id": "Class_Persona", "name": "Persona", "subClassOf": None},
            {"id": "Class_Profesor", "name": "Profesor", "subClassOf": "Class_Persona"}
        ],
        "object_properties": [
            {
                "id": "prop_ensenaA", 
                "name": "enseña a", 
                "domain": "Class_Profesor", 
                "range": "Class_Persona", 
                "characteristics": ["Functional"]
            }
        ],
        "data_properties": [
            {
                "id": "attr_tieneEdad", 
                "name": "tiene edad", 
                "domain": "Class_Persona", 
                "range": "xsd:integer"
            }
        ],
        "individuals": [
            {
                "id": "inst_profesorJuan",
                "name": "Juan Pérez",
                "typeClass": "Class_Profesor",
                # El nuevo formato usa diccionarios optimizados para búsquedas rápidas
                "objectPropertyAssertions": {},
                "dataPropertyAssertions": {
                    "attr_tieneEdad": 45
                }
            }
        ]
    }

# =====================================================================
# TEST DE ACEPTACIÓN - SCRUM-2
# =====================================================================

def test_scrum_2_acceptance_pipeline(otonova_mock_payload):
    print("\n=========================================")
    print("📊 RUNNING ACCEPTANCE TEST: SCRUM-2")
    print("=========================================")

    # -----------------------------------------------------------------
    # PASO 1: Validar Generación del JSON Schema físico para el TFM
    # -----------------------------------------------------------------
    # Determinamos una ruta limpia para el esquema generado dentro de docs/
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    schema_output_path = os.path.join(base_dir, "resources", "ontonova_schema.json")
    
    # Aseguramos que la carpeta docs exista
    os.makedirs(os.path.dirname(schema_output_path), exist_ok=True)
    
    # Forzamos a Pydantic a generar el archivo
    OntoNovaSchema.generate_json_schema_file(schema_output_path)
    
    assert os.path.exists(schema_output_path) is True
    assert os.path.getsize(schema_output_path) > 0
    print(f"✅ Criterio 1: JSON Schema exportado con éxito en: {schema_output_path}")

    # -----------------------------------------------------------------
    # PASO 2: Validar rendimiento del validador sintáctico (< 50ms)
    # -----------------------------------------------------------------
    start_time = time.perf_counter()
    
    # Ejecutamos el validador del core
    success, error_msg = validate_ontonova_json(otonova_mock_payload)
    
    end_time = time.perf_counter()
    execution_time_ms = (end_time - start_time) * 1000

    # Assertions del test
    assert success is True, f"El validador falló inesperadamente: {error_msg}"
    assert execution_time_ms < 50.0, f"El validador es lento: {execution_time_ms:.4f} ms"
    
    print(f"✅ Criterio 2: Validación sintáctica exitosa.")
    print(f"⏱️ Tiempo de ejecución medido: {execution_time_ms:.4f} ms (Límite: 50.0 ms)")
    print("=========================================\n")

# For executing with pytest directly from the command line:
# PYTHONPATH=. pytest api/acceptance-tests/scrum-2/main.py -v -s

if __name__ == "__main__":
    # Permite ejecutar el script directamente con 'python test_scrum_2.py' si no usas pytest en local
    import mock
    payload = otonova_mock_payload.__wrapped__()
    test_scrum_2_acceptance_pipeline(payload)