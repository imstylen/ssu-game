import { access, mkdir, readFile, writeFile } from "node:fs/promises";
import { isAbsolute, relative, resolve, sep } from "node:path";
import type { CardSchema } from "../domain/schema.js";
import type { SubmissionRecord } from "../domain/submission.js";
import type { CardPublisher, GeneratedFile, PublishedPullRequest } from "../github/github-publisher.js";
import type { CommandRunner } from "../process/command-runner.js";
import type { SchemaStore } from "./schema-store.js";
import type { WorkingCheckout } from "./working-checkout.js";

interface CardManifest {
  ok: boolean;
  generated_files?: string[];
  expected_import_path?: string;
  validation_errors?: string[];
}

export type ApprovalResult =
  | { kind: "approved"; pullRequest: PublishedPullRequest }
  | { kind: "needs_revision"; reason: string };

export class CardApprovalService {
  readonly #checkout: WorkingCheckout;
  readonly #schemas: SchemaStore;
  readonly #godotExecutable: string;
  readonly #runner: CommandRunner;
  readonly #publisher: CardPublisher;

  constructor(
    checkout: WorkingCheckout,
    schemas: SchemaStore,
    godotExecutable: string,
    runner: CommandRunner,
    publisher: CardPublisher,
  ) {
    this.#checkout = checkout;
    this.#schemas = schemas;
    this.#godotExecutable = godotExecutable;
    this.#runner = runner;
    this.#publisher = publisher;
  }

  async approve(submission: SubmissionRecord): Promise<ApprovalResult> {
    if (!submission.artworkPath) throw new Error("Submission has no normalized artwork");
    const schema = await this.#schemas.refresh();
    if (schema.schema_version !== submission.schemaVersion) {
      return {
        kind: "needs_revision",
        reason: "The card form changed after this submission was created. Please submit it again.",
      };
    }
    const workDirectory = resolve(this.#checkout.path, ".card-bot");
    const inputPath = resolve(workDirectory, `${submission.id}.json`);
    const manifestPath = resolve(workDirectory, `${submission.id}-manifest.json`);
    await mkdir(workDirectory, { recursive: true });
    await writeFile(inputPath, `${JSON.stringify(authoringPayload(schema, submission), null, 2)}\n`);

    await this.#runImport();
    let commandError: unknown;
    try {
      await this.#runner.run(this.#godotExecutable, [
        "--headless",
        "--path",
        this.#checkout.path,
        "--script",
        "res://tools/card_authoring/create_card.gd",
        "--",
        "--input",
        inputPath,
        "--output",
        manifestPath,
      ], this.#checkout.path);
    } catch (error) {
      commandError = error;
    }
    const manifest = await readManifest(manifestPath, commandError);
    if (!manifest.ok) {
      throw new Error(manifest.validation_errors?.join("\n") || "Godot rejected the card submission");
    }
    await this.#runImport();
    await this.#runner.run(this.#godotExecutable, [
      "--headless",
      "--path",
      this.#checkout.path,
      "--script",
      "res://tests/test_runner.gd",
    ], this.#checkout.path);
    const files = await collectGeneratedFiles(this.#checkout.path, manifest);
    const pullRequest = await this.#publisher.publish(schema, submission, files);
    return { kind: "approved", pullRequest };
  }

  async #runImport(): Promise<void> {
    await this.#runner.run(this.#godotExecutable, [
      "--headless",
      "--import",
      "--path",
      this.#checkout.path,
    ], this.#checkout.path);
  }
}

function authoringPayload(schema: CardSchema, submission: SubmissionRecord) {
  return {
    schema_version: schema.schema_version,
    card: submission.payload.card,
    style_id: submission.payload.style_id,
    effect: submission.payload.effect ?? {},
    artwork_path: submission.artworkPath,
  };
}

async function readManifest(path: string, commandError: unknown): Promise<CardManifest> {
  try {
    return JSON.parse(await readFile(path, "utf8")) as CardManifest;
  } catch (manifestError) {
    if (commandError instanceof Error) throw commandError;
    throw new Error("Godot did not write a readable card manifest", { cause: manifestError });
  }
}

async function collectGeneratedFiles(checkoutPath: string, manifest: CardManifest): Promise<GeneratedFile[]> {
  const paths = new Set(manifest.generated_files ?? []);
  if (manifest.expected_import_path) {
    const expectedPath = resourcePath(checkoutPath, manifest.expected_import_path);
    try {
      await access(expectedPath.absolute);
      paths.add(manifest.expected_import_path);
    } catch {
      throw new Error(`Godot did not import generated artwork: ${manifest.expected_import_path}`);
    }
  }
  return Promise.all([...paths].map(async (path) => {
    const resolved = resourcePath(checkoutPath, path);
    return { path: resolved.relative, content: await readFile(resolved.absolute) };
  }));
}

function resourcePath(checkoutPath: string, resourcePathValue: string): { absolute: string; relative: string } {
  if (!resourcePathValue.startsWith("res://")) {
    throw new Error(`Generated manifest contains a non-resource path: ${resourcePathValue}`);
  }
  const relativePath = resourcePathValue.slice("res://".length).replaceAll("/", sep);
  const absolutePath = resolve(checkoutPath, relativePath);
  const checkedRelative = relative(resolve(checkoutPath), absolutePath);
  if (!checkedRelative || checkedRelative.startsWith(`..${sep}`) || checkedRelative === ".." || isAbsolute(checkedRelative)) {
    throw new Error(`Generated manifest path escapes the checkout: ${resourcePathValue}`);
  }
  return { absolute: absolutePath, relative: checkedRelative.replaceAll(sep, "/") };
}
