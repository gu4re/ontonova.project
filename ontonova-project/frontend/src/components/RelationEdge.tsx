import {
  BaseEdge,
  EdgeLabelRenderer,
  getBezierPath,
  useStore,
  type Edge,
  type EdgeProps,
} from "@xyflow/react";
import { X } from "lucide-react";
import { useRef, useState, type MouseEvent as ReactMouseEvent, type PointerEvent as ReactPointerEvent } from "react";
import { useTranslation } from "react-i18next";

export interface RelationEdgeData extends Record<string, unknown> {
  label: string;
  kind: "objectProperty" | "subClassOf";
  onRename?: (name: string) => void;
  onDelete: () => void;
}

export type RelationEdgeType = Edge<RelationEdgeData, "relation">;

export function RelationEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  data,
  selected,
}: EdgeProps<RelationEdgeType>) {
  const { t } = useTranslation();
  const [editing, setEditing] = useState(false);
  const [value, setValue] = useState(data?.label ?? "");
  // The label defaults to the bezier midpoint but can be dragged anywhere on
  // the canvas (offset in FLOW coordinates, so it tracks its nodes when they
  // move and stays put across zooming). Component state survives the edge
  // array rebuilds in OntologyCanvas because React Flow keys edges by id.
  const [labelOffset, setLabelOffset] = useState({ x: 0, y: 0 });
  const dragRef = useRef<{ startX: number; startY: number; baseX: number; baseY: number } | null>(
    null,
  );
  const zoom = useStore((state) => state.transform[2]);
  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    targetX,
    targetY,
    sourcePosition,
    targetPosition,
  });

  if (!data) return <BaseEdge id={id} path={edgePath} />;

  const isTaxonomy = data.kind === "subClassOf";
  const labelPosX = labelX + labelOffset.x;
  const labelPosY = labelY + labelOffset.y;
  const isDisplaced = Math.hypot(labelOffset.x, labelOffset.y) > 12;

  const onLabelDoubleClick = (event: ReactMouseEvent<HTMLDivElement>) => {
    // Pointer capture (used for label dragging below) retargets the derived
    // dblclick to this container, so the rename trigger must live here —
    // a child-level handler never fires while dragging is enabled.
    if ((event.target as HTMLElement).closest("button, input")) return;
    if (!isTaxonomy && data.onRename) setEditing(true);
  };

  const onLabelPointerDown = (event: ReactPointerEvent<HTMLDivElement>) => {
    // Clicks on the delete button or the rename input are not drags.
    if ((event.target as HTMLElement).closest("button, input")) return;
    dragRef.current = {
      startX: event.clientX,
      startY: event.clientY,
      baseX: labelOffset.x,
      baseY: labelOffset.y,
    };
    event.currentTarget.setPointerCapture(event.pointerId);
    // Keep React Flow from interpreting the drag as a pane selection/pan.
    event.stopPropagation();
  };

  const onLabelPointerMove = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!dragRef.current) return;
    // Pointer deltas are screen pixels; divide by zoom to get flow units.
    setLabelOffset({
      x: dragRef.current.baseX + (event.clientX - dragRef.current.startX) / zoom,
      y: dragRef.current.baseY + (event.clientY - dragRef.current.startY) / zoom,
    });
  };

  const onLabelPointerUp = (event: ReactPointerEvent<HTMLDivElement>) => {
    dragRef.current = null;
    event.currentTarget.releasePointerCapture(event.pointerId);
  };

  const commit = () => {
    setEditing(false);
    const trimmed = value.trim();
    if (trimmed && trimmed !== data.label && data.onRename) data.onRename(trimmed);
    else setValue(data.label);
  };

  return (
    <>
      <BaseEdge
        id={id}
        path={edgePath}
        style={{
          strokeDasharray: isTaxonomy ? "6 4" : undefined,
          stroke: selected
            ? "var(--color-accent)"
            : isTaxonomy
              ? "var(--color-border-strong)"
              : "var(--color-text-dim)",
          strokeWidth: selected ? 2.5 : 1.5,
        }}
      />
      {isDisplaced && (
        // Leader line so a repositioned label stays visually tied to its edge.
        <path
          d={`M ${labelX} ${labelY} L ${labelPosX} ${labelPosY}`}
          stroke="var(--color-border-strong)"
          strokeWidth={1}
          strokeDasharray="2 3"
          fill="none"
        />
      )}
      <EdgeLabelRenderer>
        <div
          onPointerDown={onLabelPointerDown}
          onPointerMove={onLabelPointerMove}
          onPointerUp={onLabelPointerUp}
          onDoubleClick={onLabelDoubleClick}
          title={t("canvas.dragRelationLabel")}
          style={{ transform: `translate(-50%, -50%) translate(${labelPosX}px, ${labelPosY}px)` }}
          className="pointer-events-auto absolute flex cursor-grab touch-none items-center gap-1 rounded-md border border-border bg-surface-raised/95 px-2 py-0.5 text-xs text-text-muted shadow backdrop-blur-sm select-none active:cursor-grabbing"
        >
          {editing && !isTaxonomy ? (
            <input
              autoFocus
              value={value}
              onChange={(event) => setValue(event.target.value)}
              onBlur={commit}
              onKeyDown={(event) => event.key === "Enter" && commit()}
              className="w-20 rounded border border-accent bg-surface px-1 text-xs text-text outline-none"
            />
          ) : (
            <span>{data.label}</span>
          )}
          <button
            type="button"
            aria-label={t("canvas.deleteRelationNamed", { name: data.label })}
            onClick={() => data.onDelete()}
            className="text-text-dim transition hover:text-danger"
          >
            <X className="h-3 w-3" />
          </button>
        </div>
      </EdgeLabelRenderer>
    </>
  );
}
