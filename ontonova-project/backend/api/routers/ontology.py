import json
from typing import Any, Dict, Literal

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response, StreamingResponse
from pydantic import BaseModel

from api.core.graph import stream_ontology_generation
from api.core.models import OntoNovaSchema
from api.core.validator import validate_ontonova_json
from api.services.rdf_compiler import compile_to_rdf

router = APIRouter()

# Maps the public API format name to (rdflib format, media type, file extension).
_EXPORT_FORMATS = {
    "rdf-xml": ("xml", "application/rdf+xml", "rdf"),
    "turtle": ("turtle", "text/turtle", "ttl"),
}


class GenerateRequest(BaseModel):
    text: str
    language: str = ""  # blank means auto-detect from the text (REQ-US-FC-01)


class ExportRequest(BaseModel):
    ontology: Dict[str, Any]
    format: Literal["rdf-xml", "turtle"]


@router.post("/generate")
async def generate_ontology(request: GenerateRequest) -> StreamingResponse:
    """
    Kicks off the taxonomist/relational/populator/validator pipeline and
    streams one SSE frame per stage (REQ-US-FC-01/02/03).
    """

    async def event_stream():
        async for event in stream_ontology_generation(request.text, request.language):
            yield f"data: {json.dumps(event)}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")


@router.post("/validate")
async def validate_ontology(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validates a (possibly in-progress) ontology graph against the OntoNova
    contract. Used by the frontend canvas for reactive, hot validation on
    every edit (REQ-US-FC-04) — returns 200 with structured errors rather
    than a framework-level 422, since an invalid intermediate state is
    expected while the user is editing.
    """
    valid, error = validate_ontonova_json(payload)
    return {"valid": valid, "errors": error}


@router.post("/export")
async def export_ontology(request: ExportRequest) -> Response:
    """Compiles a validated ontology graph to a W3C standard RDF format (REQ-US-FC-05)."""
    valid, error = validate_ontonova_json(request.ontology)
    if not valid:
        raise HTTPException(status_code=422, detail=f"Ontology failed validation: {error}")

    rdf_format, media_type, extension = _EXPORT_FORMATS[request.format]
    schema = OntoNovaSchema(**request.ontology)
    body = compile_to_rdf(schema, rdf_format)

    return Response(
        content=body,
        media_type=media_type,
        headers={"Content-Disposition": f"attachment; filename=ontology.{extension}"},
    )
