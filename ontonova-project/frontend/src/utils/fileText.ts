// Reading domain text out of an attached file (REQ-US-FC-10): plain text is
// read as-is; PDFs go through pdf.js text extraction.

const TEXT_FILE_MIME_TYPES = ["text/plain", "text/markdown"];
const TEXT_FILE_EXTENSIONS = [".txt", ".md"];

export function isPlainTextFile(file: File): boolean {
  // Browsers leave `type` empty for unrecognized files, so the extension
  // check is a fallback, not redundancy.
  if (TEXT_FILE_MIME_TYPES.includes(file.type)) return true;
  const name = file.name.toLowerCase();
  return TEXT_FILE_EXTENSIONS.some((extension) => name.endsWith(extension));
}

export function isPdfFile(file: File): boolean {
  return file.type === "application/pdf" || file.name.toLowerCase().endsWith(".pdf");
}

export function isSupportedDomainFile(file: File): boolean {
  return isPlainTextFile(file) || isPdfFile(file);
}

/** Thrown when a supported file yields no usable text (e.g. a scanned PDF). */
export class EmptyFileTextError extends Error {
  constructor() {
    super("No text could be extracted from the file");
    this.name = "EmptyFileTextError";
  }
}

export async function readDomainFile(file: File): Promise<string> {
  const content = isPdfFile(file) ? await extractPdfText(file) : (await file.text()).trim();
  if (!content) throw new EmptyFileTextError();
  return content;
}

async function extractPdfText(file: File): Promise<string> {
  // Dynamic import keeps pdf.js (~1 MB) out of the main bundle for users who
  // never attach a PDF.
  const pdfjs = await import("pdfjs-dist");
  pdfjs.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url,
  ).toString();

  const loadingTask = pdfjs.getDocument({ data: await file.arrayBuffer() });
  try {
    const document = await loadingTask.promise;
    const pages: string[] = [];
    for (let pageNumber = 1; pageNumber <= document.numPages; pageNumber++) {
      const page = await document.getPage(pageNumber);
      const content = await page.getTextContent();
      pages.push(
        content.items
          .map((item) => ("str" in item ? item.str : ""))
          .join(" ")
          .trim(),
      );
    }
    return pages.join("\n\n").trim();
  } finally {
    await loadingTask.destroy();
  }
}
