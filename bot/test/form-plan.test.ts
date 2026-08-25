import assert from "node:assert/strict";
import test from "node:test";
import type { CardSchema } from "../src/domain/schema.js";
import { buildFormPlan } from "../src/domain/form-plan.js";

const schema: CardSchema = {
  schema_version: "a".repeat(64),
  source_commit: "test",
  card_types: [
    { id: "unit", label: "Ally", value: 0 },
    { id: "action", label: "One-Shot", value: 1 },
  ],
  fields: [
    { id: "name", label: "Name", description: "", type: "string", component: "text", required: true, default: "", submitter_editable: true },
    { id: "kind", label: "Kind", description: "", type: "enum", component: "select", required: true, default: 0, submitter_editable: true, options: [
      { id: "unit", label: "Ally", value: 0 },
      { id: "action", label: "One-Shot", value: 1 },
    ] },
    { id: "power", label: "Power", description: "", type: "integer", component: "text", required: true, default: 0, submitter_editable: true, visible_when: { field: "kind", equals: 0 } },
    { id: "bonus", label: "Bonus", description: "", type: "boolean", component: "select", required: true, default: false, submitter_editable: true },
  ],
  effects: [{ id: "draw", display_name: "Draw", description: "", allowed_card_types: [1], fields: [] }],
  styles: [{ id: "mint", display_name: "Mint", resource_path: "res://mint.tres" }],
  existing_card_ids: [],
};

test("plans fields from schema without production field names", () => {
  const steps = buildFormPlan(schema, { card: { kind: 0 } });
  assert.deepEqual(steps.flatMap((step) => step.fields.map((field) => field.id)), ["name", "kind", "power", "bonus"]);
  assert.equal(steps[0]?.includeStyle, true);
  assert.equal(steps.some((step) => step.includeEffect), false);
});

test("hides conditional fields and offers compatible effects", () => {
  const steps = buildFormPlan(schema, { card: { kind: 1 } });
  assert.equal(steps.flatMap((step) => step.fields).some((field) => field.id === "power"), false);
  assert.equal(steps.some((step) => step.includeEffect), true);
});
