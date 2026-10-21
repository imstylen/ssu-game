import { DatabaseSync } from "node:sqlite";
import type {
  CardSubmissionPayload,
  SubmissionRecord,
  SubmissionStatus,
} from "../domain/submission.js";

interface CreateDraftInput {
  id: string;
  guildId: string;
  submitterId: string;
  schemaVersion: string;
  stage?: string;
  threadId?: string;
}

export class SubmissionRepository {
  readonly #database: DatabaseSync;

  constructor(path: string) {
    this.#database = new DatabaseSync(path);
    this.#database.exec("PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON;");
    this.#migrate();
  }

  close(): void {
    this.#database.close();
  }

  createDraft(input: CreateDraftInput): SubmissionRecord {
    const now = new Date().toISOString();
    this.#database
      .prepare(`
        INSERT INTO submissions (
          id, guild_id, submitter_id, schema_version, status, stage,
          thread_id, payload_json, created_at, updated_at
        ) VALUES (?, ?, ?, ?, 'draft', ?, ?, '{"card":{}}', ?, ?)
      `)
      .run(
        input.id,
        input.guildId,
        input.submitterId,
        input.schemaVersion,
        input.stage ?? "card-1",
        input.threadId ?? null,
        now,
        now,
      );
    return this.getRequired(input.id);
  }

  get(id: string): SubmissionRecord | null {
    const row = this.#database.prepare("SELECT * FROM submissions WHERE id = ?").get(id);
    return row ? mapRow(row as unknown as DatabaseRow) : null;
  }

  getRequired(id: string): SubmissionRecord {
    const submission = this.get(id);
    if (!submission) throw new Error(`Submission not found: ${id}`);
    return submission;
  }

  findDraftBySubmitter(guildId: string, submitterId: string): SubmissionRecord | null {
    const row = this.#database.prepare(`
      SELECT * FROM submissions
      WHERE guild_id = ? AND submitter_id = ? AND status = 'draft' AND thread_id IS NOT NULL
      ORDER BY created_at DESC LIMIT 1
    `).get(guildId, submitterId);
    return row ? mapRow(row as unknown as DatabaseRow) : null;
  }

  findByThread(threadId: string): SubmissionRecord | null {
    const row = this.#database.prepare("SELECT * FROM submissions WHERE thread_id = ? ORDER BY created_at DESC LIMIT 1").get(threadId);
    return row ? mapRow(row as unknown as DatabaseRow) : null;
  }

  saveProgress(id: string, payload: CardSubmissionPayload, stage: string): SubmissionRecord {
    this.#database
      .prepare("UPDATE submissions SET payload_json = ?, stage = ?, updated_at = ? WHERE id = ? AND status = 'draft'")
      .run(JSON.stringify(payload), stage, new Date().toISOString(), id);
    return this.getRequired(id);
  }

  saveArtwork(id: string, artworkPath: string): SubmissionRecord {
    const result = this.#database
      .prepare("UPDATE submissions SET artwork_path = ?, updated_at = ? WHERE id = ? AND status = 'draft'")
      .run(artworkPath, new Date().toISOString(), id);
    if (result.changes !== 1) throw new Error("This submission no longer accepts artwork");
    return this.getRequired(id);
  }

  queueForReview(id: string, artworkPath?: string): SubmissionRecord {
    const suppliedArtwork = artworkPath ?? null;
    const result = this.#database
      .prepare(`
        UPDATE submissions
        SET artwork_path = COALESCE(?, artwork_path), status = 'pending', stage = 'review', updated_at = ?
        WHERE id = ? AND status = 'draft' AND COALESCE(?, artwork_path) IS NOT NULL
      `)
      .run(suppliedArtwork, new Date().toISOString(), id, suppliedArtwork);
    if (result.changes !== 1) throw new Error("This submission is not ready for review");
    return this.getRequired(id);
  }

  restoreDraftAfterReviewFailure(id: string): void {
    this.#database
      .prepare("UPDATE submissions SET status = 'draft', stage = 'ready', updated_at = ? WHERE id = ? AND status = 'pending' AND review_message_id IS NULL")
      .run(new Date().toISOString(), id);
  }

  cancel(id: string, submitterId: string): boolean {
    const result = this.#database
      .prepare("UPDATE submissions SET status = 'cancelled', stage = 'cancelled', updated_at = ? WHERE id = ? AND submitter_id = ? AND status = 'draft'")
      .run(new Date().toISOString(), id, submitterId);
    return result.changes === 1;
  }

  attachReviewMessage(id: string, channelId: string, messageId: string): void {
    this.#database
      .prepare("UPDATE submissions SET review_channel_id = ?, review_message_id = ?, updated_at = ? WHERE id = ?")
      .run(channelId, messageId, new Date().toISOString(), id);
  }

  claimForApproval(id: string, moderatorId: string): boolean {
    const result = this.#database
      .prepare("UPDATE submissions SET status = 'processing', moderator_id = ?, updated_at = ? WHERE id = ? AND status IN ('pending', 'failed')")
      .run(moderatorId, new Date().toISOString(), id);
    return result.changes === 1;
  }

  markApproved(id: string, pullRequestUrl: string, pullRequestNumber: number): void {
    this.#finish(id, "approved", { pullRequestUrl, pullRequestNumber });
  }

  markFailed(id: string, reason: string): void {
    this.#finish(id, "failed", { reason });
  }

  markNeedsRevision(id: string, reason: string): void {
    this.#finish(id, "needs_revision", { reason });
  }

  deny(id: string, moderatorId: string, reason: string): boolean {
    const result = this.#database
      .prepare("UPDATE submissions SET status = 'denied', moderator_id = ?, decision_reason = ?, updated_at = ? WHERE id = ? AND status = 'pending'")
      .run(moderatorId, reason, new Date().toISOString(), id);
    return result.changes === 1;
  }

  getMetadata(key: string): string | null {
    const row = this.#database.prepare("SELECT value FROM metadata WHERE key = ?").get(key) as
      | { value: string }
      | undefined;
    return row?.value ?? null;
  }

  setMetadata(key: string, value: string): void {
    this.#database
      .prepare("INSERT INTO metadata (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value")
      .run(key, value);
  }

  #finish(
    id: string,
    status: Extract<SubmissionStatus, "approved" | "failed" | "needs_revision">,
    values: { pullRequestUrl?: string; pullRequestNumber?: number; reason?: string },
  ): void {
    this.#database
      .prepare(`
        UPDATE submissions
        SET status = ?, pull_request_url = ?, pull_request_number = ?, decision_reason = ?, updated_at = ?
        WHERE id = ? AND status = 'processing'
      `)
      .run(
        status,
        values.pullRequestUrl ?? null,
        values.pullRequestNumber ?? null,
        values.reason ?? null,
        new Date().toISOString(),
        id,
      );
  }

  #migrate(): void {
    this.#database.exec(`
      CREATE TABLE IF NOT EXISTS metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      ) STRICT;

