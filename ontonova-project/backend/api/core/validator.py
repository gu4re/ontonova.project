from .models import OntoNovaSchema
from pydantic import ValidationError
from typing import Optional

def validate_ontonova_json(raw_json: dict) -> tuple[bool, Optional[str]]:
    """
    Valida sintácticamente si un JSON cumple con el contrato OntoNova.
    Devuelve (True, None) si es válido, o (False, "Mensaje de error") si falla.
    """
    try:
        # Intenta parsear el JSON crudo en nuestro modelo estricto
        OntoNovaSchema(**raw_json)
        return True, None
    except ValidationError as e:
        # Extrae el error estructurado ideal para el Self-Healing de la SCRUM-6
        return False, str(e.errors())