import {
  ActionRowBuilder,
  AttachmentBuilder,
  ButtonBuilder,
  ButtonStyle,
  EmbedBuilder,
  type MessageCreateOptions,
} from "discord.js";
import type { CardSchema, FieldSchema } from "../domain/schema.js";
import { fieldIsVisible } from "../domain/schema.js";
import type { SubmissionRecord } from "../domain/submission.js";
import { CustomIds } from "./custom-ids.js";

function displayValue(field: FieldSchema, value: unknown): string {
  const option = field.options?.find((candidate) => candidate.value === value);
  if (option) return option.label;
  if (typeof value === "boolean") return value ? "Yes" : "No";
  return String(value ?? "—");
}

function truncate(value: string, maximum: number): string {
  return value.length <= maximum ? value : `${value.slice(0, maximum - 1)}…`;
}

export function reviewLines(schema: CardSchema, submission: SubmissionRecord): string[] {
  const lines = schema.fields
    .filter((field) => field.submitter_editable && fieldIsVisible(field, submission.payload.card))
    .map((field) => `**${field.label}:** ${displayValue(field, submission.payload.card[field.id])}`);
  const style = schema.styles.find((candidate) => candidate.id === submission.payload.style_id);
  lines.push(`**Visual Style:** ${style?.display_name ?? submission.payload.style_id ?? "—"}`);
  const effect = schema.effects.find((candidate) => candidate.id === submission.payload.effect?.id);
  if (effect) {
    lines.push(`**Effect:** ${effect.display_name}`);
    for (const field of effect.fields) {
      lines.push(`**${field.label}:** ${displayValue(field, submission.payload.effect?.parameters[field.id])}`);
    }
  }
  if (submission.payload.credit_name) lines.push(`**Credit:** ${submission.payload.credit_name}`);
  return lines;
}

export function buildReviewMessage(schema: CardSchema, submission: SubmissionRecord): MessageCreateOptions {
  if (!submission.artworkPath) throw new Error("Submission has no normalized artwork");
  const description = truncate(reviewLines(schema, submission).join("\n"), 4096);
  const embed = new EmbedBuilder()
    .setTitle("Card submission awaiting review")
    .setDescription(description)
    .setFooter({ text: `Submission ${submission.id} · schema ${submission.schemaVersion.slice(0, 12)}` })
    .setImage("attachment://artwork.png");
  const buttons = new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder()
      .setCustomId(CustomIds.approve(submission.id))
      .setLabel("Approve")
      .setStyle(ButtonStyle.Success),
    new ButtonBuilder()
      .setCustomId(CustomIds.deny(submission.id))
      .setLabel("Deny")
      .setStyle(ButtonStyle.Danger),
  );
  return {
    embeds: [embed],
    components: [buttons],
    files: [new AttachmentBuilder(submission.artworkPath, { name: "artwork.png" })],
  };
}
