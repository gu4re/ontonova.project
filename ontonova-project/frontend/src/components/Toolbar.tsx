import { useState, type FormEvent } from "react";
import * as Dialog from "@radix-ui/react-dialog";
import { FileCode2, Plus, Trash2 } from "lucide-react";
import { useTranslation } from "react-i18next";
import { exportOntology } from "../api/client";
import { useOntologyStore } from "../store/ontologyStore";
import type { ExportFormat } from "../types/ontology";
import { slugify, uniqueId } from "../utils/slug";
import { DropdownContent, DropdownItem, DropdownMenu, DropdownTrigger } from "./ui/DropdownMenu";
import { Tooltip } from "./ui/Tooltip";

export function Toolbar() {
  const { t } = useTranslation();
  const classes = useOntologyStore((state) => state.classes);
  const addClass = useOntologyStore((state) => state.addClass);
  const reset = useOntologyStore((state) => state.reset);
  const toSchema = useOntologyStore((state) => state.toSchema);

  const [newClassName, setNewClassName] = useState("");
  const [exportError, setExportError] = useState<string | null>(null);
  const isEmpty = classes.length === 0;

  const handleAddClass = (event: FormEvent) => {
    event.preventDefault();
    const trimmed = newClassName.trim();
    if (!trimmed) return;
    // Read fresh state rather than the `classes` closed over at the last
    // render: two submits in the same tick (e.g. a fast double-click) would
    // otherwise both compute the same "unique" id from the same stale list.
    const id = uniqueId(
      useOntologyStore.getState().classes.map((cls) => cls.id),
      slugify(trimmed, "Class_"),
    );
    addClass({ id, name: trimmed });
    setNewClassName("");
  };

  const handleExport = async (format: ExportFormat) => {
    setExportError(null);
    try {
      await exportOntology(toSchema(), format);
    } catch (error) {
      setExportError(error instanceof Error ? error.message : "Export failed");
    }
  };

  return (
    <div className="flex items-center gap-3">
      <form onSubmit={handleAddClass} className="flex items-center gap-1.5">
        <input
          type="text"
          placeholder={t("toolbar.newClassPlaceholder")}
          value={newClassName}
          onChange={(event) => setNewClassName(event.target.value)}
          className="w-40 rounded-lg border border-border bg-surface-raised px-3 py-1.5 text-sm text-text placeholder:text-text-dim outline-none focus-visible:border-accent focus-visible:ring-2 focus-visible:ring-accent/40"
        />
        <Tooltip label={t("toolbar.addClass")}>
          <button
            type="submit"
            aria-label={t("toolbar.addClass")}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-border bg-surface-raised text-text-muted transition hover:border-accent hover:text-accent"
          >
            <Plus className="h-4 w-4" />
          </button>
        </Tooltip>
      </form>

      <div className="h-6 w-px bg-border" />

      <DropdownMenu>
        <DropdownTrigger disabled={isEmpty}>{t("toolbar.exportAs")}</DropdownTrigger>
        <DropdownContent>
          <DropdownItem onSelect={() => void handleExport("turtle")}>
            <FileCode2 className="h-4 w-4" /> {t("toolbar.exportTurtle")}
          </DropdownItem>
          <DropdownItem onSelect={() => void handleExport("rdf-xml")}>
            <FileCode2 className="h-4 w-4" /> {t("toolbar.exportRdfXml")}
          </DropdownItem>
        </DropdownContent>
      </DropdownMenu>

      <Dialog.Root>
        <Dialog.Trigger asChild>
          <button
            type="button"
            disabled={isEmpty}
            className="flex items-center gap-1.5 rounded-lg border border-danger/30 bg-danger-soft px-3 py-1.5 text-sm text-danger transition hover:border-danger disabled:pointer-events-none disabled:opacity-40"
          >
            <Trash2 className="h-4 w-4" /> {t("toolbar.reset")}
          </button>
        </Dialog.Trigger>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm" />
          <Dialog.Content className="fixed top-1/2 left-1/2 z-50 w-80 -translate-x-1/2 -translate-y-1/2 rounded-xl border border-border bg-surface-raised p-5 shadow-2xl">
            <Dialog.Title className="text-sm font-semibold text-text">
              {t("toolbar.resetConfirmTitle")}
            </Dialog.Title>
            <Dialog.Description className="mt-1 text-sm text-text-muted">
              {t("toolbar.resetConfirmBody")}
            </Dialog.Description>
            <div className="mt-4 flex justify-end gap-2">
              <Dialog.Close asChild>
                <button
                  type="button"
                  className="rounded-lg border border-border px-3 py-1.5 text-sm text-text-muted transition hover:text-text"
                >
                  {t("toolbar.cancel")}
                </button>
              </Dialog.Close>
              <Dialog.Close asChild>
                <button
                  type="button"
                  onClick={() => reset()}
                  className="rounded-lg bg-danger px-3 py-1.5 text-sm font-medium text-white transition hover:brightness-110"
                >
                  {t("toolbar.discard")}
                </button>
              </Dialog.Close>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      {exportError && (
        <p role="alert" className="text-xs text-danger">
          {exportError}
        </p>
      )}
    </div>
  );
}
