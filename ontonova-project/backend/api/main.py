import os

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routers.ontology import router as ontology_router

load_dotenv()

app = FastAPI(title="OntoNova API", version="0.1.0")

_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ontology_router, prefix="/api/ontologies", tags=["ontologies"])


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}
