export type FieldType = "string" | "integer" | "enum" | "boolean";

export interface SchemaOption {
  id: string;
  label: string;
  value: string | number | boolean;
}

export interface VisibilityRule {
  field: string;
  equals: unknown;
}

export interface FieldSchema {
  id: string;
  label: string;
  description: string;
  type: FieldType;
  component: "text" | "paragraph" | "select";
  required: boolean;
  default: unknown;
  submitter_editable: boolean;
  max_length?: number;
  minimum?: number;
  maximum?: number;
  step?: number;
  options?: SchemaOption[];
  visible_when?: VisibilityRule;
}

export interface EffectSchema {
  id: string;
  display_name: string;
  description: string;
  allowed_card_types: number[];
  fields: FieldSchema[];
}

export interface StyleSchema {
  id: string;
  display_name: string;
  resource_path: string;
}

export interface CardSchema {
  schema_version: string;
  source_commit: string;
  card_types: SchemaOption[];
  fields: FieldSchema[];
  effects: EffectSchema[];
  styles: StyleSchema[];
  existing_card_ids: string[];
}

export function fieldIsVisible(field: FieldSchema, values: Record<string, unknown>): boolean {
  if (!field.visible_when) return true;
  return values[field.visible_when.field] === field.visible_when.equals;
}

export function applicableEffects(schema: CardSchema, cardType: number): EffectSchema[] {
  return schema.effects.filter((effect) => effect.allowed_card_types.includes(cardType));
}

export function assertCardSchema(value: unknown): asserts value is CardSchema {
  if (!value || typeof value !== "object") throw new Error("Card schema must be an object");
  const schema = value as Partial<CardSchema>;
  if (typeof schema.schema_version !== "string" || !/^[a-f0-9]{64}$/.test(schema.schema_version)) {
    throw new Error("Card schema has an invalid content version");
  }
  for (const key of ["card_types", "fields", "effects", "styles", "existing_card_ids"] as const) {
    if (!Array.isArray(schema[key])) throw new Error(`Card schema is missing ${key}`);
  }
}
