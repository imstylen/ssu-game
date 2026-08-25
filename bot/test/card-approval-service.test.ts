import assert from "node:assert/strict";
import { mkdir, mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import type { CardSchema } from "../src/domain/schema.js";
import type { SubmissionRecord } from "../src/domain/submission.js";
import type { CardPublisher, GeneratedFile } from "../src/github/github-publisher.js";
import { CardApprovalService } from "../src/godot/card-approval-service.js";
import type { SchemaStore } from "../src/godot/schema-store.js";
import type { WorkingCheckout } from "../src/godot/working-checkout.js";
import type { CommandRunner } from "../src/process/command-runner.js";

const version = "a".repeat(64);
const schema: CardSchema = {
  schema_version: version,
  source_commit: "commit",
  card_types: [],
  fields: [],
  effects: [],
  styles: [],
  existing_card_ids: [],
};

function submission(artworkPath: string): SubmissionRecord {
  return {
    id: "submission",
    guildId: "guild",
    submitterId: "user",
    schemaVersion: version,
    status: "processing",
    stage: "review",
    payload: { card: { future_attribute: 7 }, style_id: "future" },
    artworkPath,
    reviewChannelId: null,
    reviewMessageId: null,
    moderatorId: "moderator",
    decisionReason: null,
    pullRequestUrl: null,
    pullRequestNumber: null,
    createdAt: "now",
    updatedAt: "now",
  };
}

test("publishes only Godot-generated files after importing generated artwork and running tests", async () => {
  const checkoutPath = await mkdtemp(join(tmpdir(), "card-approval-"));
  const artworkPath = join(checkoutPath, "source.png");
  await writeFile(artworkPath, "artwork");
  const commands: readonly string[][] = [];
  const mutableCommands = commands as string[][];
  const runner: CommandRunner = {
    async run(_executable, arguments_) {
      mutableCommands.push([...arguments_]);
      if (arguments_.includes("res://tools/card_authoring/create_card.gd")) {
        const outputPath = arguments_[arguments_.indexOf("--output") + 1]!;
        const cardDirectory = join(checkoutPath, "cards", "definitions", "new_card");
        await mkdir(cardDirectory, { recursive: true });
        await writeFile(join(cardDirectory, "new_card.tres"), "resource");
        await writeFile(join(cardDirectory, "new_card.png"), "png");
        await writeFile(join(cardDirectory, "new_card.png.import"), "import");
        await writeFile(outputPath, JSON.stringify({
          ok: true,
          generated_files: [
            "res://cards/definitions/new_card/new_card.tres",
            "res://cards/definitions/new_card/new_card.png",
          ],
          expected_import_path: "res://cards/definitions/new_card/new_card.png.import",
        }));
      }
      return { stdout: "", stderr: "" };
    },
  };
  let publishedFiles: GeneratedFile[] = [];
  const publisher: CardPublisher = {
    async publish(_schema, _submission, files) {
      publishedFiles = files;
      return { url: "https://github.test/pull/1", number: 1, branch: "card-submission/submission" };
    },
  };
  const checkout = { path: checkoutPath } as WorkingCheckout;
  const schemas = { refresh: async () => schema } as SchemaStore;
  const service = new CardApprovalService(checkout, schemas, "godot", runner, publisher);

  const result = await service.approve(submission(artworkPath));

  assert.equal(result.kind, "approved");
  assert.deepEqual(publishedFiles.map((file) => file.path).sort(), [
    "cards/definitions/new_card/new_card.png",
    "cards/definitions/new_card/new_card.png.import",
    "cards/definitions/new_card/new_card.tres",
  ]);
  assert.equal(commands.filter((arguments_) => arguments_.includes("--import")).length, 1);
  assert.equal(commands.some((arguments_) => arguments_.includes("res://tests/test_runner.gd")), true);
});

test("stops before generation when the schema changed", async () => {
  const checkoutPath = await mkdtemp(join(tmpdir(), "card-approval-"));
  const changed = { ...schema, schema_version: "b".repeat(64) };
  const runner: CommandRunner = { async run() { throw new Error("must not run"); } };
  const publisher: CardPublisher = { async publish() { throw new Error("must not publish"); } };
  const service = new CardApprovalService(
    { path: checkoutPath } as WorkingCheckout,
    { refresh: async () => changed } as SchemaStore,
    "godot",
    runner,
    publisher,
  );

  const result = await service.approve(submission(join(checkoutPath, "art.png")));

  assert.equal(result.kind, "needs_revision");
});
