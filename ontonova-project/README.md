# OntoNova

Turn any text into a knowledge graph. OntoNova generates a well-formed
ontology from a free-text domain description — typed directly or attached as
a plain-text file — using a local LLM inference engine, renders it on an
interactive canvas for editing, and exports it to W3C standard formats
(Turtle, RDF/XML).

## Architecture

```
┌──────────────┐  SSE / JSON   ┌──────────────┐  OpenAI-compatible  ┌──────────┐
│   frontend   │ ────────────► │   backend    │ ──────────────────► │   vLLM   │
│ React + Vite │               │   FastAPI    │    (guided_json)    │  (GPU)   │
│  React Flow  │ ◄──────────── │  LangGraph   │ ◄────────────────── │          │
└──────────────┘               └──────────────┘                     └──────────┘
```

- **frontend/** — Vite + React + TypeScript SPA: creation panel (typed text
  up to 15,000 characters, or a `.txt`/`.md`/`.pdf` file up to 5 MB, in any
  language), real-time generation progress, interactive graph canvas,
  inspector, export. See [frontend/README.md](frontend/README.md).
- **backend/** — FastAPI service running a LangGraph multi-agent pipeline
  (taxonomist → relational → populator → validator) with self-healing
  retries. Talks to any OpenAI-compatible endpoint; the model is selected
  purely by configuration. See [backend/README.md](backend/README.md).
- **vLLM** — local GPU inference engine serving the model over the
  OpenAI-compatible protocol with `guided_json` structured decoding.

## Requirements

- Docker with Docker Compose v2
- An NVIDIA GPU with driver + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
  (for the bundled vLLM service; not needed if you point at an external one)
- ~20 GB of free disk for the model weights cache (first run downloads them)

## Quick start

```bash
git clone <repository-url>
cd ontonova-project
docker compose up --build
```

Then open <http://localhost:5173>. The first start can take several minutes
while vLLM downloads and loads the model; the backend waits for its
healthcheck before accepting work.

Service ports: frontend `5173`, backend API `8001`, vLLM `8000`.

### Configuration

All knobs are environment variables (a `.env` file next to
`docker-compose.yml` is picked up automatically):

| Variable | Default | Purpose |
|---|---|---|
| `LLM_MODEL_NAME` | `Qwen/Qwen3-14B-AWQ` | Model served by vLLM and requested by the backend |
| `TAXONOMIST_BASE_URL` / `RELATIONAL_BASE_URL` / `POPULATOR_BASE_URL` | `http://vllm:8000/v1` | Per-agent OpenAI-compatible endpoints |
| `LLM_REQUEST_TIMEOUT_SECONDS` | `300` | Per-completion client timeout |
| `MAX_INPUT_CHARS` | `15000` | Input length budget enforced by the backend pre-flight check |
| `CORS_ORIGINS` | `http://localhost:5173` | Comma-separated allowed origins |
| `VITE_API_BASE_URL` | `http://localhost:8001` | Backend URL baked into the frontend build |
| `HUGGING_FACE_HUB_TOKEN` | — | Only needed for gated models |

Swapping the model or pointing at an external vLLM requires **only** these
variables — no code changes. To use an already-running vLLM:
`docker compose up backend frontend` with the `*_BASE_URL` variables set.

## Using the app

1. Describe your domain in the text box (any language), or attach a
   `.txt`/`.md`/`.pdf` file (up to 5 MB; PDF text is extracted in the
   browser) with the paperclip button.
2. Optionally hint the text's language; it is auto-detected otherwise.
3. Generate: the panel shows each pipeline stage in real time. If
   validation fails, the pipeline self-corrects and retries automatically.
4. Refine the result on the canvas: add/rename/delete classes, relations,
   attributes and individuals; every edit is re-validated reactively.
5. Export from the toolbar as Turtle or RDF/XML.

## Development (without Docker)

Backend (Python 3.12 venv lives in `backend/api/`):

```bash
cd backend
PYTHONPATH=. ./api/bin/uvicorn api.main:app --reload --port 8001
```

Frontend (Node 20+):

```bash
cd frontend
npm install
npm run dev        # http://localhost:5173, API URL from .env (see .env.example)
```

A GPU is not needed for development: backend unit tests mock all LLM calls,
and the frontend e2e suite stubs the API routes it exercises.

## Tests

```bash
# Backend — pytest (unit + router integration, LLM mocked)
cd backend && PYTHONPATH=. ./api/bin/python -m pytest -v

# Frontend — Vitest component/unit tests
cd frontend && npm test

# Frontend — Playwright end-to-end (real Chromium)
cd frontend && npm run test:e2e
```

## Maintenance

- Ontology contract, validation rules and pipeline agents:
  [backend/README.md](backend/README.md) § Maintenance notes.
- The JSON Schema of the ontology contract is published at
  [docs/ontonova-schema.json](docs/ontonova-schema.json). It is a copy of
  [backend/api/resources/ontonova_schema.json](backend/api/resources/ontonova_schema.json),
  which is generated from `backend/api/core/models.py` (the single source of
  truth) by the SCRUM-2 acceptance test — re-copy it after changing the
  contract.
- Dependency audits: `npm audit` (frontend) and `pip-audit` or
  `pip list --outdated` against `backend/api/requirements.txt`.
