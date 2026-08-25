import {
  ButtonBuilder,
  ButtonStyle,
  LabelBuilder,
  ModalBuilder,
  StringSelectMenuBuilder,
  TextInputBuilder,
  TextInputStyle,
  type ModalSubmitFields,
} from "discord.js";
import type { CardSchema, FieldSchema, SchemaOption } from "../domain/schema.js";
import { applicableEffects } from "../domain/schema.js";
import type { FormStep } from "../domain/form-plan.js";
import type { CardSubmissionPayload } from "../domain/submission.js";
import { CustomIds } from "./custom-ids.js";

const STYLE_COMPONENT_ID = "choice:style";
const EFFECT_COMPONENT_ID = "choice:effect";
const CREDIT_COMPONENT_ID = "contribution:credit";
const CONSENT_COMPONENT_ID = "contribution:consent";

function truncate(value: string, maximum: number): string {
  return value.length <= maximum ? value : `${value.slice(0, maximum - 1)}…`;
}

function fieldComponentId(fieldId: string): string {
  const id = `field:${fieldId}`;
  if (id.length > 100) throw new Error(`Schema field ID is too long for Discord: ${fieldId}`);
  return id;
}

function selectedCardType(schema: CardSchema, payload: CardSubmissionPayload): number | null {
  const field = schema.fields.find((candidate) =>
    candidate.type === "enum"
    && candidate.options?.length === schema.card_types.length
    && candidate.options.every((option, index) => option.value === schema.card_types[index]?.value));
  const value = field ? payload.card[field.id] : undefined;
  return typeof value === "number" ? value : null;
}

function optionData(option: SchemaOption, selected: unknown) {
  return {
    label: truncate(option.label, 100),
    value: option.id,
    default: option.value === selected,
  };
}

function selectLabel(
  id: string,
  label: string,
  description: string,
  options: SchemaOption[],
  selected: unknown,
): LabelBuilder {
  if (options.length === 0 || options.length > 25) {
    throw new Error(`${label} must expose between 1 and 25 Discord options`);
  }
  const select = new StringSelectMenuBuilder()
    .setCustomId(id)
    .setMinValues(1)
    .setMaxValues(1)
    .addOptions(options.map((option) => optionData(option, selected)));
  const result = new LabelBuilder().setLabel(truncate(label, 45)).setStringSelectMenuComponent(select);
  if (description) result.setDescription(truncate(description, 100));
  return result;
}

function textLabel(field: FieldSchema, value: unknown): LabelBuilder {
  const input = new TextInputBuilder()
    .setCustomId(fieldComponentId(field.id))
    .setStyle(field.component === "paragraph" ? TextInputStyle.Paragraph : TextInputStyle.Short)
    .setRequired(field.required);
  if (field.type === "string" && field.max_length) input.setMaxLength(Math.min(field.max_length, 4000));
  const existing = value ?? field.default;
  if (existing !== undefined && existing !== null && String(existing).length > 0) {
    input.setValue(truncate(String(existing), 4000));
  }
  if (field.type === "integer") {
    const range = [field.minimum, field.maximum].filter((part) => part !== undefined).join("–");
    if (range) input.setPlaceholder(range);
  }
  const result = new LabelBuilder()
    .setLabel(truncate(field.label, 45))
    .setTextInputComponent(input);
  if (field.description) result.setDescription(truncate(field.description, 100));
  return result;
}

function fieldLabel(field: FieldSchema, value: unknown): LabelBuilder {
  if (field.type === "enum" || field.type === "boolean") {
    return selectLabel(
      fieldComponentId(field.id),
      field.label,
      field.description,
      field.options ?? [],
      value ?? field.default,
    );
  }
  return textLabel(field, value);
}

export function buildStepModal(
  schema: CardSchema,
  submissionId: string,
  payload: CardSubmissionPayload,
  step: FormStep,
): ModalBuilder {
  const modal = new ModalBuilder()
    .setCustomId(CustomIds.step(submissionId, step.id))
    .setTitle(truncate(step.title, 45));
  const labels = step.fields.map((field) => fieldLabel(field, payload.card[field.id]));
  if (step.includeStyle) {
    labels.push(selectLabel(
      STYLE_COMPONENT_ID,
      "Visual Style",
      "Choose the card frame and typography.",
      schema.styles.map((style) => ({ id: style.id, label: style.display_name, value: style.id })),
      payload.style_id,
    ));
  }
  if (step.includeEffect) {
    const cardType = selectedCardType(schema, payload);
    const effects = cardType === null ? [] : applicableEffects(schema, cardType);
    labels.push(selectLabel(
      EFFECT_COMPONENT_ID,
      "Card Effect",
      "Choose the behavior this card performs.",
      effects.map((effect) => ({ id: effect.id, label: effect.display_name, value: effect.id })),
      payload.effect?.id,
    ));
  }
  if (labels.length === 0 || labels.length > 5) {
    throw new Error(`Form step ${step.id} has ${labels.length} Discord components`);
  }
  return modal.addLabelComponents(labels);
}

