import { create } from "zustand";
import type {
  DataProperty,
  Individual,
  ObjectProperty,
  OntoClass,
  OntoNovaSchema,
} from "../types/ontology";

interface OntologyState {
  classes: OntoClass[];
  objectProperties: ObjectProperty[];
  dataProperties: DataProperty[];
  individuals: Individual[];
  selectedClassId: string | null;

  loadFromGeneration: (schema: OntoNovaSchema) => void;
  reset: () => void;
  selectClass: (id: string | null) => void;

  addClass: (partial: Pick<OntoClass, "id" | "name">) => void;
  updateClass: (id: string, patch: Partial<Omit<OntoClass, "id">>) => void;
  removeClass: (id: string) => void;

  addObjectProperty: (property: ObjectProperty) => void;
  updateObjectProperty: (id: string, patch: Partial<Omit<ObjectProperty, "id">>) => void;
  removeObjectProperty: (id: string) => void;

  addDataProperty: (property: DataProperty) => void;
  updateDataProperty: (id: string, patch: Partial<Omit<DataProperty, "id">>) => void;
  removeDataProperty: (id: string) => void;

  addIndividual: (individual: Individual) => void;
  removeIndividual: (id: string) => void;

  toSchema: () => OntoNovaSchema;
}

const EMPTY_STATE = {
  classes: [] as OntoClass[],
  objectProperties: [] as ObjectProperty[],
  dataProperties: [] as DataProperty[],
  individuals: [] as Individual[],
  selectedClassId: null as string | null,
};

export const useOntologyStore = create<OntologyState>((set, get) => ({
  ...EMPTY_STATE,

  loadFromGeneration: (schema) =>
    set({
      classes: schema.classes,
      objectProperties: schema.object_properties,
      dataProperties: schema.data_properties,
      individuals: schema.individuals,
      selectedClassId: null,
    }),

  reset: () => set({ ...EMPTY_STATE }),

  selectClass: (id) => set({ selectedClassId: id }),

  addClass: (partial) =>
    set((state) => ({
      classes: [...state.classes, { id: partial.id, name: partial.name, subClassOf: null }],
    })),

  updateClass: (id, patch) =>
    set((state) => ({
      classes: state.classes.map((cls) => (cls.id === id ? { ...cls, ...patch } : cls)),
    })),

  removeClass: (id) =>
    set((state) => ({
      classes: state.classes
        .filter((cls) => cls.id !== id)
        // A surviving class may have pointed at the removed one as its
        // parent — clear it instead of leaving a dangling subClassOf.
        .map((cls) => (cls.subClassOf === id ? { ...cls, subClassOf: null } : cls)),
      objectProperties: state.objectProperties.filter(
        (prop) => prop.domain !== id && prop.range !== id,
      ),
      dataProperties: state.dataProperties.filter((prop) => prop.domain !== id),
      individuals: state.individuals.filter((individual) => individual.typeClass !== id),
      selectedClassId: state.selectedClassId === id ? null : state.selectedClassId,
    })),

  addObjectProperty: (property) =>
    set((state) => ({ objectProperties: [...state.objectProperties, property] })),

  updateObjectProperty: (id, patch) =>
    set((state) => ({
      objectProperties: state.objectProperties.map((prop) =>
        prop.id === id ? { ...prop, ...patch } : prop,
      ),
    })),

  removeObjectProperty: (id) =>
    set((state) => ({
      objectProperties: state.objectProperties.filter((prop) => prop.id !== id),
    })),

  addDataProperty: (property) =>
    set((state) => ({ dataProperties: [...state.dataProperties, property] })),

  updateDataProperty: (id, patch) =>
    set((state) => ({
      dataProperties: state.dataProperties.map((prop) =>
        prop.id === id ? { ...prop, ...patch } : prop,
      ),
    })),

  removeDataProperty: (id) =>
    set((state) => ({
      dataProperties: state.dataProperties.filter((prop) => prop.id !== id),
    })),

  addIndividual: (individual) =>
    set((state) => ({ individuals: [...state.individuals, individual] })),

  removeIndividual: (id) =>
    set((state) => ({
      individuals: state.individuals.filter((individual) => individual.id !== id),
    })),

  toSchema: (): OntoNovaSchema => {
    const state = get();
    return {
      classes: state.classes,
      object_properties: state.objectProperties,
      data_properties: state.dataProperties,
      individuals: state.individuals,
    };
  },
}));
