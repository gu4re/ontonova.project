import {
  Background,
  Controls,
  MiniMap,
  ReactFlow,
  useEdgesState,
  useNodesState,
  type Connection,
} from "@xyflow/react";
import "@xyflow/react/dist/style.css";
import { AnimatePresence, motion } from "framer-motion";
import { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { validateOntology } from "../api/client";
import { useOntologyStore } from "../store/ontologyStore";
import { useThemeStore } from "../store/themeStore";
import { uniqueId } from "../utils/slug";
import { ClassNode, type ClassNodeType } from "./ClassNode";
import { EmptyState } from "./EmptyState";
import { RelationEdge, type RelationEdgeType } from "./RelationEdge";

const nodeTypes = { classNode: ClassNode };
const edgeTypes = { relation: RelationEdge };

const GRID_COLUMNS = 4;
const GRID_SPACING_X = 220;
const GRID_SPACING_Y = 140;

function gridPosition(index: number) {
  return {
    x: (index % GRID_COLUMNS) * GRID_SPACING_X,
    y: Math.floor(index / GRID_COLUMNS) * GRID_SPACING_Y,
  };
}

export function OntologyCanvas() {
  const { t } = useTranslation();
  const theme = useThemeStore((state) => state.theme);
  const classes = useOntologyStore((state) => state.classes);
  const objectProperties = useOntologyStore((state) => state.objectProperties);
  const dataProperties = useOntologyStore((state) => state.dataProperties);
  const individuals = useOntologyStore((state) => state.individuals);
  const updateClass = useOntologyStore((state) => state.updateClass);
  const removeClass = useOntologyStore((state) => state.removeClass);
  const addObjectProperty = useOntologyStore((state) => state.addObjectProperty);
  const updateObjectProperty = useOntologyStore((state) => state.updateObjectProperty);
  const removeObjectProperty = useOntologyStore((state) => state.removeObjectProperty);
  const selectClass = useOntologyStore((state) => state.selectClass);
  const toSchema = useOntologyStore((state) => state.toSchema);

  const [nodes, setNodes, onNodesChange] = useNodesState<ClassNodeType>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<RelationEdgeType>([]);
  const [validationError, setValidationError] = useState<string | null>(null);

  useEffect(() => {
    setNodes((current) => {
      const byId = new Map(current.map((node) => [node.id, node]));
      return classes.map((cls, index) => {
        const existing = byId.get(cls.id);
        return {
          id: cls.id,
          type: "classNode",
          position: existing?.position ?? gridPosition(index),
          selected: existing?.selected,
          data: {
            label: cls.name,
            onRename: (name: string) => updateClass(cls.id, { name }),
            onDelete: () => removeClass(cls.id),
          },
        };
      });
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [classes, setNodes]);

  useEffect(() => {
    const taxonomyEdges: RelationEdgeType[] = classes
      .filter((cls) => cls.subClassOf)
      .map((cls) => ({
        id: `subclass-${cls.id}`,
        type: "relation",
        source: cls.id,
        target: cls.subClassOf as string,
        data: {
          label: "subClassOf",
          kind: "subClassOf",
          onDelete: () => updateClass(cls.id, { subClassOf: null }),
        },
      }));

    const propertyEdges: RelationEdgeType[] = objectProperties.map((prop) => ({
      id: prop.id,
      type: "relation",
      source: prop.domain,
      target: prop.range,
      data: {
        label: prop.name,
        kind: "objectProperty",
        onRename: (name: string) => updateObjectProperty(prop.id, { name }),
        onDelete: () => removeObjectProperty(prop.id),
      },
    }));

    setEdges([...taxonomyEdges, ...propertyEdges]);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [classes, objectProperties, setEdges]);

  useEffect(() => {
    let cancelled = false;
    const timeout = setTimeout(() => {
      const schema = toSchema();
      if (schema.classes.length === 0) {
        setValidationError(null);
        return;
      }
      validateOntology(schema)
        .then((result) => {
          if (!cancelled) setValidationError(result.valid ? null : result.errors);
        })
        .catch(() => {
          // A validation request failing (e.g. backend unreachable) shouldn't
          // block editing (REQ-SW-NF-03) — just leave the last known state.
        });
    }, 400);
    return () => {
      cancelled = true;
      clearTimeout(timeout);
    };
  }, [classes, objectProperties, dataProperties, individuals, toSchema]);

  const existingPropertyIds = useMemo(
    () => objectProperties.map((prop) => prop.id),
    [objectProperties],
  );

  // React Flow's Controls/MiniMap render their own built-in tooltips/aria-labels
  // (e.g. "Zoom In") rather than accepting translated child content — this is
  // the library's supported override point for localizing them.
  const ariaLabelConfig = useMemo(
    () => ({
      "controls.ariaLabel": t("canvas.controlsLabel"),
      "controls.zoomIn.ariaLabel": t("canvas.zoomIn"),
      "controls.zoomOut.ariaLabel": t("canvas.zoomOut"),
      "controls.fitView.ariaLabel": t("canvas.fitView"),
      "controls.interactive.ariaLabel": t("canvas.toggleInteractivity"),
      "minimap.ariaLabel": t("canvas.miniMapLabel"),
    }),
    [t],
  );

  const onConnect = (connection: Connection) => {
    if (!connection.source || !connection.target) return;
    const id = uniqueId(existingPropertyIds, "prop_relatesTo");
    addObjectProperty({
      id,
      name: "relatesTo",
      domain: connection.source,
      range: connection.target,
      characteristics: [],
    });
  };

  return (
    <div className="absolute inset-0">
      <AnimatePresence>
        {validationError && (
          <motion.div
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            role="alert"
            className="absolute top-3 left-1/2 z-10 max-w-[70%] -translate-x-1/2 rounded-lg border border-danger/30 bg-surface-raised/90 px-4 py-2 text-center text-sm text-danger shadow-xl backdrop-blur"
          >
            {t("canvas.validationError", { error: validationError })}
          </motion.div>
        )}
      </AnimatePresence>

      {classes.length === 0 && <EmptyState />}

      <ReactFlow
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        edgeTypes={edgeTypes}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onNodesDelete={(deleted) => deleted.forEach((node) => node.data.onDelete())}
        onEdgesDelete={(deleted) => deleted.forEach((edge) => edge.data?.onDelete())}
        onNodeClick={(_, node) => selectClass(node.id)}
        onPaneClick={() => selectClass(null)}
        colorMode={theme}
        ariaLabelConfig={ariaLabelConfig}
        fitView
      >
        <Background
          color={theme === "dark" ? "rgba(255,255,255,0.08)" : "rgba(15,23,42,0.08)"}
          gap={24}
        />
        <Controls className="overflow-hidden rounded-lg border border-border shadow-xl" />
        <MiniMap
          pannable
          zoomable
          nodeColor="#8b5cf6"
          maskColor={theme === "dark" ? "rgba(5,6,10,0.75)" : "rgba(247,247,251,0.75)"}
          className="overflow-hidden rounded-lg border border-border shadow-xl"
        />
      </ReactFlow>
    </div>
  );
}
