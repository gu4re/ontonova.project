import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { expect, test } from "@playwright/test";

// FULL-STACK end-to-end: no route stubs. Attaches a real ~193 KB PDF, lets
// the real browser pdf.js extract its text, and drives the live backend +
// vLLM pipeline, capturing the graph the app actually rendered. Run only
// when the whole stack is up (`docker compose up`) and pointed at it:
//   E2E_BASE_URL=http://localhost:5173 npx playwright test okapi-pdf.spec.ts
//
// The captured graph is written to OKAPI_CAPTURE_OUT for the Python scorer
// (backend/api/acceptance-tests/scrum-4) to grade against the gold standard.
const CAPTURE_OUT = process.env.OKAPI_CAPTURE_OUT ?? "e2e/okapi-captured-graph.json";
const LIVE = process.env.OKAPI_LIVE === "1";

test.describe("okapi PDF full-stack generation", () => {
  test.skip(!LIVE, "set OKAPI_LIVE=1 with the full docker stack running");
  // vLLM generation (4 sequential stages, possible retries) is minutes-scale.
  test.setTimeout(360_000);

  test("attaching the okapi PDF produces a graph from its extracted text", async ({ page }) => {
    // Tee the /generate SSE stream in-page: branch A is handed back to the
    // app untouched, branch B is drained here so we capture exactly the
    // frames the running app received — no stubbing, no second request.
    await page.addInitScript(() => {
      const w = window as unknown as { __sseText: string; __sseDone: boolean };
      w.__sseText = "";
      w.__sseDone = false;
      const originalFetch = window.fetch;
      window.fetch = async (...args: Parameters<typeof fetch>) => {
        const response = await originalFetch(...args);
        const url = typeof args[0] === "string" ? args[0] : (args[0] as Request).url;
        if (url && url.includes("/api/ontologies/generate") && response.body) {
          const [appBranch, captureBranch] = response.body.tee();
          void (async () => {
            const reader = captureBranch.getReader();
            const decoder = new TextDecoder();
            for (;;) {
              const { value, done } = await reader.read();
              if (done) break;
              w.__sseText += decoder.decode(value, { stream: true });
            }
            w.__sseDone = true;
          })();
          return new Response(appBranch, {
            headers: response.headers,
            status: response.status,
            statusText: response.statusText,
          });
        }
        return response;
      };
    });

    await page.goto("/");
    await page.getByLabel("Attach a text file").setInputFiles("e2e/fixtures/okapi.pdf");

    // pdf.js extraction happened in-browser: the chip proves the file was
    // accepted (empty/broken extraction would have raised an error instead).
    await expect(page.getByText("okapi.pdf")).toBeVisible();
    await page.getByRole("button", { name: "Generate ontology" }).click();

    // Wait for the whole pipeline to finish streaming.
    await page.waitForFunction(() => (window as unknown as { __sseDone: boolean }).__sseDone, null, {
      timeout: 330_000,
    });

    const sseText = await page.evaluate(() => (window as unknown as { __sseText: string }).__sseText);
    const frames = sseText
      .split("\n\n")
      .map((frame) => frame.trim())
      .filter((frame) => frame.startsWith("data:"))
      .map((frame) => JSON.parse(frame.slice("data:".length).trim()));

    const done = frames.find((frame) => frame.stage === "done");
    expect(done, "stream ended without a terminal 'done' frame").toBeTruthy();
    expect(done.status, `generation failed: ${done.error ?? ""}`).toBe("success");

    const payload = done.payload;
    const outPath = CAPTURE_OUT;
    if (!existsSync(dirname(outPath))) mkdirSync(dirname(outPath), { recursive: true });
    writeFileSync(
      outPath,
      JSON.stringify(
        {
          payload,
          retries: frames.filter((frame) => frame.status === "retrying").length,
        },
        null,
        2,
      ),
    );

    // The app rendered the graph: at least one class node is on the canvas.
    expect(payload.classes.length).toBeGreaterThan(0);
    const firstClassName: string = payload.classes[0].name;
    await expect(page.getByText(firstClassName, { exact: true }).first()).toBeVisible();
  });

  test("an over-length PDF is rejected at attach time with a clear error", async ({ page }) => {
    // Regression: this 69-page PDF (~98k chars ≈ 30k tokens vs a 16k context
    // window) used to leave the UI spinning on the first stage forever. The
    // extracted text now fails the 15,000-char bound (REQ-US-FC-01/FC-10)
    // the moment it's attached — before any backend call. The backend keeps
    // its own pre-flight for direct API clients (covered by unit tests).
    await page.goto("/");
    await page
      .getByLabel("Attach a text file")
      .setInputFiles("e2e/fixtures/revolucion_francesa.pdf");

    const alert = page.getByRole("alert");
    await expect(alert).toBeVisible({ timeout: 15_000 });
    await expect(alert).toContainText(/15,000/);
    // The file was not attached and generation never became available.
    await expect(page.getByText("revolucion_francesa.pdf")).toHaveCount(0);
    await expect(page.getByRole("button", { name: "Generate ontology" })).toBeDisabled();
  });
});
