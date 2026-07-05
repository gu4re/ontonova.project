import json
import os
from typing import Any, Dict, List

import httpx

DEFAULT_MODEL_NAME = os.getenv("LLM_MODEL_NAME", "Qwen/Qwen3-14B-AWQ")
# A single guided-JSON completion for a dense domain text (long prompt +
# large structured output, e.g. many object/data properties or individuals)
# can legitimately run for minutes at ~75 tok/s on a 14B model — too short a
# timeout aborts an in-progress, otherwise-healthy generation client-side.
DEFAULT_TIMEOUT_SECONDS = float(os.getenv("LLM_REQUEST_TIMEOUT_SECONDS", "300"))


class LLMGenerationError(Exception):
    """Raised when a vLLM completion cannot be obtained or parsed as JSON.

    The caller (core.graph) uses this to trigger the self-healing retry path
    instead of letting the whole pipeline crash.
    """


async def generate_structured(
    messages: List[Dict[str, str]],
    json_schema: Dict[str, Any],
    base_url: str,
    model: str = DEFAULT_MODEL_NAME,
    timeout: float = DEFAULT_TIMEOUT_SECONDS,
) -> Dict[str, Any]:
    """
    Requests a chat completion constrained to `json_schema` via vLLM's guided
    decoding (grammar-based sampling / logit filtering), and returns the
    parsed JSON object.
    """
    payload = {
        "model": model,
        "messages": messages,
        "temperature": 0.0,
        # Greedy decoding (temperature=0) has no randomness to escape a
        # repetition loop once one starts, and guided_json's grammar only
        # constrains *structure* — it happily allows a degenerate stream of
        # "valid but pointless" array items forever. A mild repetition
        # penalty is the standard countermeasure. Without it, a dense/complex
        # domain text can make the model loop until it exhausts max_tokens,
        # producing a multi-hundred-KB truncated (invalid) JSON blob that
        # takes minutes to fail on.
        "repetition_penalty": 1.15,
        # Each agent only emits its own slice of the schema, not the whole
        # ontology — a hard ceiling turns a runaway generation into a fast,
        # cheap failure the self-healing loop can retry, instead of a
        # multi-minute hang that still ends in failure anyway.
        "max_tokens": 8192,
        # `guided_json` is a top-level field in vLLM's OpenAI-compatible wire
        # protocol, NOT the OpenAI Python SDK's `extra_body={...}` wrapper —
        # that wrapper only exists client-side to merge extra keys into the
        # request when using `openai.OpenAI(...)`. Since we POST raw JSON
        # directly via httpx, it must be sent unwrapped or vLLM silently
        # ignores it and returns unconstrained free text.
        "guided_json": json_schema,
        # The JSON grammar allows unlimited whitespace between tokens, and a
        # degenerate newline loop can silently burn the whole token budget
        # (observed live: 20k newline-only lines before truncation). Legit
        # output never emits five consecutive newlines, so this stop string
        # turns that loop into a fast, clearly-reported failure.
        "stop": ["\n\n\n\n\n"],
    }

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(f"{base_url}/chat/completions", json=payload)
            response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        # str(exc) only names the status and URL; the actionable explanation
        # (e.g. vLLM's "maximum context length is N tokens...") is in the
        # response body — surface it, it's what the user needs to see.
        body = exc.response.text.strip()
        detail = body[:500] if body else str(exc)
        raise LLMGenerationError(f"LLM endpoint at {base_url} rejected the request: {detail}") from exc
    except httpx.HTTPError as exc:
        # Some httpx exceptions (e.g. ReadTimeout) stringify to an empty
        # message, which makes "Failed to reach ...: " useless for
        # diagnosing what actually happened — always include the exception
        # type name too.
        detail = str(exc) or type(exc).__name__
        raise LLMGenerationError(f"Failed to reach LLM endpoint at {base_url}: {detail}") from exc

    try:
        body = response.json()
        choice = body["choices"][0]
        content = choice["message"]["content"]
        # Distinguish truncation from malformation: a completion cut by the
        # token budget (finish_reason "length") or by the anti-loop stop
        # string (vLLM reports the matched string in `stop_reason`) can
        # never parse, and saying so is far more actionable than a JSON
        # position error.
        if choice.get("finish_reason") == "length" or choice.get("stop_reason") is not None:
            raise LLMGenerationError(
                f"LLM output truncated (finish_reason="
                f"{choice.get('finish_reason')!r}) after {len(content)} chars — "
                "the model exhausted its output budget or entered a "
                "degenerate whitespace loop"
            )
        return json.loads(content)
    except LLMGenerationError:
        raise
    except (KeyError, IndexError, json.JSONDecodeError) as exc:
        raise LLMGenerationError(f"Malformed LLM response from {base_url}: {exc}") from exc
