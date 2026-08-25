import { mkdir, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { assertCardSchema, type CardSchema } from "../domain/schema.js";
import type { CommandRunner } from "../process/command-runner.js";
import type { WorkingCheckout } from "./working-checkout.js";

export class SchemaStore {
  readonly #checkout: WorkingCheckout;
  readonly #godotExecutable: string;
  readonly #runner: CommandRunner;
  readonly #schemas = new Map<string, CardSchema>();
  #current: CardSchema | null = null;

  constructor(checkout: WorkingCheckout, godotExecutable: string, runner: CommandRunner) {
    this.#checkout = checkout;
    this.#godotExecutable = godotExecutable;
    this.#runner = runner;
  }

  get current(): CardSchema {
    if (!this.#current) throw new Error("Card schema has not been loaded");
    return this.#current;
  }

  get(version: string): CardSchema | null {
    return this.#schemas.get(version) ?? null;
  }

  async refresh(): Promise<CardSchema> {
    const sourceCommit = await this.#checkout.sync();
    const workDirectory = resolve(this.#checkout.path, ".card-bot");
    const outputPath = join(workDirectory, "schema.json");
    await mkdir(workDirectory, { recursive: true });
    await this.#runner.run(this.#godotExecutable, [
      "--headless",
      "--path",
      this.#checkout.path,
      "--script",
      "res://tools/card_authoring/export_schema.gd",
      "--",
      "--output",
      outputPath,
      "--source-commit",
      sourceCommit,
    ], this.#checkout.path);
    const parsed: unknown = JSON.parse(await readFile(outputPath, "utf8"));
    assertCardSchema(parsed);
    this.#schemas.set(parsed.schema_version, parsed);
    this.#current = parsed;
    return parsed;
  }
}
