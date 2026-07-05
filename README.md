# OntoNova

Web-based knowledge management system that turns natural-language domain
descriptions into a validated OWL/RDF ontology using a locally-hosted LLM,
with an interactive canvas to review, edit and export the result. Built
against the requirements and use cases in `../thesis/parts/analysis.typ`.

## Use cases

| # | Use case | Requirements |
|---|----------|--------------|
| 1 | **Create** — submit a domain description, watch the ontology get generated live | REQ-US-FC-01/02/03/10 |
| 2 | **Edit** — add/rename/delete classes and relations on an interactive canvas, validated as you go | REQ-US-FC-04 |
| 3 | **Delete** — discard the current ontology after a confirmation step | REQ-US-FC-04 |
| 4 | **Export** — download the validated ontology as RDF/XML or Turtle | REQ-US-FC-05 |

Out of scope for this MVP (explicitly marked "Opcional" / "Requiere nuevo
diseño" / low priority in the thesis's requirements table): multi-user
concurrent editing, version history, ontology import, user accounts,
persistence of past ontologies. The backend is intentionally stateless —
the frontend holds the working ontology in memory and the backend
validates/compiles on demand.

## Architecture

```
                     ┌─────────────┐        SSE / REST        ┌──────────────┐
   user's browser →  │   frontend   │ ────────────────────────▶│   backend    │
                     │ React + Vite │◀──────────────────────── │   FastAPI    │
                     │ React Flow   │      JSON / RDF files     └──────┬───────┘
                     └─────────────┘                                  │ OpenAI-compatible
                                                                       │ HTTP API
                                                                ┌──────▼───────┐
                                                                │     vLLM     │
                                                                │ Qwen3-14B-AWQ│
                                                                │  (GPU, local)│
                                                                └──────────────┘
```

- **`backend/api`** — FastAPI service. `core/graph.py` runs a 3-agent
  LangGraph pipeline (taxonomist → relational → populator → validator) that
  calls vLLM's OpenAI-compatible endpoint with `guided_json` (grammar-based
  structured decoding) so every agent can only emit its own slice of the
  ontology contract. A self-healing loop re-prompts the failing agent (up to
  2 retries) using the validator's error, catching both Pydantic structural
  errors and dangling-reference (well-formedness) errors. `services/rdf_compiler.py`
  compiles the validated schema to RDF/XML or Turtle via `rdflib`.
- **`backend/llm-server`** — reference scripts for running vLLM directly on
  bare metal (used during development on the GPU box); superseded by the
  `vllm` service in `docker-compose.yml` for normal use.
- **`frontend`** — Vite + React + TypeScript SPA, styled with Tailwind CSS
  v4 and a light/dark theme toggle (persisted to `localStorage`, defaulting
  to the OS `prefers-color-scheme`). The canvas is a full-bleed base layer
  with the header and both side panels floating above it as translucent,
  blurred, rounded cards rather than a docked grid with hard dividers — the
  inspector card only mounts (with a `framer-motion` transition) once a
  class is selected. `@xyflow/react` (React Flow) renders classes as nodes
  and object properties/subClassOf as edges; `zustand` holds the working
  ontology graph; edits are validated against the backend on a short
  debounce. Radix UI primitives (`Dialog`, `DropdownMenu`, `Tooltip`) back
  the reset-confirmation, export menu, and icon-button hints;
  `framer-motion` animates the generation stepper and canvas nodes;
  `lucide-react` supplies icons; `sonner` surfaces toast notifications. The
  UI itself is internationalized (`i18next`/`react-i18next`) with a
  language switcher in
  the header — English, Spanish, French, German — independent of the
  per-generation domain-text language hint in the create panel.

## Run everything with one command

