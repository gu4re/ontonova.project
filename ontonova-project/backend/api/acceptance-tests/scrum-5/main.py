"""
Acceptance test: dense organizational text (nexolabs.txt) must never end in
a hard failure.

This text reproduced two live failure modes: a degenerate whitespace loop in
guided decoding (truncated JSON after burning the whole token budget) and a
relational agent that hallucinated English class names for a Spanish
taxonomy across every retry (dangling domain/range the assertion-level
pruning could not salvage). The fix extends the deterministic ladder:
truncations are detected and reported clearly, an anti-loop stop string
fails fast, and the last-resort pruning now also amputates properties and
individuals that reference undeclared classes — a degraded graph beats a
dead one (REQ-US-FC-03, REQ-SW-NF-03).

Run (with the live stack up):
    PYTHONPATH=. ./api/bin/python -m pytest api/acceptance-tests/scrum-5/main.py -v -s
"""

import json
import os
from pathlib import Path

import httpx
import pytest

BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "http://localhost:8001")
TEXT_PATH = Path(__file__).parent / "nexolabs.txt"


def test_dense_text_never_hard_fails():
    try:
        httpx.get(f"{BACKEND_BASE_URL}/health", timeout=5).raise_for_status()
    except httpx.HTTPError:
        pytest.skip(f"backend not reachable at {BACKEND_BASE_URL}")

    print("\n=========================================")
    print("📊 ACCEPTANCE TEST: DENSE TEXT RESILIENCE")
    print("=========================================")

    text = TEXT_PATH.read_text(encoding="utf-8")
    events = []
    with httpx.Client(timeout=1800) as client:
        with client.stream(
            "POST",
            f"{BACKEND_BASE_URL}/api/ontologies/generate",
            json={"text": text, "language": ""},
        ) as response:
            response.raise_for_status()
            for line in response.iter_lines():
                line = line.strip()
                if line.startswith("data:"):
                    events.append(json.loads(line[len("data:") :].strip()))

    done = next((event for event in events if event.get("stage") == "done"), None)
    retries = sum(1 for event in events if event.get("status") == "retrying")
    assert done is not None, "stream ended without a terminal event"
    assert done.get("status") == "success", f"hard failure: {done.get('error')}"

    payload = done["payload"]
    connected = set()
    for cls in payload["classes"]:
        if cls.get("subClassOf"):
            connected.add(cls["id"])
            connected.add(cls["subClassOf"])
    for prop in payload["object_properties"]:
        connected.add(prop["domain"])
        connected.add(prop["range"])
    isolated = [cls["id"] for cls in payload["classes"] if cls["id"] not in connected]
    print(
        f"survived with {len(payload['classes'])} classes, "
        f"{len(payload['object_properties'])} object properties, "
        f"{len(payload['individuals'])} individuals ({retries} retries); "
        f"isolated classes: {len(isolated)}/{len(payload['classes'])} {isolated}"
    )
    # The organizational text guarantees at least a skeleton graph.
    assert len(payload["classes"]) >= 3
    assert len(payload["individuals"]) >= 1
