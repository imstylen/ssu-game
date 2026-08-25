export type SubmissionStatus =
  | "draft"
  | "pending"
  | "processing"
  | "approved"
  | "denied"
  | "cancelled"
  | "failed"
  | "needs_revision";

export interface CardSubmissionPayload {
  card: Record<string, unknown>;
  style_id?: string;
  effect?: {
    id: string;
    parameters: Record<string, unknown>;
  };
  credit_name?: string;
  consent_confirmed?: boolean;
}

export interface SubmissionRecord {
  id: string;
  guildId: string;
  submitterId: string;
  schemaVersion: string;
  status: SubmissionStatus;
  stage: string;
  threadId: string | null;
  payload: CardSubmissionPayload;
  artworkPath: string | null;
  reviewChannelId: string | null;
  reviewMessageId: string | null;
  moderatorId: string | null;
  decisionReason: string | null;
  pullRequestUrl: string | null;
  pullRequestNumber: number | null;
  createdAt: string;
  updatedAt: string;
}