      CREATE TABLE IF NOT EXISTS submissions (
        id TEXT PRIMARY KEY,
        guild_id TEXT NOT NULL,
        submitter_id TEXT NOT NULL,
        schema_version TEXT NOT NULL,
        status TEXT NOT NULL,
        stage TEXT NOT NULL,
        thread_id TEXT,
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
    const columns = this.#database.prepare("PRAGMA table_info(submissions)").all() as unknown as Array<{ name: string }>;
    if (!columns.some((column) => column.name === "thread_id")) {
      this.#database.exec("ALTER TABLE submissions ADD COLUMN thread_id TEXT;");
    }
    this.#database.exec("CREATE UNIQUE INDEX IF NOT EXISTS submissions_thread_id ON submissions(thread_id) WHERE thread_id IS NOT NULL;");
  }
}

interface DatabaseRow {
  id: string;
  guild_id: string;
  submitter_id: string;
  schema_version: string;
  status: SubmissionStatus;
  stage: string;
  thread_id: string | null;
  payload_json: string;
  artwork_path: string | null;
  review_channel_id: string | null;
  review_message_id: string | null;
  moderator_id: string | null;
  decision_reason: string | null;
  pull_request_url: string | null;
  pull_request_number: number | null;
  created_at: string;
  updated_at: string;
}

function mapRow(row: DatabaseRow): SubmissionRecord {
  const payload = normalizedPayload(row.payload_json);
  return {
    id: row.id,
    guildId: row.guild_id,
    submitterId: row.submitter_id,
    schemaVersion: row.schema_version,
    status: row.status,
    stage: row.stage,
    threadId: row.thread_id,
    payload,
    artworkPath: row.artwork_path,
    reviewChannelId: row.review_channel_id,
    reviewMessageId: row.review_message_id,
    moderatorId: row.moderator_id,
    decisionReason: row.decision_reason,
    pullRequestUrl: row.pull_request_url,
    pullRequestNumber: row.pull_request_number,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function normalizedPayload(json: string): CardSubmissionPayload {
  const parsed: unknown = JSON.parse(json);
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return { card: {} };
  const values = parsed as Record<string, unknown>;
  const card = values.card;
  return {
    ...values,
    card: card && typeof card === "object" && !Array.isArray(card)
      ? card as Record<string, unknown>
      : {},
  } as CardSubmissionPayload;
}
