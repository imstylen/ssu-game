import type { CardSchema } from "../domain/schema.js";
import type { SubmissionRecord } from "../domain/submission.js";
import { reviewLines } from "../discord/review-message.js";

export function buildPullRequestBody(schema: CardSchema, submission: SubmissionRecord): string {
  return [
    "## Community card submission",
    "",
    ...reviewLines(schema, submission),
    "",
    `- Discord submission: \`${submission.id}\``,
    `- Submitter: <@${submission.submitterId}>`,
    `- Schema version: \`${submission.schemaVersion}\``,
    "- Generated and validated by the Godot card-authoring service.",
    "",
    "This PR is intentionally a draft so maintainers can review the generated resource and artwork.",
  ].join("\n");
}
