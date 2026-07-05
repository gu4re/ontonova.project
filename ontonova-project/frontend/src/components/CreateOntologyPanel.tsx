import { useEffect, useMemo, useRef, useState, type ChangeEvent, type FormEvent } from "react";
import clsx from "clsx";
import { AnimatePresence, motion } from "framer-motion";
import { FileText, ListTree, Loader2, Paperclip, Share2, ShieldCheck, Sparkles, Users, X, type LucideIcon } from "lucide-react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { generateOntology } from "../api/client";
import { useOntologyStore } from "../store/ontologyStore";
import type { GenerationEvent } from "../types/ontology";
import { EmptyFileTextError, isSupportedDomainFile, readDomainFile } from "../utils/fileText";
import { localizedLanguageNames } from "../utils/languageNames";
import { DropdownContent, DropdownItem, DropdownMenu, DropdownTrigger } from "./ui/DropdownMenu";
import { FlagIcon } from "./ui/FlagIcon";

const STAGE_ICONS: Record<string, LucideIcon> = {
  taxonomist: ListTree,
  relational: Share2,
  populator: Users,
  validator: ShieldCheck,
};

// A hint list, not an allowlist — REQ-US-FC-01 requires the domain text to
// accept any language, so the field itself stays free text.
const LANGUAGE_SUGGESTION_CODES = ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ar"];

// REQ-US-FC-01: typed domain text is bounded at 15,000 characters — the
// same semantic limit the backend enforces for file-extracted text
// (REQ-US-FC-10), so both entry paths share one documented bound.
export const MAX_TEXT_LENGTH = 15_000;

// REQ-US-FC-10: a text file (plain text or PDF) of up to 5 MB can be
// attached as the domain text instead of typing it.
export const MAX_FILE_BYTES = 5 * 1024 * 1024;

interface AttachedFile {
  name: string;
  size: number;
  content: string;
}

