import assert from "node:assert/strict";
import test from "node:test";
import type { CardSchema } from "../src/domain/schema.js";
import type { SubmissionRecord } from "../src/domain/submission.js";
import { reviewLines } from "../src/discord/review-message.js";

const schema: CardSchema = {
  schema_version: "a".repeat(64),
  source_commit: "test",
  card_types: [],
  fields: [
    { id: "future_attribute", label: "Future Attribute", description: "", type: "integer", component: "text", required: true, default: 0, submitter_editable: true },
  ],
  effects: [{
    id: "future_effect",
    display_name: "Future Effect",
    description: "",
    allowed_card_types: [0],
    fields: [{ id: "future_amount", label: "Future Amount", description: "", type: "integer", component: "text", required: true, default: 1, submitter_editable: true }],
  }],
  styles: [{ id: "future_style", display_name: "Future Style", resource_path: "res://future.tres" }],
  existing_card_ids: [],
};

const submission: SubmissionRecord = {
  id: "submission",
  guildId: "guild",
  submitterId: "submitter",
  schemaVersion: schema.schema_version,
  status: "pending",
  stage: "review",
  threadId: null,
  payload: {
    card: { future_attribute: 7 },
    style_id: "future_style",
    effect: { id: "future_effect", parameters: { future_amount: 3 } },
  },
  artworkPath: "/tmp/art.png",
  reviewChannelId: null,
  reviewMessageId: null,
  moderatorId: null,
  decisionReason: null,
  pullRequestUrl: null,
  pullRequestNumber: null,
  createdAt: "now",
  updatedAt: "now",
};

test("renders new schema fields, styles, and effects without ID-specific code", () => {
  const lines = reviewLines(schema, submission).join("\n");
  assert.match(lines, /Future Attribute.*7/);
  assert.match(lines, /Future Style/);
  assert.match(lines, /Future Effect/);
  assert.match(lines, /Future Amount.*3/);
});
