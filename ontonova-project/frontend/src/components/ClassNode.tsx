import { Handle, Position, type Node, type NodeProps } from "@xyflow/react";
import clsx from "clsx";
import { motion } from "framer-motion";
import { X } from "lucide-react";
import { useState } from "react";
import { useTranslation } from "react-i18next";

export interface ClassNodeData extends Record<string, unknown> {
  label: string;
  onRename: (name: string) => void;
  onDelete: () => void;
}

export type ClassNodeType = Node<ClassNodeData, "classNode">;

export function ClassNode({ data, selected }: NodeProps<ClassNodeType>) {
  const { t } = useTranslation();
  const [editing, setEditing] = useState(false);
  const [value, setValue] = useState(data.label);

  const commit = () => {
    setEditing(false);
    const trimmed = value.trim();
    if (trimmed && trimmed !== data.label) {
      data.onRename(trimmed);
    } else {
      setValue(data.label);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.85 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ type: "spring", stiffness: 300, damping: 22 }}
      className={clsx(
        "group relative min-w-36 rounded-xl border bg-surface-raised/95 px-4 py-2.5 text-center text-sm shadow-lg backdrop-blur-sm transition-shadow",
        selected
          ? "border-transparent bg-linear-to-r from-accent-from/15 to-accent-to/15 shadow-accent/30 ring-2 ring-accent"
          : "border-border hover:border-border-strong",
      )}
    >
      <Handle type="target" position={Position.Left} className="!border-none !bg-accent" />
      {editing ? (
        <input
          autoFocus
          value={value}
          onChange={(event) => setValue(event.target.value)}
          onBlur={commit}
          onKeyDown={(event) => {
            if (event.key === "Enter") commit();
            if (event.key === "Escape") {
              setValue(data.label);
              setEditing(false);
            }
          }}
          className="w-full rounded border border-accent bg-surface px-1 text-center text-sm text-text outline-none"
        />
      ) : (
        <span className="font-medium text-text" onDoubleClick={() => setEditing(true)}>
          {data.label}
        </span>
      )}
      <button
        type="button"
        aria-label={t("canvas.deleteClassNamed", { name: data.label })}
        onClick={(event) => {
          event.stopPropagation();
          data.onDelete();
        }}
        className="absolute -top-2 -right-2 flex h-5 w-5 items-center justify-center rounded-full border border-border bg-surface text-text-dim opacity-0 shadow transition group-hover:opacity-100 hover:border-danger hover:text-danger"
      >
        <X className="h-3 w-3" />
      </button>
      <Handle type="source" position={Position.Right} className="!border-none !bg-accent" />
    </motion.div>
  );
}