function parseOption(field: FieldSchema, fields: ModalSubmitFields): unknown {
  const selected = fields.getStringSelectValues(fieldComponentId(field.id))[0];
  const option = field.options?.find((candidate) => candidate.id === selected);
  if (!option) throw new Error(`Choose a valid ${field.label}`);
  return option.value;
}

function parseField(field: FieldSchema, fields: ModalSubmitFields): unknown {
  if (field.type === "enum" || field.type === "boolean") return parseOption(field, fields);
  const raw = fields.getTextInputValue(fieldComponentId(field.id)).trim();
  if (field.required && raw.length === 0) throw new Error(`${field.label} is required`);
  if (field.type === "string") return raw;
  const value = Number(raw);
  if (!Number.isSafeInteger(value)) throw new Error(`${field.label} must be a whole number`);
  if (field.minimum !== undefined && value < field.minimum) {
    throw new Error(`${field.label} must be at least ${field.minimum}`);
  }
  if (field.maximum !== undefined && value > field.maximum) {
    throw new Error(`${field.label} must be no more than ${field.maximum}`);
  }
  return value;
}

export function applyStepFields(
  schema: CardSchema,
  payload: CardSubmissionPayload,
  step: FormStep,
  fields: ModalSubmitFields,
): CardSubmissionPayload {
  const next: CardSubmissionPayload = {
    ...payload,
    card: { ...payload.card },
    ...(payload.effect ? { effect: { ...payload.effect, parameters: { ...payload.effect.parameters } } } : {}),
  };
  for (const field of step.fields) {
    const value = parseField(field, fields);
    if (step.id.startsWith("effect-")) {
      if (!next.effect) throw new Error("Choose an effect before entering its parameters");
      next.effect.parameters[field.id] = value;
    } else {
      next.card[field.id] = value;
    }
  }
  if (step.includeStyle) {
    const selected = fields.getStringSelectValues(STYLE_COMPONENT_ID)[0];
    if (!selected || !schema.styles.some((style) => style.id === selected)) {
      throw new Error("Choose a valid visual style");
    }
    next.style_id = selected;
  }
  if (step.includeEffect) {
    const selected = fields.getStringSelectValues(EFFECT_COMPONENT_ID)[0];
    const cardType = selectedCardType(schema, next);
    const available = cardType === null ? [] : applicableEffects(schema, cardType);
    if (!selected || !available.some((effect) => effect.id === selected)) {
      throw new Error("Choose a valid card effect");
    }
    next.effect = { id: selected, parameters: {} };
  }
  return next;
}

export function buildContinueButton(submissionId: string, stage: string): ButtonBuilder {
  return new ButtonBuilder()
    .setCustomId(CustomIds.continue(submissionId, stage))
    .setLabel(stage === "contribution" ? "Finish details" : "Continue")
    .setStyle(ButtonStyle.Primary);
}

export function buildContributionModal(submissionId: string, payload: CardSubmissionPayload): ModalBuilder {
  const credit = new TextInputBuilder()
    .setCustomId(CREDIT_COMPONENT_ID)
    .setStyle(TextInputStyle.Short)
    .setRequired(false)
    .setMaxLength(100);
  if (payload.credit_name) credit.setValue(payload.credit_name);
  const consent = new StringSelectMenuBuilder()
    .setCustomId(CONSENT_COMPONENT_ID)
    .setMinValues(1)
    .setMaxValues(1)
    .addOptions({ label: "Yes, I can submit this artwork", value: "confirmed" });
  return new ModalBuilder()
    .setCustomId(CustomIds.step(submissionId, "contribution"))
    .setTitle("Contribution details")
    .addLabelComponents(
      new LabelBuilder()
        .setLabel("Credit name (optional)")
        .setDescription("Name shown in the draft PR.")
        .setTextInputComponent(credit),
      new LabelBuilder()
        .setLabel("Artwork permission")
        .setDescription("Confirm you have permission to submit the image.")
        .setStringSelectMenuComponent(consent),
    );
}

export function applyContributionFields(
  payload: CardSubmissionPayload,
  fields: ModalSubmitFields,
): CardSubmissionPayload {
  const creditName = fields.getTextInputValue(CREDIT_COMPONENT_ID).trim();
  const consent = fields.getStringSelectValues(CONSENT_COMPONENT_ID)[0] === "confirmed";
  if (!consent) throw new Error("Artwork permission must be confirmed");
  return {
    ...payload,
    ...(creditName ? { credit_name: creditName } : {}),
    consent_confirmed: true,
  };
}

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
