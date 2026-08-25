import assert from "node:assert/strict";
import test from "node:test";
import { SubmissionRepository } from "../src/storage/submission-repository.js";

test("persists schema-shaped JSON and enforces one moderation decision", () => {
  const repository = new SubmissionRepository(":memory:");
  repository.createDraft({ id: "submission-1", guildId: "guild", submitterId: "user", schemaVersion: "v1" });
  repository.saveProgress("submission-1", { card: { future_attribute: 42 }, style_id: "mint" }, "details");
  repository.awaitArtwork("submission-1", repository.getRequired("submission-1").payload);
  repository.queueForReview("submission-1", "/data/art.png");

  assert.equal(repository.getRequired("submission-1").payload.card.future_attribute, 42);
  assert.equal(repository.claimForApproval("submission-1", "moderator-a"), true);
  assert.equal(repository.claimForApproval("submission-1", "moderator-b"), false);

  repository.markApproved("submission-1", "https://github.test/pr/1", 1);
  assert.equal(repository.getRequired("submission-1").status, "approved");
  repository.close();
});

test("records denial reasons atomically", () => {
  const repository = new SubmissionRepository(":memory:");
  repository.createDraft({ id: "submission-2", guildId: "guild", submitterId: "user", schemaVersion: "v1" });
  repository.awaitArtwork("submission-2", { card: {} });
  repository.queueForReview("submission-2", "/data/art.png");

  assert.equal(repository.deny("submission-2", "moderator", "Needs a clearer effect."), true);
  assert.equal(repository.deny("submission-2", "other", "Second decision"), false);
  assert.equal(repository.getRequired("submission-2").decisionReason, "Needs a clearer effect.");
  repository.close();
});
