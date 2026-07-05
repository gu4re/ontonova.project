import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import * as apiClient from "../api/client";
import i18n from "../i18n";
import { useOntologyStore } from "../store/ontologyStore";
import { render, screen, waitFor } from "../test/render";
import type { GenerationEvent } from "../types/ontology";
import { CreateOntologyPanel, MAX_FILE_BYTES } from "./CreateOntologyPanel";

beforeEach(() => {
  useOntologyStore.getState().reset();
  vi.restoreAllMocks();
});

afterEach(async () => {
  await i18n.changeLanguage("en");
});

describe("CreateOntologyPanel", () => {
  it("disables submit until domain text is entered", async () => {
    render(<CreateOntologyPanel />);
    expect(screen.getByRole("button", { name: "Generate ontology" })).toBeDisabled();

    const user = userEvent.setup();
    await user.type(screen.getByLabelText("Describe the domain"), "university roles");
    expect(screen.getByRole("button", { name: "Generate ontology" })).toBeEnabled();
  });

  it("accepts free-text language input and forwards it trimmed", async () => {
    const generateSpy = vi
      .spyOn(apiClient, "generateOntology")
      .mockImplementation(() => new AbortController());
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    await user.type(screen.getByLabelText("Describe the domain"), "university roles");
    // getByLabelText(/Language/i) would also match the suggestions dropdown's
    // "Language" aria-label button — scope to the textbox role to disambiguate.
    await user.type(screen.getByRole("textbox", { name: /Language/i }), "  Français  ");
    await user.click(screen.getByRole("button", { name: "Generate ontology" }));

    expect(generateSpy).toHaveBeenCalledWith(
      "university roles",
      "Français",
      expect.any(Function),
      expect.any(Function),
    );
  });

  it("fills the language field from the suggestions menu without losing free-text entry", async () => {
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    const languageInput = screen.getByRole("textbox", { name: /Language/i });
    await user.click(screen.getByRole("button", { name: "Language" }));
    // Suggestions are localized to the current UI language (English in tests),
    // so the menu item reads "French" rather than the endonym "Français".
    await user.click(await screen.findByRole("menuitem", { name: "French" }));
    expect(languageInput).toHaveValue("French");

    // Still editable as free text afterwards — not locked to the suggestion list.
    await user.clear(languageInput);
    await user.type(languageInput, "Klingon");
    expect(languageInput).toHaveValue("Klingon");
  });

  it("re-localizes the suggestions menu when the interface language changes", async () => {
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    await i18n.changeLanguage("es");
    await user.click(screen.getByRole("button", { name: "Idioma" }));
    expect(await screen.findByRole("menuitem", { name: "Francés" })).toBeInTheDocument();
  });

  it("walks the stage stepper and loads the ontology into the store on success", async () => {
    let emit: (event: GenerationEvent) => void = () => {};
    vi.spyOn(apiClient, "generateOntology").mockImplementation((_text, _language, onEvent) => {
      emit = onEvent;
      return new AbortController();
    });

    const user = userEvent.setup();
    render(<CreateOntologyPanel />);
    await user.type(screen.getByLabelText("Describe the domain"), "university roles");
    await user.click(screen.getByRole("button", { name: "Generate ontology" }));

    emit({ stage: "taxonomist", status: "completed" });
    await waitFor(() => expect(screen.getByText("Classes")).toHaveClass("text-success"));

    const payload = {
      classes: [{ id: "Class_Person", name: "Person", subClassOf: null }],
      object_properties: [],
      data_properties: [],
      individuals: [],
    };
    emit({ stage: "done", status: "success", payload });

    await waitFor(() => expect(useOntologyStore.getState().classes).toEqual(payload.classes));
  });

  it("clears the retrying note once self-healing succeeds, instead of leaving it stuck forever", async () => {
    let emit: (event: GenerationEvent) => void = () => {};
    vi.spyOn(apiClient, "generateOntology").mockImplementation((_text, _language, onEvent) => {
      emit = onEvent;
      return new AbortController();
    });

    const user = userEvent.setup();
    render(<CreateOntologyPanel />);
    await user.type(screen.getByLabelText("Describe the domain"), "university roles");
    await user.click(screen.getByRole("button", { name: "Generate ontology" }));

    emit({ stage: "taxonomist", status: "completed" });
    emit({ stage: "relational", status: "completed" });
    emit({ stage: "populator", status: "completed" });
    emit({ stage: "validator", status: "retrying", error: "dangling reference" });
    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent(/retrying/i));

    // Self-healing recovers: the retried stages complete and validation passes.
    emit({ stage: "relational", status: "completed" });
    emit({ stage: "populator", status: "completed" });
    emit({ stage: "validator", status: "completed" });

    await waitFor(() => expect(screen.queryByRole("status")).not.toBeInTheDocument());
  });

  it("localizes coded backend failures into the UI language", async () => {
    // Regression: the backend's input_too_long failure rendered its raw
    // English text even in a Spanish UI. Coded frames must be translated.
    let emit: (event: GenerationEvent) => void = () => {};
    vi.spyOn(apiClient, "generateOntology").mockImplementation((_text, _language, onEvent) => {
      emit = onEvent;
      return new AbortController();
    });

    const user = userEvent.setup();
    render(<CreateOntologyPanel />);
    await i18n.changeLanguage("es");
    await user.type(screen.getByLabelText("Describe el dominio"), "un texto cualquiera");
    await user.click(screen.getByRole("button", { name: "Generar ontología" }));

    emit({
      stage: "done",
      status: "failed",
      error: "The document is too long for the model's context window: ...",
      code: "input_too_long",
      params: { count: 99_655, max: 15_000 },
    });

    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("El documento contiene");
    expect(alert).toHaveTextContent("15.000"); // Spanish number formatting
    expect(alert).not.toHaveTextContent("too long for the model");
  });

  it("surfaces a failure message and re-enables the form", async () => {
    let emit: (event: GenerationEvent) => void = () => {};
    vi.spyOn(apiClient, "generateOntology").mockImplementation((_text, _language, onEvent) => {
      emit = onEvent;
      return new AbortController();
    });

    const user = userEvent.setup();
    render(<CreateOntologyPanel />);
    await user.type(screen.getByLabelText("Describe the domain"), "university roles");
    await user.click(screen.getByRole("button", { name: "Generate ontology" }));

    emit({ stage: "done", status: "failed", error: "self-healing exhausted" });

    expect(await screen.findByRole("alert")).toHaveTextContent("self-healing exhausted");
    expect(screen.getByRole("button", { name: "Generate ontology" })).toBeEnabled();
  });
});

