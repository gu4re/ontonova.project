import { afterEach, describe, expect, it, vi } from "vitest";
import { exportOntology, generateOntology, validateOntology } from "./client";
import type { OntoNovaSchema } from "../types/ontology";

const SAMPLE_SCHEMA: OntoNovaSchema = {
  classes: [{ id: "Class_Person", name: "Person", subClassOf: null }],
  object_properties: [],
  data_properties: [],
  individuals: [],
};

function makeStreamResponse(chunks: string[]) {
  const encoder = new TextEncoder();
  let index = 0;
  return {
    ok: true,
    status: 200,
    body: {
      getReader: () => ({
        read: async () => {
          if (index < chunks.length) {
            const value = encoder.encode(chunks[index]);
            index += 1;
            return { value, done: false };
          }
          return { value: undefined, done: true };
        },
      }),
    },
  };
}

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("generateOntology", () => {
  it("parses SSE frames split across chunk boundaries and invokes onEvent for each", async () => {
    const doneFrame = `data: ${JSON.stringify({
      stage: "done",
      status: "success",
      payload: SAMPLE_SCHEMA,
    })}\n\n`;
    const firstFrame = 'data: {"stage":"taxonomist","status":"completed"}\n\n';
    // Split the first frame mid-way to exercise the buffering logic.
    const chunks = [firstFrame.slice(0, 10), firstFrame.slice(10), doneFrame];

    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(makeStreamResponse(chunks)));

    const events: Array<{ stage: string; status: string }> = [];
    const onEvent = vi.fn((event) => events.push(event));
    const onError = vi.fn();

    generateOntology("some text", "en", onEvent, onError);
    await vi.waitFor(() => expect(onEvent).toHaveBeenCalledTimes(2));

    expect(events[0]).toEqual({ stage: "taxonomist", status: "completed" });
    expect(events[1]).toMatchObject({ stage: "done", status: "success" });
    expect(onError).not.toHaveBeenCalled();
  });

  it("reports an error when the HTTP response is not ok", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: false, status: 500, body: null }));

    const onError = vi.fn();
    generateOntology("x", "en", vi.fn(), onError);

    await vi.waitFor(() => expect(onError).toHaveBeenCalled());
    expect(onError).toHaveBeenCalledWith(expect.stringContaining("500"));
  });

  it("reports an error when the stream closes without a terminal 'done' frame", async () => {
    // Regression: a backend failure path that forgot the terminal frame left
    // the UI spinning forever — the client must detect the truncated stream.
    const chunks = ['data: {"stage":"taxonomist","status":"completed"}\n\n'];
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(makeStreamResponse(chunks)));

    const onError = vi.fn();
    generateOntology("some text", "en", vi.fn(), onError);

    await vi.waitFor(() => expect(onError).toHaveBeenCalled());
    expect(onError).toHaveBeenCalledWith(expect.stringContaining("ended unexpectedly"));
  });

  it("does not report a truncated stream when the caller aborts it", async () => {
    // Aborting (unmount / regenerate) is a deliberate cancellation, not an
    // error — onError firing here would flash a bogus failure toast.
    vi.stubGlobal(
      "fetch",
      vi.fn().mockImplementation(
        (_url, init: RequestInit) =>
          new Promise((_resolve, reject) => {
            init.signal?.addEventListener("abort", () =>
              reject(new DOMException("aborted", "AbortError")),
            );
          }),
      ),
    );

    const onError = vi.fn();
    const controller = generateOntology("some text", "en", vi.fn(), onError);
    controller.abort();

    // Give the rejected fetch a tick to propagate before asserting silence.
    await new Promise((resolve) => setTimeout(resolve, 20));
    expect(onError).not.toHaveBeenCalled();
  });
});

describe("validateOntology", () => {
  it("posts the schema and returns the parsed validation result", async () => {
    const fetchMock = vi.fn().mockResolvedValue({ json: async () => ({ valid: true, errors: null }) });
    vi.stubGlobal("fetch", fetchMock);

    const result = await validateOntology(SAMPLE_SCHEMA);

    expect(result).toEqual({ valid: true, errors: null });
    expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining("/api/ontologies/validate"),
      expect.objectContaining({ method: "POST" }),
    );
  });
});

describe("exportOntology", () => {
  it("throws with the server-provided detail when the export request fails", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 422,
        json: async () => ({ detail: "Ontology failed validation: bad stuff" }),
      }),
    );

    await expect(exportOntology(SAMPLE_SCHEMA, "turtle")).rejects.toThrow("bad stuff");
  });

  it("triggers a file download on success", async () => {
    const blob = new Blob(["@prefix onto: <http://example.org/> ."], { type: "text/turtle" });
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: true, blob: async () => blob }));
    vi.stubGlobal("URL", { createObjectURL: vi.fn(() => "blob:fake"), revokeObjectURL: vi.fn() });
    const clickSpy = vi.spyOn(HTMLAnchorElement.prototype, "click").mockImplementation(() => {});

    await exportOntology(SAMPLE_SCHEMA, "turtle");

    expect(clickSpy).toHaveBeenCalledOnce();
  });
});
