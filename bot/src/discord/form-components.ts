import {
  LabelBuilder,
  ModalBuilder,
  TextInputBuilder,
  TextInputStyle,
  type ModalSubmitFields,
} from "discord.js";
import { CustomIds } from "./custom-ids.js";

export function buildDenialModal(submissionId: string): ModalBuilder {
  return new ModalBuilder()
    .setCustomId(CustomIds.denial(submissionId))
    .setTitle("Deny card submission")
    .addLabelComponents(
      new LabelBuilder()
        .setLabel("Reason")
        .setDescription("This will be shown to the submitter.")
        .setTextInputComponent(
          new TextInputBuilder()
            .setCustomId("denial:reason")
            .setStyle(TextInputStyle.Paragraph)
            .setRequired(true)
            .setMaxLength(1000),
        ),
    );
}

export function denialReason(fields: ModalSubmitFields): string {
  return fields.getTextInputValue("denial:reason").trim();
}
