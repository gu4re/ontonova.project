import { expect, test } from "@playwright/test";

// These specs exercise the edit/delete/export use cases purely client-side
// (no backend required) by driving the real Chromium-rendered canvas —
// jsdom-based component tests can't validate React Flow's actual pointer
// interactions or the native <dialog> confirm flow.

test.beforeEach(async ({ page }) => {
  await page.goto("/");
});

test("adding a class renders it as a node on the canvas", async ({ page }) => {
  await page.getByPlaceholder("New class name…").fill("Teacher");
  await page.getByRole("button", { name: "Add class" }).click();

  await expect(page.getByText("Teacher", { exact: true })).toBeVisible();
  await expect(page.getByRole("button", { name: "Reset" })).toBeEnabled();
});

test("selecting a class shows it in the inspector panel", async ({ page }) => {
  await page.getByPlaceholder("New class name…").fill("Student");
  await page.getByRole("button", { name: "Add class" }).click();

  await page.getByText("Student", { exact: true }).click();

  await expect(page.getByRole("heading", { name: "Student" })).toBeVisible();
});

test("deleting a class removes it from the canvas", async ({ page }) => {
  await page.getByPlaceholder("New class name…").fill("Course");
  await page.getByRole("button", { name: "Add class" }).click();
  await expect(page.getByText("Course", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Delete class Course" }).click();

  await expect(page.getByText("Course", { exact: true })).toHaveCount(0);
  await expect(page.getByRole("button", { name: "Reset" })).toBeDisabled();
});

test("reset only discards the ontology after confirming", async ({ page }) => {
  await page.getByPlaceholder("New class name…").fill("Person");
  await page.getByRole("button", { name: "Add class" }).click();

  await page.getByRole("button", { name: "Reset" }).click();
  await expect(page.getByText("Discard the current ontology?")).toBeVisible();
  await page.getByRole("button", { name: "Cancel" }).click();
  await expect(page.getByText("Person", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Reset" }).click();
  await page.getByRole("button", { name: "Discard" }).click();
  await expect(page.getByText("Person", { exact: true })).toHaveCount(0);
});

test("exporting a class triggers a Turtle file download", async ({ page }) => {
  // Stub the backend call so this spec doesn't depend on the API being up —
  // it's verifying the frontend's download-triggering behavior in a real
  // browser, not the backend's RDF compilation (covered by backend tests).
  await page.route("**/api/ontologies/export", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "text/turtle",
      headers: { "content-disposition": "attachment; filename=ontology.ttl" },
      body: "@prefix onto: <http://ontonova.local/ontology#> .\n",
    });
  });

  await page.getByPlaceholder("New class name…").fill("Book");
  await page.getByRole("button", { name: "Add class" }).click();

  await page.getByRole("button", { name: "Export" }).click();
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("menuitem", { name: "Turtle" }).click();
  const download = await downloadPromise;

  expect(download.suggestedFilename()).toBe("ontology.ttl");
});

test("relation labels can be dragged to a new position on the canvas", async ({ page }) => {
  // Load a graph with a subClassOf edge through the (stubbed) generation
  // flow — edges can't be created from the toolbar alone.
  const payload = {
    classes: [
      { id: "Person", name: "Person", subClassOf: null },
      { id: "Professor", name: "Professor", subClassOf: "Person" },
    ],
    object_properties: [],
    data_properties: [],
    individuals: [],
  };
  await page.route("**/api/ontologies/generate", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "text/event-stream",
      body: `data: ${JSON.stringify({ stage: "done", status: "success", payload })}\n\n`,
    });
  });
  await page.getByLabel("Describe the domain").fill("professors are persons");
  await page.getByRole("button", { name: "Generate ontology" }).click();

  const label = page.getByText("subClassOf", { exact: true });
  await expect(label).toBeVisible();
  const before = (await label.boundingBox())!;

  await label.hover();
  await page.mouse.down();
  await page.mouse.move(before.x + before.width / 2 + 120, before.y + before.height / 2 + 80, {
    steps: 5,
  });
  await page.mouse.up();

  const after = (await label.boundingBox())!;
  expect(after.x - before.x).toBeGreaterThan(100);
  expect(after.y - before.y).toBeGreaterThan(60);

  // The label is still functional after the move: its delete control works.
  await page.getByRole("button", { name: "Delete relation subClassOf" }).click();
  await expect(page.getByText("subClassOf", { exact: true })).toHaveCount(0);
});

test("visual smoke check — empty state and populated canvas", async ({ page }) => {
  await page.screenshot({ path: "e2e/screenshots/empty-state.png" });

  await page.getByPlaceholder("New class name…").fill("Person");
  await page.getByRole("button", { name: "Add class" }).click();
  await page.getByPlaceholder("New class name…").fill("Organization");
  await page.getByRole("button", { name: "Add class" }).click();
  await page.getByText("Person", { exact: true }).click();

  await page.screenshot({ path: "e2e/screenshots/populated-canvas.png" });
});
