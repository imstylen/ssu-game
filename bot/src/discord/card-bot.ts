import { randomUUID } from "node:crypto";
import {
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  ChannelType,
  Client,
  Colors,
  EmbedBuilder,
  Events,
  MessageFlags,
  ThreadAutoArchiveDuration,
  type AnyThreadChannel,
  type ButtonInteraction,
  type ChatInputCommandInteraction,
  type Interaction,
  type Message,
  type ModalSubmitInteraction,
  type StringSelectMenuInteraction,
  type TextChannel,
} from "discord.js";
import type { ArtworkNormalizer } from "../artwork/artwork-normalizer.js";
import { MAX_ARTWORK_BYTES } from "../artwork/artwork-normalizer.js";
import type { BotConfig } from "../config.js";
import {
  applySelectionAnswer,
  applyTextAnswer,
  buildConversationPlan,
  conversationStep,
  nextConversationStep,
  type ConversationStep,
} from "../domain/conversation.js";
import type { CardSchema } from "../domain/schema.js";
import type { CardSubmissionPayload, SubmissionRecord } from "../domain/submission.js";
import type { CardApprovalService } from "../godot/card-approval-service.js";
import type { SchemaStore } from "../godot/schema-store.js";
import type { SubmissionRepository } from "../storage/submission-repository.js";
import { commandDefinitions } from "./commands.js";
import { buildConversationPrompt } from "./conversation-components.js";
import { CustomIds, parseCustomId } from "./custom-ids.js";
import { buildDenialModal, denialReason } from "./form-components.js";
import { buildReviewMessage } from "./review-message.js";

type StartInteraction = ButtonInteraction | ChatInputCommandInteraction;

export class DiscordCardBot {
  readonly #client: Client;
  readonly #config: BotConfig;
  readonly #repository: SubmissionRepository;
  readonly #schemas: SchemaStore;
  readonly #artwork: ArtworkNormalizer;
  readonly #approval: CardApprovalService;

  constructor(
    client: Client,
    config: BotConfig,
    repository: SubmissionRepository,
    schemas: SchemaStore,
    artwork: ArtworkNormalizer,
    approval: CardApprovalService,
  ) {
    this.#client = client;
    this.#config = config;
    this.#repository = repository;
    this.#schemas = schemas;
    this.#artwork = artwork;
    this.#approval = approval;
  }

