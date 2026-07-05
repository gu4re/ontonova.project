import { useEffect, useState, type FormEvent } from "react";
import { Hash, Plus, User, X } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useOntologyStore } from "../store/ontologyStore";
import type { XsdDatatype } from "../types/ontology";
import { slugify, uniqueId } from "../utils/slug";

const XSD_TYPES: XsdDatatype[] = ["xsd:string", "xsd:integer", "xsd:float", "xsd:boolean", "xsd:dateTime"];

/** Every id currently in use, across all categories (ids share one flat RDF namespace on export). */
function allIds(): string[] {
  const state = useOntologyStore.getState();
  return [
    ...state.classes.map((cls) => cls.id),
    ...state.objectProperties.map((prop) => prop.id),
    ...state.dataProperties.map((prop) => prop.id),
    ...state.individuals.map((individual) => individual.id),
  ];
}

export function InspectorPanel() {
  const { t } = useTranslation();
  const selectedClassId = useOntologyStore((state) => state.selectedClassId);
  const classes = useOntologyStore((state) => state.classes);
  const dataProperties = useOntologyStore((state) => state.dataProperties);
  const individuals = useOntologyStore((state) => state.individuals);
  const addDataProperty = useOntologyStore((state) => state.addDataProperty);
  const removeDataProperty = useOntologyStore((state) => state.removeDataProperty);
  const addIndividual = useOntologyStore((state) => state.addIndividual);
  const removeIndividual = useOntologyStore((state) => state.removeIndividual);

  const [newPropertyName, setNewPropertyName] = useState("");
  const [newPropertyRange, setNewPropertyRange] = useState<XsdDatatype>("xsd:string");
  const [newIndividualName, setNewIndividualName] = useState("");

  // Otherwise the previous class's in-progress form values (e.g. a chosen
  // datatype) silently carry over when the user selects a different class.
  useEffect(() => {
    setNewPropertyName("");
    setNewPropertyRange("xsd:string");
    setNewIndividualName("");
  }, [selectedClassId]);

  const selectedClass = classes.find((cls) => cls.id === selectedClassId);

  if (!selectedClass) {
    return (
      <p className="mt-6 text-center text-sm text-text-dim">{t("inspector.emptySelection")}</p>
    );
  }

  const classDataProperties = dataProperties.filter((prop) => prop.domain === selectedClass.id);
  const classIndividuals = individuals.filter((individual) => individual.typeClass === selectedClass.id);

  const handleAddProperty = (event: FormEvent) => {
    event.preventDefault();
    const trimmed = newPropertyName.trim();
    if (!trimmed) return;
    // Read fresh state (not the closed-over values from the last render) and
    // check across every category — ids must be globally unique since the
    // backend maps them all into one RDF namespace on export.
    const id = uniqueId(allIds(), slugify(trimmed, "attr_", { capitalizeFirst: false }));
    addDataProperty({ id, name: trimmed, domain: selectedClass.id, range: newPropertyRange });
    setNewPropertyName("");
  };

  const handleAddIndividual = (event: FormEvent) => {
    event.preventDefault();
    const trimmed = newIndividualName.trim();
    if (!trimmed) return;
    const id = uniqueId(allIds(), slugify(trimmed, "inst_", { capitalizeFirst: false }));
    addIndividual({
      id,
      name: trimmed,
      typeClass: selectedClass.id,
      objectPropertyAssertions: {},
      dataPropertyAssertions: {},
    });
    setNewIndividualName("");
  };

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h3 className="text-base font-semibold text-text">{selectedClass.name}</h3>
        <p className="font-mono text-xs text-text-dim">{selectedClass.id}</p>
      </div>

      <section className="flex flex-col gap-2">
        <h4 className="flex items-center gap-1.5 text-xs font-semibold tracking-wide text-text-muted uppercase">
          <Hash className="h-3.5 w-3.5" /> {t("inspector.dataProperties")}
        </h4>
        <ul className="flex flex-col gap-1">
          {classDataProperties.map((prop) => (
            <li
              key={prop.id}
              className="flex items-center justify-between rounded-lg bg-surface-raised px-2.5 py-1.5 text-sm"
            >
              <span className="text-text">
                {prop.name} <em className="text-text-dim not-italic">({prop.range.replace("xsd:", "")})</em>
              </span>
              <button
                type="button"
                aria-label={t("inspector.removeNamed", { name: prop.name })}
                onClick={() => removeDataProperty(prop.id)}
                className="text-text-dim transition hover:text-danger"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </li>
          ))}
          {classDataProperties.length === 0 && (
            <li className="px-2.5 py-1 text-sm text-text-dim">{t("inspector.noneYet")}</li>
          )}
        </ul>
        <form onSubmit={handleAddProperty} className="flex gap-1.5">
          <input
            value={newPropertyName}
            onChange={(event) => setNewPropertyName(event.target.value)}
            placeholder={t("inspector.attributeNamePlaceholder")}
            className="min-w-0 flex-1 rounded-lg border border-border bg-surface-raised px-2.5 py-1.5 text-sm text-text placeholder:text-text-dim outline-none focus-visible:border-accent focus-visible:ring-2 focus-visible:ring-accent/40"
          />
          <select
            value={newPropertyRange}
            onChange={(event) => setNewPropertyRange(event.target.value as XsdDatatype)}
            className="rounded-lg border border-border bg-surface-raised px-1.5 py-1.5 text-sm text-text outline-none focus-visible:border-accent"
          >
            {XSD_TYPES.map((type) => (
              <option key={type} value={type}>
                {type.replace("xsd:", "")}
              </option>
            ))}
          </select>
          <button
            type="submit"
            aria-label={t("inspector.add")}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-border bg-surface-raised text-text-muted transition hover:border-accent hover:text-accent"
          >
            <Plus className="h-4 w-4" />
          </button>
        </form>
      </section>

      <section className="flex flex-col gap-2">
        <h4 className="flex items-center gap-1.5 text-xs font-semibold tracking-wide text-text-muted uppercase">
          <User className="h-3.5 w-3.5" /> {t("inspector.individuals")}
        </h4>
        <ul className="flex flex-col gap-1">
          {classIndividuals.map((individual) => (
            <li
              key={individual.id}
              className="flex items-center justify-between rounded-lg bg-surface-raised px-2.5 py-1.5 text-sm text-text"
            >
              <span>{individual.name}</span>
              <button
                type="button"
                aria-label={t("inspector.removeNamed", { name: individual.name })}
                onClick={() => removeIndividual(individual.id)}
                className="text-text-dim transition hover:text-danger"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </li>
          ))}
          {classIndividuals.length === 0 && (
            <li className="px-2.5 py-1 text-sm text-text-dim">{t("inspector.noneYet")}</li>
          )}
        </ul>
        <form onSubmit={handleAddIndividual} className="flex gap-1.5">
          <input
            value={newIndividualName}
            onChange={(event) => setNewIndividualName(event.target.value)}
            placeholder={t("inspector.individualNamePlaceholder")}
            className="min-w-0 flex-1 rounded-lg border border-border bg-surface-raised px-2.5 py-1.5 text-sm text-text placeholder:text-text-dim outline-none focus-visible:border-accent focus-visible:ring-2 focus-visible:ring-accent/40"
          />
          <button
            type="submit"
            aria-label={t("inspector.add")}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-border bg-surface-raised text-text-muted transition hover:border-accent hover:text-accent"
          >
            <Plus className="h-4 w-4" />
          </button>
        </form>
      </section>
    </div>
  );
}
