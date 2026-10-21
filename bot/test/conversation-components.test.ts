import assert from "node:assert/strict";
import test from "node:test";
import type { ConversationStep } from "../src/domain/conversation.js";
import type { CardSchema } from "../src/domain/schema.js";
import type { SubmissionRecord } from "../src/domain/submission.js";
import { buildConversationPrompt } from "../src/discord/conversation-components.js";

const schema: CardSchema = {
  schema_version: "a".repeat(64),
  source_commit: "test",
  card_types: [{ id: "future", label: "Future Type", value: 7 }],
  fields: [{
    id: "future_kind",
    label: "Future Kind",
    description: "A newly exported choice.",
    type: "enum",
    component: "select",
    required: true,
    default: 7,
    submitter_editable: true,
    options: [{ id: "future", label: "Future Type", value: 7 }],
  }],
  effects: [],
  styles: [],
  existing_card_ids: [],
};

const submission: SubmissionRecord = {
  id: "submission",
  guildId: "guild",
  submitterId: "user",
  schemaVersion: schema.schema_version,
  status: "draft",
  stage: "card.future_kind",
  threadId: "thread",
  payload: { card: {} },
  artworkPath: null,
  reviewChannelId: null,
  reviewMessageId: null,
  moderatorId: null,
  decisionReason: null,
  pullRequestUrl: null,
  pullRequestNumber: null,
  createdAt: "now",
  updatedAt: "now",
};

test("renders schema choices as a thread select menu", () => {
  const step: ConversationStep = { id: "card.future_kind", kind: "field", scope: "card", field: schema.fields[0]! };
  const prompt = buildConversationPrompt(schema, submission, step);
  const component = prompt.components?.[0];
  assert.ok(component && "toJSON" in component);
  const row = component.toJSON() as {
    components: Array<{ custom_id?: string; options?: Array<{ label?: string }> }>;
  };
  assert.equal(row?.components[0]?.custom_id, "card:answer:submission:card.future_kind");
  assert.equal(row?.components[0]?.options?.[0]?.label, "Future Type");
});
