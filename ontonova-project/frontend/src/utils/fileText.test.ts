import { beforeEach, describe, expect, it, vi } from "vitest";
import { EmptyFileTextError, isSupportedDomainFile, readDomainFile } from "./fileText";

// pdf.js is exercised for real in the Playwright suite (e2e/create.spec.ts);
// here it's mocked so unit tests stay fast and jsdom-safe.
const { getDocumentMock } = vi.hoisted(() => ({ getDocumentMock: vi.fn() }));
vi.mock("pdfjs-dist", () => ({
  GlobalWorkerOptions: { workerSrc: "" },
  getDocument: getDocumentMock,
}));

function mockPdfDocument(pageTexts: string[][]) {
  getDocumentMock.mockReturnValue({
    promise: Promise.resolve({
      numPages: pageTexts.length,
      getPage: (pageNumber: number) =>
        Promise.resolve({
          getTextContent: () =>
            Promise.resolve({ items: pageTexts[pageNumber - 1].map((str) => ({ str })) }),
        }),
    }),
    destroy: () => Promise.resolve(),
  });
}

beforeEach(() => {
  getDocumentMock.mockReset();
});

describe("isSupportedDomainFile", () => {
  it("accepts plain text, markdown and PDF", () => {
    expect(isSupportedDomainFile(new File([""], "a.txt", { type: "text/plain" }))).toBe(true);
    expect(isSupportedDomainFile(new File([""], "a.md", { type: "text/markdown" }))).toBe(true);
    expect(isSupportedDomainFile(new File([""], "a.pdf", { type: "application/pdf" }))).toBe(true);
    // Extension fallback for files the browser gives no MIME type.
    expect(isSupportedDomainFile(new File([""], "a.pdf", { type: "" }))).toBe(true);
    expect(isSupportedDomainFile(new File([""], "a.docx", { type: "application/vnd.ms-word" }))).toBe(false);
  });
});

describe("readDomainFile", () => {
  it("returns trimmed plain-text content", async () => {
    const file = new File(["  domain text  \n"], "a.txt", { type: "text/plain" });
    await expect(readDomainFile(file)).resolves.toBe("domain text");
  });

  it("throws EmptyFileTextError for a whitespace-only text file", async () => {
    const file = new File(["   \n\t"], "a.txt", { type: "text/plain" });
    await expect(readDomainFile(file)).rejects.toBeInstanceOf(EmptyFileTextError);
  });

  it("joins the extracted text of every PDF page", async () => {
    mockPdfDocument([
      ["University", "professors"],
      ["teach", "courses."],
    ]);
    const file = new File(["%PDF-1.7"], "a.pdf", { type: "application/pdf" });
    await expect(readDomainFile(file)).resolves.toBe("University professors\n\nteach courses.");
  });

  it("throws EmptyFileTextError for a PDF with no extractable text", async () => {
    mockPdfDocument([[""]]);
    const file = new File(["%PDF-1.7"], "scanned.pdf", { type: "application/pdf" });
    await expect(readDomainFile(file)).rejects.toBeInstanceOf(EmptyFileTextError);
  });
});