Requires a host with an NVIDIA GPU, the [NVIDIA Container
Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
installed, and Docker Compose v2 (`docker compose`, not the legacy
`docker-compose`).

```bash
docker compose up --build
```

This starts three services:

- `vllm` — `vllm/vllm-openai`, serving `Qwen/Qwen3-14B-AWQ` on `:8000`. First
  run downloads the model (cached in a named volume afterwards) and can take
  several minutes; `docker compose ps` shows `healthy` once it's ready.
- `backend` — FastAPI on `:8001`.
- `frontend` — static build served by nginx on `:5173`.

Then open **http://localhost:5173**. Verified end-to-end on the project's
WSL2 + RTX 4090 dev box: `docker compose up --build` brings up all three
services, and a real domain description produces a valid, exportable
ontology through the full taxonomist → relational → populator → validator
pipeline.

To stop everything:

```bash
docker compose down
```

This stops and removes the `vllm`/`backend`/`frontend` containers and the
network, but keeps the named volume that caches the downloaded model — so
the next `docker compose up` doesn't need to re-download it. Use `docker
compose stop` instead if you just want to pause without removing the
containers, or add `-v` to `down` to also wipe the model cache.

> **WSL2 note:** the `vllm` image is pinned to `v0.9.2`. Newer `vllm-openai`
> releases (`v0.16.0`+, tested up to `v0.24.0`) ship a GPU worker rewrite
> that crashes with `RuntimeError: UVA is not available` under WSL2's
> virtualized GPU driver — v0.9.2 predates that code path and works.
> Bare-metal Linux hosts are likely unaffected; if you hit this on WSL2 with
> `backend/llm-server/main.sh` instead of Compose, pin your `vllm` pip
> install to `0.9.2` too.

To point at a vLLM instance you run yourself instead of the bundled one
(e.g. a different model, or one already warm), set
`TAXONOMIST_BASE_URL` / `RELATIONAL_BASE_URL` / `POPULATOR_BASE_URL` in a
`.env` file next to `docker-compose.yml` and start only the other two
services: `docker compose up backend frontend`.

## Local development (without Docker)

### Backend

```bash
cd backend/api
python3 -m venv .   # or reuse the existing venv in this folder
./bin/pip install -r requirements.txt
cp .env.example .env   # adjust base URLs if your vLLM isn't on localhost:8000
cd ..                  # PYTHONPATH must resolve `api` as a package
PYTHONPATH=. ./api/bin/uvicorn api.main:app --reload --port 8001
```

Start vLLM separately (see `backend/llm-server/main.sh` for the exact flags
used in development):

```bash
./backend/llm-server/main.sh
```

### Frontend

```bash
cd frontend
npm install
cp .env.example .env   # VITE_API_BASE_URL, defaults to http://localhost:8001
npm run dev
```

## Testing

```bash
# Backend — 26 tests, no GPU required (the LLM client is mocked)
cd backend && PYTHONPATH=. ./api/bin/python -m pytest -v

# Frontend — unit/component tests (Vitest + React Testing Library)
cd frontend && npm test

# Frontend — type check + production build
cd frontend && npm run build

# Frontend — end-to-end (Playwright, real Chromium), against a running frontend
cd frontend && npx playwright install --with-deps chromium   # first time only
E2E_BASE_URL=http://localhost:5173 npm run test:e2e          # against docker compose
# or, with no backend running, npm run test:e2e alone starts `npm run dev` for you
```

## Environment variables

| Variable | Where | Default | Purpose |
|---|---|---|---|
| `TAXONOMIST_BASE_URL` / `RELATIONAL_BASE_URL` / `POPULATOR_BASE_URL` | backend | `http://localhost:8000/v1` (host) / `http://vllm:8000/v1` (compose) | OpenAI-compatible endpoint per agent — can point at different models/instances for true multi-model orchestration (REQ-SW-FC-02) |
| `LLM_MODEL_NAME` | backend | `Qwen/Qwen3-14B-AWQ` | Model name sent in each completion request |
| `LLM_REQUEST_TIMEOUT_SECONDS` | backend | `300` | HTTP timeout per LLM call — dense domain texts can need minutes for one agent's guided-JSON completion |
| `CORS_ORIGINS` | backend | `http://localhost:5173` | Comma-separated list of allowed frontend origins |
| `VITE_API_BASE_URL` | frontend (build-time) | `http://localhost:8001` | Backend base URL baked into the static build |

## Known limitations

- **Accessibility (REQ-SW-NF-01):** forms, dialogs and buttons are labeled
  and keyboard-operable, but the canvas's double-click-to-rename gesture has
  no keyboard equivalent yet — inherent to freeform node/edge canvases
  (same limitation as most diagramming tools). Flagged as "Viable" rather
  than "Incluido" in the thesis's own requirement status.
- **No auth/persistence:** by design for this MVP (see "Out of scope"
  above) — REQ-US-FC-06/07/08/09 are marked optional or "requires new
  design" in the source requirements table.
- **Small/quantized model quality:** Qwen3-14B-AWQ occasionally produces a
  domain-modeling choice that's structurally valid but semantically odd
  (e.g. an unexpected class hierarchy) — the self-healing loop guarantees
  *well-formedness*, not domain-modeling judgment. A larger or non-quantized
  model on the same OpenAI-compatible endpoint will generally model better.
