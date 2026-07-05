import type { ExportFormat, GenerationEvent, OntoNovaSchema } from "../types/ontology";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8001";

export interface ValidationResult {
  valid: boolean;
  errors: string | null;
}

/**
 * Opens the SSE-over-fetch stream for ontology generation (`/generate` returns
 * `text/event-stream`, but the payload is POSTed so a native EventSource can't
 * be used). Returns an AbortController the caller can use to cancel the stream.
 */
export function generateOntology(
  text: string,
  language: string,
  onEvent: (event: GenerationEvent) => void,
  onError: (message: string) => void,
): AbortController {
  const controller = new AbortController();

  (async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/ontologies/generate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text, language }),
        signal: controller.signal,
      });

      if (!response.ok || !response.body) {
        onError(`Generation request failed with status ${response.status}`);
        return;
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";
      let sawTerminalEvent = false;

      for (;;) {
        const { value, done } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });

        const frames = buffer.split("\n\n");
        buffer = frames.pop() ?? "";

        for (const frame of frames) {
          const line = frame.trim();
          if (!line.startsWith("data:")) continue;
          const json = line.slice("data:".length).trim();
          if (!json) continue;
          try {
            const generationEvent = JSON.parse(json) as GenerationEvent;
            if (generationEvent.stage === "done") sawTerminalEvent = true;
            onEvent(generationEvent);
          } catch {
            // A single malformed/truncated frame shouldn't abort an
            // otherwise-healthy stream — skip it and keep reading.
          }
        }
      }

      // A stream that closes without a terminal 'done' frame (backend bug,
      // proxy cutting the connection, ...) must not leave the UI spinning
      // forever — surface it as an error so the caller can reset its state.
      if (!sawTerminalEvent) {
        onError("The generation stream ended unexpectedly. Please try again.");
      }
    } catch (error) {
      if (controller.signal.aborted) return;
      onError(error instanceof Error ? error.message : "Unknown generation error");
    }
  })();

  return controller;
}

export async function validateOntology(ontology: OntoNovaSchema): Promise<ValidationResult> {
  const response = await fetch(`${API_BASE_URL}/api/ontologies/validate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(ontology),
  });
  return (await response.json()) as ValidationResult;
}

export async function exportOntology(ontology: OntoNovaSchema, format: ExportFormat): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/api/ontologies/export`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ontology, format }),
  });

  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new Error(body.detail ?? `Export failed with status ${response.status}`);
  }

  const blob = await response.blob();
  const filename = format === "turtle" ? "ontology.ttl" : "ontology.rdf";

  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}
