import assert from "node:assert/strict";
import test from "node:test";
import type { CardSchema } from "../src/domain/schema.js";
import type { SubmissionRecord } from "../src/domain/submission.js";
import { buildPullRequestBody } from "../src/github/pull-request-body.js";

test("builds PR content from schema fields instead of production IDs", () => {
  const schema: CardSchema = {
    schema_version: "a".repeat(64),
    source_commit: "test",
    card_types: [],
    fields: [{ id: "brand_new", label: "Brand New", description: "", type: "string", component: "text", required: true, default: "", submitter_editable: true }],
    effects: [],
    styles: [{ id: "style", display_name: "Style", resource_path: "res://style.tres" }],
    existing_card_ids: [],
  };
  const submission: SubmissionRecord = {
    id: "submission",
    guildId: "guild",
    submitterId: "user",
    schemaVersion: schema.schema_version,
    status: "processing",
    stage: "review",
    threadId: null,
    payload: { card: { brand_new: "Inherited" }, style_id: "style" },
    artworkPath: "/data/art.png",
    reviewChannelId: null,
    reviewMessageId: null,
    moderatorId: "moderator",
    decisionReason: null,
    pullRequestUrl: null,
    pullRequestNumber: null,
    createdAt: "now",
    updatedAt: "now",
  };

  assert.match(buildPullRequestBody(schema, submission), /Brand New:\*\* Inherited/);
});
