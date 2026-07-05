# OntoNova backend

FastAPI service + LangGraph multi-agent ontology generation pipeline. See
the [project README](../README.md) for architecture, use cases, and how to
run the full stack.

## Layout

```
api/
  core/
    models.py      # OntoNovaSchema contract (Pydantic) — the source of truth
    validator.py    # structural + referential-integrity validation
    graph.py         # LangGraph pipeline: taxonomist/relational/populator/validator
  services/
    vllm_client.py    # async client for vLLM's OpenAI-compatible API (guided_json)
    rdf_compiler.py   # OntoNovaSchema -> RDF/XML | Turtle via rdflib
  routers/ontology.py  # /generate (SSE), /validate, /export
  prompts/GUIDANCE.md  # shared system prompt fragment for all three agents
  tests/               # pytest suite (LLM calls are mocked, no GPU needed)
```

## Maintenance notes

- **Changing the ontology contract:** edit `core/models.py` first (it drives
  the JSON schemas sent to vLLM via `guided_json`, the RDF compiler, and the
  generated `resources/ontonova_schema.json`). Regenerate the latter by
  running `pytest api/acceptance-tests/scrum-2/main.py`.
- **Adding a new specialist agent:** add a node function in `core/graph.py`
  following the existing taxonomist/relational/populator pattern (own
  scoped output schema, own `_BASE_URL` env var), wire it into the graph's
  edges, and extend `_stage_from_error` so self-healing can route to it.
- **Changing validation rules:** structural rules live in `core/models.py`
  (Pydantic field constraints); cross-reference rules (e.g. "domain must be
  a declared class id") live in `core/validator.py`'s
  `_check_referential_integrity`.

## Run

```bash
PYTHONPATH=. ./api/bin/uvicorn api.main:app --reload --port 8001
```

## Test

```bash
PYTHONPATH=. ./api/bin/python -m pytest -v
```

### Graph-quality acceptance test

Scores a real end-to-end generation against a hand-crafted gold-standard
ontology (precision/recall/F1 per category). Needs the live stack
(`docker compose up vllm backend`); it skips itself if the backend is down.

```bash
PYTHONPATH=. ./api/bin/python -m pytest api/acceptance-tests/scrum-3/graph-quality/main.py -v -s
```

The acceptance floor is `GRAPH_QUALITY_MIN_MACRO_F1` (default 0.5); the full
scored report is written next to the test as `graph-quality-report.json`.
