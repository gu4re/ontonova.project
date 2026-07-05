import { expect, test } from "@playwright/test";
import { PDFDocument, StandardFonts } from "pdf-lib";

// REQ-US-FC-10: the user can attach a plain-text file of up to 5 MB as the
// domain input. The generation backend is stubbed (same rationale as the
// export spec): these tests verify the real-browser file-picker flow, not
// the LLM pipeline.

const SSE_SUCCESS_BODY = [
  { stage: "taxonomist", status: "completed" },
  { stage: "relational", status: "completed" },
  { stage: "populator", status: "completed" },
  { stage: "validator", status: "completed" },
  {
    stage: "done",
    status: "success",
    payload: {
      classes: [{ id: "Class_Profesor", name: "Profesor", subClassOf: null }],
      object_properties: [],
      data_properties: [],
      individuals: [],
    },
  },
]
  .map((event) => `data: ${JSON.stringify(event)}\n\n`)
  .join("");

test.beforeEach(async ({ page }) => {
  await page.goto("/");
});

test("attaching a text file generates an ontology from its content", async ({ page }) => {
  await page.route("**/api/ontologies/generate", async (route) => {
    const body = route.request().postDataJSON() as { text: string };
    expect(body.text).toContain("profesores imparten cursos");
    await route.fulfill({
      status: 200,
      contentType: "text/event-stream",
      body: SSE_SUCCESS_BODY,
    });
  });

  await page.getByLabel("Attach a text file").setInputFiles({
    name: "dominio.txt",
    mimeType: "text/plain",
    buffer: Buffer.from("Universidad: profesores imparten cursos a estudiantes."),
  });

  await expect(page.getByText("dominio.txt")).toBeVisible();
  await page.getByRole("button", { name: "Generate ontology" }).click();

  await expect(page.getByText("Profesor", { exact: true })).toBeVisible();
});

test("a file over 5 MB is rejected with an error message", async ({ page }) => {
  await page.getByLabel("Attach a text file").setInputFiles({
    name: "huge.txt",
    mimeType: "text/plain",
    buffer: Buffer.alloc(5 * 1024 * 1024 + 1, "a"),
  });

  await expect(page.getByRole("alert")).toHaveText(/exceeds the 5 MB limit/);
  await expect(page.getByText("huge.txt")).toHaveCount(0);
  await expect(page.getByRole("button", { name: "Generate ontology" })).toBeDisabled();
});

test("attaching a PDF extracts its text and generates from it", async ({ page }) => {
  // A real PDF built at runtime — this exercises the actual pdf.js
  // extraction (including its web worker) in Chromium, unlike the
  // mocked-pdfjs component tests.
  const pdf = await PDFDocument.create();
  const font = await pdf.embedFont(StandardFonts.Helvetica);
  pdf.addPage().drawText("University professors teach courses to students.", {
    x: 50,
    y: 700,
    size: 12,
    font,
  });
  const pdfBytes = await pdf.save();

  await page.route("**/api/ontologies/generate", async (route) => {
    const body = route.request().postDataJSON() as { text: string };
    expect(body.text).toContain("professors teach courses");
    await route.fulfill({
      status: 200,
      contentType: "text/event-stream",
      body: SSE_SUCCESS_BODY,
    });
  });

  await page.getByLabel("Attach a text file").setInputFiles({
    name: "domain.pdf",
    mimeType: "application/pdf",
    buffer: Buffer.from(pdfBytes),
  });

  await expect(page.getByText("domain.pdf")).toBeVisible();
  await page.getByRole("button", { name: "Generate ontology" }).click();

  await expect(page.getByText("Profesor", { exact: true })).toBeVisible();
});

test("a file at exactly the 5 MB boundary passes the size check", async ({ page }) => {
  await page.getByLabel("Attach a text file").setInputFiles({
    name: "boundary.txt",
    mimeType: "text/plain",
    buffer: Buffer.alloc(5 * 1024 * 1024, "a"),
  });

  // Exactly 5 MB is within the transport bound (REQ-US-FC-10), so the size
  // rule does NOT fire — the rejection this file does get is the separate
  // 15,000-character extracted-text rule, proving the two limits are
  // enforced independently at their own boundaries.
  const alert = page.getByRole("alert");
  await expect(alert).toBeVisible();
  await expect(alert).toContainText(/15,000/);
  await expect(alert).not.toContainText(/5 MB limit/);
});
