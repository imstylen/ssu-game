import type { CardSchema, FieldSchema } from "./schema.js";
import { applicableEffects, fieldIsVisible } from "./schema.js";
import type { CardSubmissionPayload } from "./submission.js";

export const MAX_MODAL_COMPONENTS = 5;

export interface FormStep {
  id: string;
  title: string;
  fields: FieldSchema[];
  includeStyle: boolean;
  includeEffect: boolean;
}

function chunkFields(id: string, title: string, fields: FieldSchema[]): FormStep[] {
  const steps: FormStep[] = [];
  for (let index = 0; index < fields.length; index += MAX_MODAL_COMPONENTS) {
    steps.push({
      id: `${id}-${steps.length + 1}`,
      title: steps.length === 0 ? title : `${title} ${steps.length + 1}`,
      fields: fields.slice(index, index + MAX_MODAL_COMPONENTS),
      includeStyle: false,
      includeEffect: false,
    });
  }
  return steps;
}

export function buildFormPlan(schema: CardSchema, payload: CardSubmissionPayload): FormStep[] {
  const visibleFields = schema.fields.filter(
    (field) => field.submitter_editable && fieldIsVisible(field, payload.card),
  );
  const basics = visibleFields.filter((field) => field.type === "string" || field.type === "enum");
  const statistics = visibleFields.filter((field) => !basics.includes(field));
  const steps = chunkFields("card", "Card Details", basics);
  if (steps.length === 0) {
    steps.push({ id: "card-1", title: "Card Details", fields: [], includeStyle: false, includeEffect: false });
  }
  steps[0]!.includeStyle = true;
  steps.push(...chunkFields("stats", "Card Stats", statistics));

  const cardTypeField = schema.fields.find(
    (field) => field.type === "enum"
      && field.options?.length === schema.card_types.length
      && field.options.every((option, index) => option.value === schema.card_types[index]?.value),
  );
  const selectedCardType = cardTypeField ? payload.card[cardTypeField.id] : undefined;
  const cardType = schema.card_types.find((option) => selectedCardType === option.value)?.value;
  if (typeof cardType === "number" && applicableEffects(schema, cardType).length > 0) {
    const effectStep: FormStep = {
      id: "effect-choice",
      title: "Card Effect",
      fields: [],
      includeStyle: false,
      includeEffect: true,
    };
    steps.push(effectStep);
    const selected = schema.effects.find((effect) => effect.id === payload.effect?.id);
    if (selected) steps.push(...chunkFields("effect", selected.display_name, selected.fields));
  }
  return steps;
}
