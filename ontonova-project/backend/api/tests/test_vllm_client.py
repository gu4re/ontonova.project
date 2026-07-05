from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from api.services.vllm_client import LLMGenerationError, generate_structured


def _mock_response(content: str, status_ok: bool = True):
    response = MagicMock()
    response.raise_for_status = MagicMock()
    response.json.return_value = {"choices": [{"message": {"content": content}}]}
    return response


async def test_guided_json_is_sent_as_a_top_level_field_not_wrapped_in_extra_body():
    """
    Regression test: `guided_json` is a top-level field in vLLM's wire
    protocol. `extra_body={...}` is an OpenAI *Python SDK* convenience that
    merges into the request client-side — since we POST raw JSON via httpx,
    sending it nested under "extra_body" makes vLLM silently ignore it and
    return unconstrained free text instead of raising or erroring.
    """
    captured_payload = {}

    async def fake_post(url, json):
        captured_payload.update(json)
        return _mock_response('{"classes": []}')

    with patch("httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.post = AsyncMock(side_effect=fake_post)
        mock_client_cls.return_value.__aenter__.return_value = mock_client

        result = await generate_structured(
            messages=[{"role": "user", "content": "hi"}],
            json_schema={"type": "object"},
            base_url="http://vllm:8000/v1",
        )

    assert result == {"classes": []}
    assert captured_payload["guided_json"] == {"type": "object"}
    assert "extra_body" not in captured_payload


async def test_request_guards_against_degenerate_repetition_loops():
    """
    Regression test: greedy decoding (temperature=0) combined with
    guided_json's structural-only grammar has no mechanism to stop a
    degenerate repetition loop — observed in practice as a multi-hundred-KB
    truncated (invalid) JSON response after several minutes. A repetition
    penalty plus a hard max_tokens ceiling turn that into a fast, cheap
    failure the self-healing loop can retry instead.
    """
    captured_payload = {}

    async def fake_post(url, json):
        captured_payload.update(json)
        return _mock_response('{"classes": []}')

    with patch("httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.post = AsyncMock(side_effect=fake_post)
        mock_client_cls.return_value.__aenter__.return_value = mock_client

        await generate_structured(
            messages=[{"role": "user", "content": "hi"}],
            json_schema={"type": "object"},
            base_url="http://vllm:8000/v1",
        )

    assert captured_payload["repetition_penalty"] > 1.0
    assert 0 < captured_payload["max_tokens"] <= 8192


async def test_raises_llm_generation_error_on_malformed_json_content():
    async def fake_post(url, json):
        return _mock_response("not valid json")

    with patch("httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.post = AsyncMock(side_effect=fake_post)
        mock_client_cls.return_value.__aenter__.return_value = mock_client

        with pytest.raises(LLMGenerationError):
            await generate_structured(
                messages=[{"role": "user", "content": "hi"}],
                json_schema={"type": "object"},
                base_url="http://vllm:8000/v1",
            )
