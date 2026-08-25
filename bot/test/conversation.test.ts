import assert from "node:assert/strict";
import test from "node:test";
import {
  applySelectionAnswer,
  applyTextAnswer,
  buildConversationPlan,
  nextConversationStep,
} from "../src/domain/conversation.js";
import type { CardSchema } from "../src/domain/schema.js";
import type { CardSubmissionPayload } from "../src/domain/submission.js";

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
    { id: "power", label: "Power", description: "", type: "integer", component: "text", required: true, default: 1, submitter_editable: true, minimum: 0, maximum: 10, visible_when: { field: "kind", equals: 0 } },
    { id: "cost", label: "Cost", description: "", type: "integer", component: "text", required: true, default: 0, submitter_editable: true, minimum: 0, maximum: 10 },
  ],
  effects: [{
    id: "draw",
    display_name: "Draw",
    description: "Draw cards",
    allowed_card_types: [1],
    fields: [{ id: "amount", label: "Amount", description: "", type: "integer", component: "text", required: true, default: 2, submitter_editable: true, minimum: 1, maximum: 5 }],
  }],
  styles: [{ id: "mint", display_name: "Mint", resource_path: "res://mint.tres" }],
  existing_card_ids: [],
};

test("conversation plan inherits visible card fields and selected effect fields", () => {
  let payload: CardSubmissionPayload = { card: {} };
  const kindStep = buildConversationPlan(schema, payload).find((step) => step.id === "card.kind");
  assert.ok(kindStep);
  payload = applySelectionAnswer(payload, kindStep, "action");
  const effectStep = buildConversationPlan(schema, payload).find((step) => step.kind === "effect");
  assert.ok(effectStep);
  payload = applySelectionAnswer(payload, effectStep, "draw");

  assert.deepEqual(
    buildConversationPlan(schema, payload).filter((step) => step.kind === "field").map((step) => step.id),
    ["card.name", "card.kind", "card.cost", "effect.amount"],
  );
});

test("text answers enforce schema constraints and support defaults", () => {
  const payload: CardSubmissionPayload = { card: { kind: 0 } };
  const power = buildConversationPlan(schema, payload).find((step) => step.id === "card.power");
  assert.ok(power);
  assert.equal(applyTextAnswer(payload, power, "default").card.power, 1);
  assert.throws(() => applyTextAnswer(payload, power, "11"), /no more than 10/);
});

test("next step skips artwork already uploaded earlier in the conversation", () => {
  const payload: CardSubmissionPayload = { card: {} };
  assert.equal(nextConversationStep(schema, payload, "credit", true).id, "ready");
  assert.equal(nextConversationStep(schema, payload, "credit", false).id, "artwork");
});
