// Mirrors backend/api/core/models.py (OntoNovaSchema and its $defs).
// Keep in sync manually — the Pydantic models are the source of truth.

export type XsdDatatype =
  | "xsd:string"
  | "xsd:integer"
  | "xsd:float"
  | "xsd:boolean"
  | "xsd:dateTime";

export type ObjectPropertyCharacteristic =
  | "Functional"
  | "InverseFunctional"
  | "Transitive"
  | "Symmetric"
  | "Asymmetric"
  | "Reflexive"
  | "Irreflexive";

export interface OntoClass {
  id: string;
  name: string;
  subClassOf: string | null;
  metadata?: Record<string, unknown>;
}

export interface ObjectProperty {
  id: string;
  name: string;
  domain: string;
  range: string;
  characteristics: ObjectPropertyCharacteristic[];
  metadata?: Record<string, unknown>;
}

export interface DataProperty {
  id: string;
  name: string;
  domain: string;
  range: XsdDatatype | string;
  metadata?: Record<string, unknown>;
}

export interface Individual {
  id: string;
  name: string;
  typeClass: string;
  objectPropertyAssertions: Record<string, string[]>;
  dataPropertyAssertions: Record<string, unknown>;
  metadata?: Record<string, unknown>;
}

export interface OntoNovaSchema {
  classes: OntoClass[];
  object_properties: ObjectProperty[];
  data_properties: DataProperty[];
  individuals: Individual[];
}

export type GenerationStage = "taxonomist" | "relational" | "populator" | "validator" | "done" | "generation";
export type GenerationStatus = "completed" | "retrying" | "failed" | "success";

export interface GenerationEvent {
  stage: GenerationStage;
  status: GenerationStatus;
  error?: string;
  /** Machine-readable failure kind so the UI can localize the message
   *  (`error` is the English fallback for direct API consumers). */
  code?: "input_too_long" | "llm_error" | "unexpected_error";
  params?: Record<string, number>;
  payload?: OntoNovaSchema;
}

export type ExportFormat = "rdf-xml" | "turtle";
