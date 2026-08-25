import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import type { CommandRunner } from "../src/process/command-runner.js";
import { SchemaStore } from "../src/godot/schema-store.js";
import type { WorkingCheckout } from "../src/godot/working-checkout.js";

test("caches exported schemas by content version", async () => {
  const checkoutPath = await mkdtemp(join(tmpdir(), "card-schema-"));
  const version = "a".repeat(64);
  const checkout = {
    path: checkoutPath,
    sync: async () => "commit-sha",
  } as WorkingCheckout;
  const calls: string[][] = [];
  const runner: CommandRunner = {
    async run(_executable, arguments_) {
      calls.push([...arguments_]);
      if (!arguments_.includes("res://tools/card_authoring/export_schema.gd")) {
        return { stdout: "", stderr: "" };
      }
      const outputIndex = arguments_.indexOf("--output");
      const output = arguments_[outputIndex + 1];
      assert.ok(output);
      await mkdir(join(checkoutPath, ".card-bot"), { recursive: true });
      await writeFile(output, JSON.stringify({
        schema_version: version,
        source_commit: "commit-sha",
        card_types: [],
        fields: [],
        effects: [],
        styles: [],
        existing_card_ids: [],
      }));
      return { stdout: "", stderr: "" };
    },
  };
  const store = new SchemaStore(checkout, "godot", runner);

  const schema = await store.refresh();

  assert.equal(schema.source_commit, "commit-sha");
  assert.equal(store.current, schema);
  assert.equal(store.get(version), schema);
  assert.deepEqual(calls[0], ["--headless", "--import", "--path", checkoutPath]);
  assert.equal(calls[1]?.includes("res://tools/card_authoring/export_schema.gd"), true);
});