// pdf.js runs for real only in the Playwright suite; the component test just
// needs the PDF branch of readDomainFile to resolve.
const { getDocumentMock } = vi.hoisted(() => ({ getDocumentMock: vi.fn() }));
vi.mock("pdfjs-dist", () => ({
  GlobalWorkerOptions: { workerSrc: "" },
  getDocument: getDocumentMock,
}));

// REQ-US-FC-10: a text file (plain text or PDF) of up to 5 MB can be attached
// as the domain input.
describe("CreateOntologyPanel file attachment", () => {
  it("uses the attached file's content as the generation input", async () => {
    const generateSpy = vi
      .spyOn(apiClient, "generateOntology")
      .mockImplementation(() => new AbortController());
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    const file = new File(["Universidad: profesores imparten cursos a estudiantes."], "dominio.txt", {
      type: "text/plain",
    });
    await user.upload(screen.getByLabelText("Attach a text file"), file);

    // The chip shows the attached file, and submit is enabled without typing.
    expect(await screen.findByText("dominio.txt")).toBeInTheDocument();
    const submit = screen.getByRole("button", { name: "Generate ontology" });
    expect(submit).toBeEnabled();

    await user.click(submit);
    expect(generateSpy).toHaveBeenCalledWith(
      "Universidad: profesores imparten cursos a estudiantes.",
      "",
      expect.any(Function),
      expect.any(Function),
    );
  });

  it("rejects a file over the 5 MB limit", async () => {
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    const oversized = new File(["x"], "huge.txt", { type: "text/plain" });
    // Faking `size` avoids allocating a real >5 MB payload in the test.
    Object.defineProperty(oversized, "size", { value: MAX_FILE_BYTES + 1 });
    await user.upload(screen.getByLabelText("Attach a text file"), oversized);

    expect(await screen.findByRole("alert")).toHaveTextContent("exceeds the 5 MB limit");
    expect(screen.queryByText("huge.txt")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Generate ontology" })).toBeDisabled();
  });

  it("rejects an unsupported file type", async () => {
    // applyAccept: false — the browser's file picker filter is exactly what
    // this test bypasses, so the component's own type check is exercised.
    const user = userEvent.setup({ applyAccept: false });
    render(<CreateOntologyPanel />);

    const docx = new File(["PK"], "document.docx", { type: "application/vnd.ms-word" });
    await user.upload(screen.getByLabelText("Attach a text file"), docx);

    expect(await screen.findByRole("alert")).toHaveTextContent("Only text or PDF files");
    expect(screen.queryByText("document.docx")).not.toBeInTheDocument();
  });

  it("extracts and uses the text of an attached PDF", async () => {
    getDocumentMock.mockReturnValue({
      promise: Promise.resolve({
        numPages: 1,
        getPage: () =>
          Promise.resolve({
            getTextContent: () =>
              Promise.resolve({ items: [{ str: "Contenido PDF del dominio." }] }),
          }),
      }),
      destroy: () => Promise.resolve(),
    });
    const generateSpy = vi
      .spyOn(apiClient, "generateOntology")
      .mockImplementation(() => new AbortController());
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    const pdf = new File(["%PDF-1.7"], "dominio.pdf", { type: "application/pdf" });
    await user.upload(screen.getByLabelText("Attach a text file"), pdf);

    expect(await screen.findByText("dominio.pdf")).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: "Generate ontology" }));
    expect(generateSpy).toHaveBeenCalledWith(
      "Contenido PDF del dominio.",
      "",
      expect.any(Function),
      expect.any(Function),
    );
  });

  it("reports a PDF with no extractable text instead of attaching it", async () => {
    getDocumentMock.mockReturnValue({
      promise: Promise.resolve({
        numPages: 1,
        getPage: () =>
          Promise.resolve({ getTextContent: () => Promise.resolve({ items: [] }) }),
      }),
      destroy: () => Promise.resolve(),
    });
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    const scanned = new File(["%PDF-1.7"], "scanned.pdf", { type: "application/pdf" });
    await user.upload(screen.getByLabelText("Attach a text file"), scanned);

    expect(await screen.findByRole("alert")).toHaveTextContent("No text could be extracted");
    expect(screen.queryByText("scanned.pdf")).not.toBeInTheDocument();
  });

  it("rejects a file whose extracted text exceeds the 15,000-character bound", async () => {
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    const oversizedText = new File(["x".repeat(15_001)], "tome.txt", { type: "text/plain" });
    await user.upload(screen.getByLabelText("Attach a text file"), oversizedText);

    expect(await screen.findByRole("alert")).toHaveTextContent(/15,000/);
    expect(screen.queryByText("tome.txt")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Generate ontology" })).toBeDisabled();
  });

  it("restores the typed-text flow when the attachment is removed", async () => {
    const user = userEvent.setup();
    render(<CreateOntologyPanel />);

    const file = new File(["domain text from file"], "notes.md", { type: "text/markdown" });
    await user.upload(screen.getByLabelText("Attach a text file"), file);
    expect(await screen.findByText("notes.md")).toBeInTheDocument();
    expect(screen.getByLabelText("Describe the domain")).toBeDisabled();

    await user.click(screen.getByRole("button", { name: "Remove attached file" }));

    expect(screen.queryByText("notes.md")).not.toBeInTheDocument();
    expect(screen.getByLabelText("Describe the domain")).toBeEnabled();
    expect(screen.getByRole("button", { name: "Generate ontology" })).toBeDisabled();
  });
});
