import type { CardSchema, EffectSchema, FieldSchema, StyleSchema } from "./schema.js";
import { applicableEffects, fieldIsVisible } from "./schema.js";
import type { CardSubmissionPayload } from "./submission.js";

export type ConversationStep =
  | { id: string; kind: "field"; scope: "card" | "effect"; field: FieldSchema }
  | { id: "style"; kind: "style"; styles: StyleSchema[] }
  | { id: "effect-choice"; kind: "effect"; effects: EffectSchema[] }
  | { id: "credit"; kind: "credit" }
  | { id: "consent"; kind: "consent" }
  | { id: "artwork"; kind: "artwork" }
  | { id: "ready"; kind: "ready" };

export function buildConversationPlan(
  schema: CardSchema,
  payload: CardSubmissionPayload,
): ConversationStep[] {
  const steps: ConversationStep[] = schema.fields
    .filter((field) => field.submitter_editable && fieldIsVisible(field, payload.card))
    .map((field) => ({ id: `card.${field.id}`, kind: "field", scope: "card", field }));

  if (schema.styles.length > 0) {
    steps.push({ id: "style", kind: "style", styles: schema.styles });
  }

  const cardType = selectedCardType(schema, payload);
  const effects = cardType === null ? [] : applicableEffects(schema, cardType);
  if (effects.length > 0) {
    steps.push({ id: "effect-choice", kind: "effect", effects });
    const effect = effects.find((candidate) => candidate.id === payload.effect?.id);
    if (effect) {
      steps.push(...effect.fields
        .filter((field) => field.submitter_editable && fieldIsVisible(field, payload.effect?.parameters ?? {}))
        .map((field): ConversationStep => ({
          id: `effect.${field.id}`,
          kind: "field",
          scope: "effect",
          field,
        })));
    }
  }

  steps.push(
    { id: "credit", kind: "credit" },
    { id: "consent", kind: "consent" },
    { id: "artwork", kind: "artwork" },
    { id: "ready", kind: "ready" },
  );
  return steps;
}

export function conversationStep(
  schema: CardSchema,
  payload: CardSubmissionPayload,
  stage: string,
): ConversationStep {
  const step = buildConversationPlan(schema, payload).find((candidate) => candidate.id === stage);
  if (!step) throw new Error("This card question is no longer available. Start a new card submission");
  return step;
}

export function nextConversationStep(
  schema: CardSchema,
  payload: CardSubmissionPayload,
  completedStage: string,
  hasArtwork: boolean,
): ConversationStep {
  const plan = buildConversationPlan(schema, payload);
  const index = plan.findIndex((candidate) => candidate.id === completedStage);
  if (index < 0) throw new Error("The completed card question is no longer in the schema");
  const next = plan.slice(index + 1).find((candidate) => candidate.kind !== "artwork" || !hasArtwork);
  if (!next) throw new Error("The card conversation ended without a review step");
  return next;
}

export function applyTextAnswer(
  payload: CardSubmissionPayload,
  step: ConversationStep,
  rawAnswer: string,
): CardSubmissionPayload {
  const next = clonePayload(payload);
  if (step.kind === "credit") {
    const answer = rawAnswer.trim();
    if (answer.toLowerCase() === "skip" || answer.length === 0) delete next.credit_name;
    else {
      if (answer.length > 100) throw new Error("Credit name must be 100 characters or fewer");
      next.credit_name = answer;
    }
    return next;
  }
  if (step.kind !== "field") throw new Error("Use the choices on the bot's current question");
  if (step.field.type === "enum" || step.field.type === "boolean") {
    throw new Error(`Choose ${step.field.label} from the menu`);
  }
  const value = parseFieldText(step.field, rawAnswer);
  const target = step.scope === "card" ? next.card : next.effect?.parameters;
  if (!target) throw new Error("Choose a card effect before entering its details");
  if (value === undefined) delete target[step.field.id];
  else target[step.field.id] = value;
  return next;
}

export function applySelectionAnswer(
  payload: CardSubmissionPayload,
  step: ConversationStep,
  selectedId: string,
): CardSubmissionPayload {
  const next = clonePayload(payload);
  if (step.kind === "field") {
    if (step.field.type !== "enum" && step.field.type !== "boolean") {
      throw new Error(`Reply to the thread with ${step.field.label}`);
    }
    const option = step.field.options?.find((candidate) => candidate.id === selectedId);
    if (!option) throw new Error(`Choose a valid ${step.field.label}`);
    const target = step.scope === "card" ? next.card : next.effect?.parameters;
    if (!target) throw new Error("Choose a card effect before entering its details");
    target[step.field.id] = option.value;
    return next;
  }
  if (step.kind === "style") {
    if (!step.styles.some((style) => style.id === selectedId)) throw new Error("Choose a valid visual style");
    next.style_id = selectedId;
    return next;
  }
  if (step.kind === "effect") {
    if (!step.effects.some((effect) => effect.id === selectedId)) throw new Error("Choose a valid card effect");
    next.effect = { id: selectedId, parameters: {} };
    return next;
  }
  if (step.kind === "consent") {
    if (selectedId !== "confirmed") throw new Error("Artwork permission must be confirmed");
    next.consent_confirmed = true;
    return next;
  }
  throw new Error("Reply to the thread for the bot's current question");
}

function selectedCardType(schema: CardSchema, payload: CardSubmissionPayload): number | null {
  const field = schema.fields.find((candidate) =>
    candidate.type === "enum"
    && candidate.options?.length === schema.card_types.length
    && candidate.options.every((option, index) => option.value === schema.card_types[index]?.value));
  const value = field ? payload.card[field.id] : undefined;
  return typeof value === "number" ? value : null;
}

function parseFieldText(field: FieldSchema, rawAnswer: string): unknown {
  const answer = rawAnswer.trim();
  if (answer.toLowerCase() === "skip") {
    if (field.required) throw new Error(`${field.label} is required`);
    return field.default ?? undefined;
  }
  if (answer.toLowerCase() === "default") {
    if (field.default === undefined || field.default === null) throw new Error(`${field.label} has no default value`);
    return field.default;
  }
  if (field.required && answer.length === 0) throw new Error(`${field.label} is required`);
  if (field.type === "string") {
    if (field.max_length !== undefined && answer.length > field.max_length) {
      throw new Error(`${field.label} must be ${field.max_length} characters or fewer`);
    }
    return answer || undefined;
  }
  const value = Number(answer);
  if (!Number.isSafeInteger(value)) throw new Error(`${field.label} must be a whole number`);
  if (field.minimum !== undefined && value < field.minimum) {
    throw new Error(`${field.label} must be at least ${field.minimum}`);
  }
  if (field.maximum !== undefined && value > field.maximum) {
    throw new Error(`${field.label} must be no more than ${field.maximum}`);
  }
  return value;
}

function clonePayload(payload: CardSubmissionPayload): CardSubmissionPayload {
  return {
    ...payload,
    card: { ...payload.card },
    ...(payload.effect ? { effect: { ...payload.effect, parameters: { ...payload.effect.parameters } } } : {}),
  };
}
