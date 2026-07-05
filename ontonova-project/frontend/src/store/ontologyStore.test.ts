import { beforeEach, describe, expect, it } from "vitest";
import { useOntologyStore } from "./ontologyStore";
import type { OntoNovaSchema } from "../types/ontology";

const SAMPLE_SCHEMA: OntoNovaSchema = {
  classes: [
    { id: "Class_Person", name: "Person", subClassOf: null },
    { id: "Class_Teacher", name: "Teacher", subClassOf: "Class_Person" },
  ],
  object_properties: [
    { id: "prop_teaches", name: "teaches", domain: "Class_Teacher", range: "Class_Person", characteristics: [] },
  ],
  data_properties: [
    { id: "attr_age", name: "age", domain: "Class_Person", range: "xsd:integer" },
  ],
  individuals: [
    {
      id: "inst_juan",
      name: "Juan",
      typeClass: "Class_Teacher",
      objectPropertyAssertions: {},
      dataPropertyAssertions: { attr_age: 45 },
    },
  ],
};

beforeEach(() => {
  useOntologyStore.getState().reset();
});

describe("ontologyStore", () => {
  it("starts empty", () => {
    const state = useOntologyStore.getState();
    expect(state.classes).toHaveLength(0);
    expect(state.toSchema()).toEqual({
      classes: [],
      object_properties: [],
      data_properties: [],
      individuals: [],
    });
  });

  it("loads a generated schema wholesale", () => {
    useOntologyStore.getState().loadFromGeneration(SAMPLE_SCHEMA);
    const state = useOntologyStore.getState();
    expect(state.classes).toEqual(SAMPLE_SCHEMA.classes);
    expect(state.toSchema()).toEqual(SAMPLE_SCHEMA);
  });

  it("adds a class with no parent", () => {
    useOntologyStore.getState().addClass({ id: "Class_Animal", name: "Animal" });
    expect(useOntologyStore.getState().classes).toEqual([
      { id: "Class_Animal", name: "Animal", subClassOf: null },
    ]);
  });

  it("renames a class in place", () => {
    useOntologyStore.getState().addClass({ id: "Class_Animal", name: "Animal" });
    useOntologyStore.getState().updateClass("Class_Animal", { name: "Creature" });
    expect(useOntologyStore.getState().classes[0].name).toBe("Creature");
  });

  it("cascades class removal to dependent properties and individuals", () => {
    useOntologyStore.getState().loadFromGeneration(SAMPLE_SCHEMA);
    useOntologyStore.getState().removeClass("Class_Teacher");

    const state = useOntologyStore.getState();
    expect(state.classes.map((c) => c.id)).toEqual(["Class_Person"]);
    // The object property's domain (Class_Teacher) no longer exists.
    expect(state.objectProperties).toHaveLength(0);
    // The individual's typeClass (Class_Teacher) no longer exists.
    expect(state.individuals).toHaveLength(0);
    // Data properties on the surviving class are untouched.
    expect(state.dataProperties).toHaveLength(1);
  });

  it("clears a surviving subclass's subClassOf when its parent is removed", () => {
    useOntologyStore.getState().loadFromGeneration(SAMPLE_SCHEMA);
    useOntologyStore.getState().removeClass("Class_Person");

    const state = useOntologyStore.getState();
    expect(state.classes).toEqual([{ id: "Class_Teacher", name: "Teacher", subClassOf: null }]);
  });

  it("clears the selection when the selected class is removed", () => {
    useOntologyStore.getState().loadFromGeneration(SAMPLE_SCHEMA);
    useOntologyStore.getState().selectClass("Class_Teacher");
    useOntologyStore.getState().removeClass("Class_Teacher");
    expect(useOntologyStore.getState().selectedClassId).toBeNull();
  });

  it("reset clears everything back to the empty state", () => {
    useOntologyStore.getState().loadFromGeneration(SAMPLE_SCHEMA);
    useOntologyStore.getState().reset();
    const state = useOntologyStore.getState();
    expect(state.classes).toHaveLength(0);
    expect(state.objectProperties).toHaveLength(0);
    expect(state.dataProperties).toHaveLength(0);
    expect(state.individuals).toHaveLength(0);
    expect(state.selectedClassId).toBeNull();
  });

  it("adds and removes individuals for a class", () => {
    useOntologyStore.getState().addClass({ id: "Class_Animal", name: "Animal" });
    useOntologyStore.getState().addIndividual({
      id: "inst_rex",
      name: "Rex",
      typeClass: "Class_Animal",
      objectPropertyAssertions: {},
      dataPropertyAssertions: {},
    });
    expect(useOntologyStore.getState().individuals).toHaveLength(1);

    useOntologyStore.getState().removeIndividual("inst_rex");
    expect(useOntologyStore.getState().individuals).toHaveLength(0);
  });
});