  async start(): Promise<void> {
    await this.#schemas.refresh();
    this.#client.once(Events.ClientReady, async (client) => {
      await client.application.commands.set(commandDefinitions, this.#config.discordGuildId);
      await this.#publishIntakePanel();
      console.log(`Card bot ready as ${client.user.tag}`);
    });
    this.#client.on(Events.InteractionCreate, (interaction) => {
      void this.#handleInteraction(interaction);
    });
    this.#client.on(Events.MessageCreate, (message) => {
      void this.#handleMessage(message);
    });
    await this.#client.login(this.#config.discordToken);
  }

  async #handleInteraction(interaction: Interaction): Promise<void> {
    try {
      if (interaction.isChatInputCommand()) await this.#handleCommand(interaction);
      else if (interaction.isStringSelectMenu()) await this.#handleSelection(interaction);
      else if (interaction.isButton()) await this.#handleButton(interaction);
      else if (interaction.isModalSubmit()) await this.#handleModal(interaction);
    } catch (error) {
      console.error(error);
      const message = userFacingError(error);
      if (interaction.isRepliable()) {
        if (interaction.deferred || interaction.replied) await interaction.editReply({ content: message, components: [] });
        else await interaction.reply({ content: message, flags: MessageFlags.Ephemeral });
      }
    }
  }

  async #handleCommand(interaction: ChatInputCommandInteraction): Promise<void> {
    switch (interaction.commandName) {
      case "newcard":
        await this.#startConversation(interaction);
        return;
      case "card-schema-refresh": {
        this.#requireModerator(interaction);
        await interaction.deferReply({ flags: MessageFlags.Ephemeral });
        const schema = await this.#schemas.refresh();
        await interaction.editReply(`Schema refreshed: \`${schema.schema_version.slice(0, 12)}\``);
        return;
      }
      case "card-intake-refresh":
        this.#requireModerator(interaction);
        await interaction.deferReply({ flags: MessageFlags.Ephemeral });
        await this.#publishIntakePanel();
        await interaction.editReply("The card submission panel is up to date.");
        return;
      default:
        await interaction.reply({ content: "Unknown card command.", flags: MessageFlags.Ephemeral });
    }
  }

  async #startConversation(interaction: StartInteraction): Promise<void> {
    if (interaction.guildId !== this.#config.discordGuildId) {
      throw new Error("Card submissions are only available in the configured server");
    }
    await interaction.deferReply({ flags: MessageFlags.Ephemeral });

    const existing = this.#repository.findDraftBySubmitter(interaction.guildId, interaction.user.id);
    if (existing?.threadId) {
      try {
        const thread = await this.#threadChannel(existing.threadId);
        if (thread.archived) await thread.setArchived(false, "Submitter resumed their card draft");
        await interaction.editReply(`You already have a card in progress: ${thread}`);
        return;
      } catch (error) {
        console.error("Could not resume the existing card thread", error);
        this.#repository.cancel(existing.id, interaction.user.id);
      }
    }

    const schema = this.#schemas.current;
    const seed: CardSubmissionPayload = { card: {} };
    const firstStep = buildConversationPlan(schema, seed)[0];
    if (!firstStep) throw new Error("The game schema did not provide any card questions");
    const intakeChannel = await this.#textChannel(this.#config.intakeChannelId);
    const thread = await intakeChannel.threads.create({
      name: cardThreadName(interaction.user.username),
      type: ChannelType.PrivateThread,
      autoArchiveDuration: ThreadAutoArchiveDuration.OneDay,
      invitable: false,
      reason: `Card draft for ${interaction.user.tag}`,
    });

    try {
      await thread.members.add(interaction.user.id);
      const submission = this.#repository.createDraft({
        id: randomUUID(),
        guildId: interaction.guildId,
        submitterId: interaction.user.id,
        schemaVersion: schema.schema_version,
        stage: firstStep.id,
        threadId: thread.id,
      });
      await thread.send({
        content: [
          `<@${interaction.user.id}> this is your private card workspace.`,
          "Answer the current question, then I’ll ask the next one. You can attach or replace the artwork at any time.",
        ].join("\n"),
        allowedMentions: { users: [interaction.user.id] },
      });
      await thread.send(buildConversationPrompt(schema, submission, firstStep));
      await interaction.editReply(`Your private card thread is ready: ${thread}`);
    } catch (error) {
      await thread.setArchived(true, "Card draft setup failed").catch(() => undefined);
      throw error;
    }
  }

  async #handleMessage(message: Message): Promise<void> {
    if (message.author.bot || !message.inGuild() || message.guildId !== this.#config.discordGuildId) return;
    if (!message.channel.isThread()) return;
    let submission = this.#repository.findByThread(message.channelId);
    if (!submission || submission.status !== "draft" || submission.submitterId !== message.author.id) return;

    try {
      const schema = this.#schemaFor(submission);
      let artworkSaved = false;
      if (message.attachments.size > 0) {
        submission = await this.#saveArtwork(message, submission);
        artworkSaved = true;
      }

      const step = conversationStep(schema, submission.payload, submission.stage);
      const answer = message.content.trim();
      if (acceptsText(step) && answer.length > 0) {
        const payload = applyTextAnswer(submission.payload, step, answer);
        if (artworkSaved) await message.channel.send("Artwork saved.");
        await this.#advanceConversation(message.channel, schema, submission, step.id, payload, submission.artworkPath !== null);
        return;
      }
      if (step.kind === "artwork" && artworkSaved) {
        await message.channel.send("Artwork saved and normalized to 1024×1024 PNG.");
        await this.#advanceConversation(message.channel, schema, submission, step.id, submission.payload, true);
        return;
      }
      if (artworkSaved) {
        if (step.kind === "ready") await message.channel.send(buildConversationPrompt(schema, submission, step));
        else await message.reply("Artwork saved. Continue with the bot’s current question above.");
        return;
      }
      if (answer.length > 0) {
        await message.reply("Use the choice menu or buttons on the bot’s current question.");
      }
    } catch (error) {
      console.error(error);
      await message.reply(userFacingError(error));
    }
  }

  async #handleSelection(interaction: StringSelectMenuInteraction): Promise<void> {
    const customId = parseCustomId(interaction.customId);
    if (customId?.action !== "answer" || !customId.submissionId || !customId.stage) return;
    const submission = this.#repository.getRequired(customId.submissionId);
    this.#requireSubmitter(interaction, submission);
    if (submission.status !== "draft" || submission.stage !== customId.stage) {
      throw new Error("That card question is no longer active");
    }
    if (submission.threadId !== interaction.channelId) throw new Error("Use this choice inside its card thread");
    const selected = interaction.values[0];
    if (!selected) throw new Error("Choose one option");
    const schema = this.#schemaFor(submission);
    const step = conversationStep(schema, submission.payload, submission.stage);
    const payload = applySelectionAnswer(submission.payload, step, selected);
    const next = nextConversationStep(schema, payload, step.id, submission.artworkPath !== null);
    const updated = this.#repository.saveProgress(submission.id, payload, next.id);
    await interaction.update({ components: [] });
    const thread = await this.#threadChannel(interaction.channelId);
    await thread.send(buildConversationPrompt(schema, updated, next));
  }

  async #handleButton(interaction: ButtonInteraction): Promise<void> {
    const customId = parseCustomId(interaction.customId);
    if (!customId) return;
    if (customId.action === "start") {
      await this.#startConversation(interaction);
      return;
    }
    if (!customId.submissionId) throw new Error("Invalid submission action");
    const submission = this.#repository.getRequired(customId.submissionId);
    if (customId.action === "submit") {
      await this.#submitForReview(interaction, submission);
      return;
    }
    if (customId.action === "cancel") {
      this.#requireSubmitter(interaction, submission);
      if (!this.#repository.cancel(submission.id, interaction.user.id)) throw new Error("This draft can no longer be cancelled");
      await interaction.update({ content: "Card draft cancelled.", embeds: [], components: [], attachments: [] });
      const thread = await this.#threadChannel(interaction.channelId);
      await thread.setArchived(true, "Submitter cancelled card draft");
      return;
    }

    this.#requireModerator(interaction);
    if (customId.action === "deny") {
      if (submission.status !== "pending") throw new Error("This submission is no longer pending");
      await interaction.showModal(buildDenialModal(submission.id));
      return;
    }
    if (customId.action === "approve") {
      if (!this.#repository.claimForApproval(submission.id, interaction.user.id)) {
        throw new Error("Another moderator already claimed this submission");
      }
      await interaction.deferReply({ flags: MessageFlags.Ephemeral });
      try {
        const claimed = this.#repository.getRequired(submission.id);
        const result = await this.#approval.approve(claimed);
        if (result.kind === "needs_revision") {
          this.#repository.markNeedsRevision(submission.id, result.reason);
          await this.#updateReviewStatus(submission, "Needs revision", Colors.Orange);
          await this.#notifySubmitter(submission, result.reason);
          await interaction.editReply(result.reason);
          return;
        }
        this.#repository.markApproved(submission.id, result.pullRequest.url, result.pullRequest.number);
        await this.#updateReviewStatus(submission, `Approved · PR #${result.pullRequest.number}`, Colors.Green);
        await this.#notifySubmitter(submission, `Your card was approved and opened as a draft PR: ${result.pullRequest.url}`);
        await interaction.editReply(`Approved: ${result.pullRequest.url}`);
      } catch (error) {
        const message = userFacingError(error);
        this.#repository.markFailed(submission.id, message);
        await this.#updateReviewStatus(submission, "Approval failed · moderators may retry", Colors.Red);
        throw error;
      }
    }
  }

  async #submitForReview(interaction: ButtonInteraction, submission: SubmissionRecord): Promise<void> {
    this.#requireSubmitter(interaction, submission);
    if (submission.status !== "draft" || submission.stage !== "ready") throw new Error("This card is not ready to submit");
    if (submission.threadId !== interaction.channelId) throw new Error("Submit this card inside its card thread");
    if (!submission.artworkPath) throw new Error("Attach artwork before submitting this card");

    await interaction.update({ content: "Submitting to moderators…", embeds: [], components: [], attachments: [] });
    const pending = this.#repository.queueForReview(submission.id);
    try {
      const reviewChannel = await this.#textChannel(this.#config.reviewChannelId);
      const reviewMessage = await reviewChannel.send(buildReviewMessage(this.#schemaFor(pending), pending));
      this.#repository.attachReviewMessage(pending.id, reviewChannel.id, reviewMessage.id);
      await interaction.editReply("Submitted to the moderator review queue. Updates will appear in this thread.");
    } catch (error) {
      this.#repository.restoreDraftAfterReviewFailure(submission.id);
      const restored = this.#repository.getRequired(submission.id);
      await interaction.editReply(`Could not reach the review queue: ${userFacingError(error)}`);
      const thread = await this.#threadChannel(interaction.channelId);
      await thread.send(buildConversationPrompt(this.#schemaFor(restored), restored, conversationStep(this.#schemaFor(restored), restored.payload, restored.stage)));
    }
  }

  async #handleModal(interaction: ModalSubmitInteraction): Promise<void> {
    const customId = parseCustomId(interaction.customId);
    if (customId?.action !== "denial" || !customId.submissionId) return;
    const submission = this.#repository.getRequired(customId.submissionId);
    this.#requireModerator(interaction);
    const reason = denialReason(interaction.fields);
    if (!reason) throw new Error("A denial reason is required");
    if (!this.#repository.deny(submission.id, interaction.user.id, reason)) {
      throw new Error("Another moderator already decided this submission");
    }
    await this.#updateReviewStatus(submission, "Denied", Colors.Red);
    await this.#notifySubmitter(submission, `Your card submission was denied: ${reason}`);
    await interaction.reply({ content: "Submission denied.", flags: MessageFlags.Ephemeral });
  }

  async #saveArtwork(message: Message<true>, submission: SubmissionRecord): Promise<SubmissionRecord> {
    const attachment = [...message.attachments.values()].find((candidate) =>
      candidate.contentType === "image/png"
      || candidate.contentType === "image/jpeg"
      || /\.(png|jpe?g)$/i.test(candidate.name));
    if (!attachment) throw new Error("Attach a PNG or JPEG image");
    if (attachment.size > MAX_ARTWORK_BYTES) throw new Error("Artwork must be 10 MB or smaller");
    const response = await fetch(attachment.url);
    if (!response.ok) throw new Error("Discord could not provide the artwork attachment");
    const source = Buffer.from(await response.arrayBuffer());
    const artworkPath = await this.#artwork.normalize(submission.id, source);
    return this.#repository.saveArtwork(submission.id, artworkPath);
  }

  async #advanceConversation(
    thread: AnyThreadChannel,
    schema: CardSchema,
    submission: SubmissionRecord,
    completedStage: string,
    payload: CardSubmissionPayload,
    hasArtwork: boolean,
  ): Promise<void> {
    const next = nextConversationStep(schema, payload, completedStage, hasArtwork);
    const updated = this.#repository.saveProgress(submission.id, payload, next.id);
    await thread.send(buildConversationPrompt(schema, updated, next));
  }

  async #publishIntakePanel(): Promise<void> {
    const channel = await this.#textChannel(this.#config.intakeChannelId);
    const payload = {
      embeds: [new EmbedBuilder()
        .setTitle("Create a community card")
        .setDescription("Start a private thread where the bot walks you through the game’s current fields, styles, effects, and artwork.")
        .setColor(Colors.Blurple)],
      components: [new ActionRowBuilder<ButtonBuilder>().addComponents(
        new ButtonBuilder().setCustomId(CustomIds.start).setLabel("Create a card").setStyle(ButtonStyle.Primary),
      )],
    };
    const previousId = this.#repository.getMetadata("intake_message_id");
    if (previousId) {
      try {
        const previous = await channel.messages.fetch(previousId);
        await previous.edit(payload);
        return;
      } catch {
        // The stored message was deleted or the channel changed; create a replacement.
      }
    }
    const message = await channel.send(payload);
    this.#repository.setMetadata("intake_message_id", message.id);
  }

  async #updateReviewStatus(submission: SubmissionRecord, title: string, color: number): Promise<void> {
    if (!submission.reviewChannelId || !submission.reviewMessageId) return;
    try {
      const channel = await this.#textChannel(submission.reviewChannelId);
      const message = await channel.messages.fetch(submission.reviewMessageId);
      const existing = message.embeds[0];
      const embed = existing ? EmbedBuilder.from(existing).setTitle(title).setColor(color) : new EmbedBuilder().setTitle(title).setColor(color);
      await message.edit({ embeds: [embed], components: [] });
    } catch (error) {
      console.error("Could not update review message", error);
    }
  }

  async #notifySubmitter(submission: SubmissionRecord, message: string): Promise<void> {
    if (submission.threadId) {
      try {
        const thread = await this.#threadChannel(submission.threadId);
        await thread.send({
          content: `<@${submission.submitterId}> ${message}`,
          allowedMentions: { users: [submission.submitterId] },
        });
        return;
      } catch (error) {
        console.error("Could not notify card submitter in their thread", error);
      }
    }
    try {
      const user = await this.#client.users.fetch(submission.submitterId);
      await user.send(message);
    } catch (error) {
      console.error("Could not DM card submitter", error);
    }
  }

  #schemaFor(submission: SubmissionRecord): CardSchema {
    const schema = this.#schemas.get(submission.schemaVersion);
    if (!schema) throw new Error("This submission uses an unavailable card form. Please start a new submission");
    return schema;
  }

  #requireSubmitter(interaction: Interaction, submission: SubmissionRecord): void {
    if (submission.submitterId !== interaction.user.id) throw new Error("This card submission belongs to another user");
  }

  #requireModerator(interaction: Interaction): void {
    if (!this.#isModerator(interaction)) throw new Error("The moderator role is required for this action");
  }

  #isModerator(interaction: Interaction): boolean {
    return interaction.inCachedGuild() && interaction.member.roles.cache.has(this.#config.moderatorRoleId);
  }

  async #textChannel(id: string): Promise<TextChannel> {
    const channel = await this.#client.channels.fetch(id);
    if (!channel || channel.type !== ChannelType.GuildText) throw new Error(`Configured channel is not a text channel: ${id}`);
    return channel;
  }

  async #threadChannel(id: string): Promise<AnyThreadChannel> {
    const channel = await this.#client.channels.fetch(id);
    if (!channel?.isThread()) throw new Error(`Card thread is unavailable: ${id}`);
    return channel;
  }
}

function acceptsText(step: ConversationStep): boolean {
  return step.kind === "credit"
    || (step.kind === "field" && step.field.type !== "enum" && step.field.type !== "boolean");
}

function cardThreadName(username: string): string {
  const name = `card-${username}`.trim();
  return name.slice(0, 100) || "card-draft";
}

function userFacingError(error: unknown): string {
  const message = error instanceof Error ? error.message : "Unexpected card bot error";
  return message.length <= 1900 ? message : `${message.slice(0, 1899)}…`;
}