function formatFileSize(bytes: number): string {
  if (bytes >= 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  if (bytes >= 1024) return `${Math.round(bytes / 1024)} KB`;
  return `${bytes} B`;
}

function useLanguageSuggestions(uiLanguage: string) {
  return useMemo(() => {
    const labels = localizedLanguageNames(LANGUAGE_SUGGESTION_CODES, uiLanguage);
    return LANGUAGE_SUGGESTION_CODES.map((code, index) => ({ code, label: labels[index] }));
  }, [uiLanguage]);
}

function stageStatus(events: GenerationEvent[], stageKey: string): "pending" | "active" | "done" | "error" {
  const stageEvents = events.filter((event) => event.stage === stageKey);
  if (stageEvents.length === 0) return "pending";
  const last = stageEvents[stageEvents.length - 1];
  if (last.status === "failed") return "error";
  if (last.status === "completed" || last.status === "success") return "done";
  return "active";
}

export function CreateOntologyPanel() {
  const { t, i18n } = useTranslation();
  const loadFromGeneration = useOntologyStore((state) => state.loadFromGeneration);
  const hasOntology = useOntologyStore((state) => state.classes.length > 0);
  const languageSuggestions = useLanguageSuggestions(i18n.language);

  const STAGES: { key: GenerationEvent["stage"]; label: string }[] = [
    { key: "taxonomist", label: t("create.stageClasses") },
    { key: "relational", label: t("create.stageRelations") },
    { key: "populator", label: t("create.stageIndividuals") },
    { key: "validator", label: t("create.stageValidation") },
  ];

  const [text, setText] = useState("");
  const [language, setLanguage] = useState("");
  const [attachedFile, setAttachedFile] = useState<AttachedFile | null>(null);
  const [fileError, setFileError] = useState<string | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [events, setEvents] = useState<GenerationEvent[]>([]);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const controllerRef = useRef<AbortController | null>(null);
  // React state updates aren't synchronous, so a double-click/double-Enter
  // between two handleSubmit calls could both read isGenerating === false
  // before the first commit lands. This ref is set immediately, in the same
  // tick as the guard check, closing that race.
  const isGeneratingRef = useRef(false);

  useEffect(() => () => controllerRef.current?.abort(), []);

  const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    // Reset so removing and re-attaching the same file still fires a change event.
    event.target.value = "";
    if (!file) return;

    if (!isSupportedDomainFile(file)) {
      setFileError(t("create.fileWrongType"));
      return;
    }
    if (file.size > MAX_FILE_BYTES) {
      setFileError(t("create.fileTooLarge"));
      return;
    }
    try {
      const content = await readDomainFile(file);
      // REQ-US-FC-10: the 5 MB bound is transport-level; the extracted text
      // must also fit the model's documented input budget (mirrors the
      // backend's MAX_INPUT_CHARS pre-flight, but fails at attach time with
      // a localized message instead of after submitting).
      if (content.length > MAX_TEXT_LENGTH) {
        setFileError(
          t("create.fileTextTooLong", {
            count: content.length.toLocaleString(i18n.language),
            max: MAX_TEXT_LENGTH.toLocaleString(i18n.language),
          }),
        );
        return;
      }
      setFileError(null);
      setAttachedFile({ name: file.name, size: file.size, content });
    } catch (readError) {
      setFileError(
        readError instanceof EmptyFileTextError ? t("create.fileNoText") : t("create.fileUnreadable"),
      );
    }
  };

  const removeAttachedFile = () => {
    setAttachedFile(null);
    setFileError(null);
  };

  // REQ-US-FC-10: an attached file replaces the typed text as the domain input.
  const domainText = attachedFile ? attachedFile.content : text;

  // Backend failure frames carry a machine-readable `code` precisely so the
  // message can be rendered in the UI language — the raw `error` string is
  // an English fallback (kept as technical detail for LLM-side failures).
  const describeGenerationError = (generationEvent: GenerationEvent): string => {
    if (generationEvent.code === "input_too_long" && generationEvent.params) {
      return t("create.fileTextTooLong", {
        count: Number(generationEvent.params.count).toLocaleString(i18n.language),
        max: Number(generationEvent.params.max).toLocaleString(i18n.language),
      });
    }
    if (generationEvent.code === "llm_error") {
      return generationEvent.error
        ? `${t("create.llmError")}: ${generationEvent.error}`
        : t("create.llmError");
    }
    return generationEvent.error ?? t("create.genericFailure");
  };

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    if (!domainText.trim() || isGeneratingRef.current) return;
    isGeneratingRef.current = true;

    // Guard against a stream somehow still being open (e.g. "Regenerate").
    controllerRef.current?.abort();
    setEvents([]);
    setError(null);
    setIsGenerating(true);

    controllerRef.current = generateOntology(
      domainText,
      language.trim(),
      (generationEvent) => {
        setEvents((prev) => [...prev, generationEvent]);
        if (generationEvent.stage === "done") {
          isGeneratingRef.current = false;
          setIsGenerating(false);
          if (generationEvent.status === "success" && generationEvent.payload) {
            loadFromGeneration(generationEvent.payload);
          } else {
            const message = describeGenerationError(generationEvent);
            setError(message);
            toast.error(message);
          }
        }
      },
      (message) => {
        isGeneratingRef.current = false;
        setIsGenerating(false);
        setError(message);
        toast.error(message);
      },
    );
  };

  // Must reflect the *current* state, not "did this ever retry" — events
  // only ever grows within a run, so a naive `.some(retrying)` would stay
  // true forever after the first retry even once validation later succeeds.
  const isRetrying = events[events.length - 1]?.status === "retrying";

  return (
    <div className="flex flex-col gap-5">
      <form onSubmit={handleSubmit} className="flex flex-col gap-3">
        <label htmlFor="ontology-text" className="text-sm font-semibold text-text">
          {t("create.domainLabel")}
        </label>
        <textarea
          id="ontology-text"
          placeholder={attachedFile ? t("create.domainFromFile") : t("create.domainPlaceholder")}
          value={attachedFile ? "" : text}
          onChange={(event) => setText(event.target.value)}
          rows={6}
          maxLength={MAX_TEXT_LENGTH}
          disabled={isGenerating || attachedFile !== null}
          className="w-full resize-y rounded-xl border border-border bg-surface-raised p-3 text-sm text-text placeholder:text-text-dim outline-none transition focus-visible:border-accent focus-visible:ring-2 focus-visible:ring-accent/40 disabled:opacity-60"
        />

        <div className="flex flex-col gap-1.5">
          <input
            ref={fileInputRef}
            type="file"
            accept=".txt,.md,.pdf,text/plain,text/markdown,application/pdf"
            onChange={(event) => void handleFileChange(event)}
            disabled={isGenerating}
            className="sr-only"
            aria-label={t("create.attachFile")}
          />
          {attachedFile ? (
            <div className="flex items-center gap-2 rounded-lg border border-border bg-surface-raised px-3 py-1.5 text-sm text-text">
              <FileText className="h-4 w-4 shrink-0 text-accent" aria-hidden="true" />
              <span className="min-w-0 truncate">{attachedFile.name}</span>
              <span className="shrink-0 text-xs text-text-dim">{formatFileSize(attachedFile.size)}</span>
              <button
                type="button"
                onClick={removeAttachedFile}
                disabled={isGenerating}
                aria-label={t("create.removeFile")}
                className="ml-auto flex h-6 w-6 shrink-0 items-center justify-center rounded-md text-text-muted transition hover:bg-danger-soft hover:text-danger"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              disabled={isGenerating}
              className="flex items-center gap-1.5 self-start rounded-lg border border-border bg-surface-raised px-3 py-1.5 text-xs font-medium text-text-muted transition hover:border-accent hover:text-accent disabled:opacity-60"
            >
              <Paperclip className="h-3.5 w-3.5" aria-hidden="true" />
              {t("create.attachFile")} <span className="text-text-dim">{t("create.attachHint")}</span>
            </button>
          )}
          {fileError && (
            <p role="alert" className="animate-fade-in text-xs text-danger">
              {fileError}
            </p>
          )}
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor="ontology-language" className="text-xs font-medium text-text-muted">
            {t("create.languageLabel")} <span className="text-text-dim">{t("create.languageHint")}</span>
          </label>
          <div className="flex items-center gap-1.5">
            <input
              id="ontology-language"
              type="text"
              placeholder={t("create.languagePlaceholder")}
              value={language}
              onChange={(event) => setLanguage(event.target.value)}
              disabled={isGenerating}
              className="w-full min-w-0 rounded-lg border border-border bg-surface-raised px-3 py-1.5 text-sm text-text placeholder:text-text-dim outline-none focus-visible:border-accent focus-visible:ring-2 focus-visible:ring-accent/40 disabled:opacity-60"
            />
            <DropdownMenu>
              <DropdownTrigger variant="icon" disabled={isGenerating} aria-label={t("create.languageLabel")}>
                <span className="sr-only">{t("create.languageLabel")}</span>
              </DropdownTrigger>
              <DropdownContent align="end">
                {languageSuggestions.map(({ code, label }) => (
                  <DropdownItem key={code} onSelect={() => setLanguage(label)}>
                    <FlagIcon code={code} />
                    {label}
                  </DropdownItem>
                ))}
              </DropdownContent>
            </DropdownMenu>
          </div>
        </div>

        <button
          type="submit"
          disabled={isGenerating || !domainText.trim()}
          className="flex w-full items-center justify-center gap-2 rounded-lg bg-linear-to-r from-accent-from to-accent-to px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-accent-from/20 transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:brightness-100"
        >
          {isGenerating ? <Loader2 className="h-4 w-4 animate-spin" /> : <Sparkles className="h-4 w-4" />}
          {isGenerating ? t("create.submitBusy") : hasOntology ? t("create.submitRegenerate") : t("create.submitIdle")}
        </button>
      </form>

      <AnimatePresence>
        {(isGenerating || events.length > 0) && (
          <motion.ol
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            aria-label={t("create.progressLabel")}
            className="flex flex-col gap-1 overflow-hidden"
          >
            {STAGES.map((stage) => {
              const status = stageStatus(events, stage.key);
              const Icon = STAGE_ICONS[stage.key];
              return (
                <li
                  key={stage.key}
                  className={clsx(
                    "flex items-center gap-2 rounded-lg px-2.5 py-1.5 text-sm transition-colors",
                    status === "pending" && "text-text-dim",
                    status === "active" && "animate-pulse-glow bg-accent-soft text-accent",
                    status === "done" && "text-success",
                    status === "error" && "text-danger",
                  )}
                >
                  <Icon className="h-4 w-4 shrink-0" aria-hidden="true" />
                  {stage.label}
                </li>
              );
            })}
          </motion.ol>
        )}
      </AnimatePresence>

      {isRetrying && !error && (
        <p role="status" className="animate-fade-in text-xs text-warning">
          {t("create.retryingNote")}
        </p>
      )}
      {error && (
        <p role="alert" className="animate-fade-in text-xs text-danger">
          {error}
        </p>
      )}
    </div>
  );
}
