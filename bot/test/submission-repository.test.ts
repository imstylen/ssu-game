import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { SubmissionRepository } from "../src/storage/submission-repository.js";

test("persists schema-shaped JSON and enforces one moderation decision", () => {
  const repository = new SubmissionRepository(":memory:");
  const draft = repository.createDraft({ id: "submission-1", guildId: "guild", submitterId: "user", schemaVersion: "v1" });
  assert.deepEqual(draft.payload, { card: {} });
  repository.saveProgress("submission-1", { card: { future_attribute: 42 }, style_id: "mint" }, "details");
  repository.saveArtwork("submission-1", "/data/art.png");
  repository.queueForReview("submission-1");

  assert.equal(repository.getRequired("submission-1").payload.card.future_attribute, 42);
  assert.equal(repository.claimForApproval("submission-1", "moderator-a"), true);
  assert.equal(repository.claimForApproval("submission-1", "moderator-b"), false);

  repository.markApproved("submission-1", "https://github.test/pr/1", 1);
  assert.equal(repository.getRequired("submission-1").status, "approved");
  repository.close();
});

test("finds an active thread draft and stores artwork before review", () => {
  const repository = new SubmissionRepository(":memory:");
  repository.createDraft({
    id: "thread-draft",
    guildId: "guild",
    submitterId: "user",
    schemaVersion: "v1",
    stage: "card.name",
    threadId: "thread",
  });

  assert.equal(repository.findDraftBySubmitter("guild", "user")?.threadId, "thread");
  assert.equal(repository.findByThread("thread")?.id, "thread-draft");
  repository.saveArtwork("thread-draft", "/data/thread-draft.png");
  repository.queueForReview("thread-draft");
  assert.equal(repository.getRequired("thread-draft").status, "pending");
  repository.close();
});

test("normalizes drafts created before the card payload invariant", async () => {
  const directory = await mkdtemp(join(tmpdir(), "card-submissions-"));
  const path = join(directory, "submissions.sqlite");
  const repository = new SubmissionRepository(path);
  repository.createDraft({ id: "legacy", guildId: "guild", submitterId: "user", schemaVersion: "v1" });
  repository.close();
  const database = new DatabaseSync(path);
  database.prepare("UPDATE submissions SET payload_json = '{}' WHERE id = 'legacy'").run();
  database.close();

  const reopened = new SubmissionRepository(path);
  assert.deepEqual(reopened.getRequired("legacy").payload, { card: {} });
  reopened.close();
});

test("adds thread storage to databases created before conversation intake", async () => {
  const directory = await mkdtemp(join(tmpdir(), "card-submissions-"));
  const path = join(directory, "legacy.sqlite");
  const database = new DatabaseSync(path);
  database.exec(`
    CREATE TABLE submissions (
      id TEXT PRIMARY KEY,
      guild_id TEXT NOT NULL,
      submitter_id TEXT NOT NULL,
      schema_version TEXT NOT NULL,
      status TEXT NOT NULL,
      stage TEXT NOT NULL,
      payload_json TEXT NOT NULL,
      artwork_path TEXT,
      review_channel_id TEXT,
      review_message_id TEXT,
      moderator_id TEXT,
      decision_reason TEXT,
      pull_request_url TEXT,
      pull_request_number INTEGER,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    ) STRICT;
  `);
  database.close();

  const repository = new SubmissionRepository(path);
  const draft = repository.createDraft({
    id: "migrated",
    guildId: "guild",
    submitterId: "user",
    schemaVersion: "v1",
    stage: "card.name",
    threadId: "thread",
  });
  assert.equal(draft.threadId, "thread");
  repository.close();
});

test("records denial reasons atomically", () => {
  const repository = new SubmissionRepository(":memory:");
  repository.createDraft({ id: "submission-2", guildId: "guild", submitterId: "user", schemaVersion: "v1" });
  repository.saveArtwork("submission-2", "/data/art.png");
  repository.queueForReview("submission-2");

  assert.equal(repository.deny("submission-2", "moderator", "Needs a clearer effect."), true);
  assert.equal(repository.deny("submission-2", "other", "Second decision"), false);
  assert.equal(repository.getRequired("submission-2").decisionReason, "Needs a clearer effect.");
  repository.close();
});
