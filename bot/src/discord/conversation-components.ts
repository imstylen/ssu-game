import {
  ActionRowBuilder,
  AttachmentBuilder,
  ButtonBuilder,
  ButtonStyle,
  EmbedBuilder,
  StringSelectMenuBuilder,
  type MessageCreateOptions,
} from "discord.js";
import type { ConversationStep } from "../domain/conversation.js";
import type { CardSchema, FieldSchema } from "../domain/schema.js";
import type { SubmissionRecord } from "../domain/submission.js";
import { CustomIds } from "./custom-ids.js";
import { reviewLines } from "./review-message.js";

export function buildConversationPrompt(
  schema: CardSchema,
  submission: SubmissionRecord,
  step: ConversationStep,
): MessageCreateOptions {
  switch (step.kind) {
    case "field":
      if (step.field.type === "enum" || step.field.type === "boolean") {
        return selectionPrompt(
          submission.id,
          step.id,
          step.field.label,
          step.field.description,
          (step.field.options ?? []).map((option) => ({ label: option.label, value: option.id })),
        );
      }
      return { content: textFieldPrompt(step.field) };
    case "style":
      return selectionPrompt(
        submission.id,
        step.id,
        "Visual Style",
        "Choose the card frame and typography.",
        step.styles.map((style) => ({ label: style.display_name, value: style.id })),
      );
    case "effect":
      return selectionPrompt(
        submission.id,
        step.id,
        "Card Effect",
        "Choose what happens when this card is played.",
        step.effects.map((effect) => ({
          label: effect.display_name,
          value: effect.id,
          description: effect.description,
        })),
      );
    case "credit":
      return { content: "**Credit name (optional)**\nWho should be credited in the pull request? Reply with a name, or `skip`." };
    case "consent":
      return selectionPrompt(
        submission.id,
        step.id,
        "Artwork permission",
        "Confirm that you have permission to submit the attached image.",
        [{ label: "I confirm", value: "confirmed" }],
      );
    case "artwork":
      return { content: "**Artwork**\nAttach a PNG or JPEG to your next message (up to 10 MB)." };
    case "ready":
      return readyPrompt(schema, submission);
  }
}

function textFieldPrompt(field: FieldSchema): string {
  const details = [field.description];
  if (field.type === "integer") {
    const limits = [
      field.minimum === undefined ? null : `minimum ${field.minimum}`,
      field.maximum === undefined ? null : `maximum ${field.maximum}`,
    ].filter(Boolean).join(", ");
    if (limits) details.push(`Enter a whole number (${limits}).`);
  }
  if (field.default !== undefined && field.default !== null && String(field.default).length > 0) {
    details.push(`Reply \`default\` to use ${String(field.default)}.`);
  }
  if (!field.required) details.push("Reply `skip` to leave this blank.");
  return `**${field.label}**\n${details.filter(Boolean).join("\n")}\nReply in this thread.`;
}

interface SelectOption {
  label: string;
  value: string;
  description?: string;
}

function selectionPrompt(
  submissionId: string,
  stage: string,
  label: string,
  description: string,
  options: SelectOption[],
): MessageCreateOptions {
  if (options.length === 0 || options.length > 25) {
    throw new Error(`${label} must expose between 1 and 25 Discord options`);
  }
  const menu = new StringSelectMenuBuilder()
    .setCustomId(CustomIds.answer(submissionId, stage))
    .setPlaceholder(truncate(`Choose ${label}`, 150))
    .setMinValues(1)
    .setMaxValues(1)
    .addOptions(options.map((option) => ({
      label: truncate(option.label, 100),
      value: checkedOptionValue(option.value),
      ...(option.description ? { description: truncate(option.description, 100) } : {}),
    })));
  return {
    content: `**${label}**\n${description}`,
    components: [new ActionRowBuilder<StringSelectMenuBuilder>().addComponents(menu)],
  };
}

function readyPrompt(schema: CardSchema, submission: SubmissionRecord): MessageCreateOptions {
  if (!submission.artworkPath) throw new Error("Attach artwork before submitting this card");
  const embed = new EmbedBuilder()
    .setTitle("Ready to submit?")
    .setDescription(truncate(reviewLines(schema, submission).join("\n"), 4096))
    .setImage("attachment://artwork.png")
    .setFooter({ text: "Submitting sends this card to the moderator review queue." });
  return {
    embeds: [embed],
    files: [new AttachmentBuilder(submission.artworkPath, { name: "artwork.png" })],
    components: [new ActionRowBuilder<ButtonBuilder>().addComponents(
      new ButtonBuilder()
        .setCustomId(CustomIds.submit(submission.id))
        .setLabel("Submit for review")
        .setStyle(ButtonStyle.Success),
      new ButtonBuilder()
        .setCustomId(CustomIds.cancel(submission.id))
        .setLabel("Cancel")
        .setStyle(ButtonStyle.Secondary),
    )],
  };
}

function checkedOptionValue(value: string): string {
  if (value.length === 0 || value.length > 100) throw new Error("Schema option ID is too long for Discord");
  return value;
}

function truncate(value: string, maximum: number): string {
  return value.length <= maximum ? value : `${value.slice(0, maximum - 1)}…`;
}
