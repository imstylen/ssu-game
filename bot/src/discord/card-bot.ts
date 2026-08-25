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
  type ButtonInteraction,
  type ChatInputCommandInteraction,
  type Interaction,
  type ModalSubmitInteraction,
  type TextChannel,
} from "discord.js";
import type { ArtworkNormalizer } from "../artwork/artwork-normalizer.js";
import { MAX_ARTWORK_BYTES } from "../artwork/artwork-normalizer.js";
import type { BotConfig } from "../config.js";
import { buildFormPlan } from "../domain/form-plan.js";
import type { CardSchema } from "../domain/schema.js";
import type { SubmissionRecord } from "../domain/submission.js";
import type { CardApprovalService } from "../godot/card-approval-service.js";
import type { SchemaStore } from "../godot/schema-store.js";
import type { SubmissionRepository } from "../storage/submission-repository.js";
import { commandDefinitions } from "./commands.js";
import { CustomIds, parseCustomId } from "./custom-ids.js";
import {
  applyContributionFields,
  applyStepFields,
  buildContinueButton,
  buildContributionModal,
  buildDenialModal,
  buildStepModal,
  denialReason,
} from "./form-components.js";
import { buildReviewMessage } from "./review-message.js";

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
    await this.#client.login(this.#config.discordToken);
  }

  async #handleInteraction(interaction: Interaction): Promise<void> {
    try {
      if (interaction.isChatInputCommand()) await this.#handleCommand(interaction);
      else if (interaction.isButton()) await this.#handleButton(interaction);
      else if (interaction.isModalSubmit()) await this.#handleModal(interaction);
    } catch (error) {
      console.error(error);
      const message = userFacingError(error);
      if (interaction.isRepliable()) {
        if (interaction.deferred || interaction.replied) await interaction.editReply({ content: message, components: [] });
        else await interaction.reply({ content: message, ephemeral: true });
      }
    }
  }

  async #handleCommand(interaction: ChatInputCommandInteraction): Promise<void> {
    switch (interaction.commandName) {
      case "card-artwork":
        await this.#handleArtwork(interaction);
        return;
      case "card-status":
        await this.#handleStatus(interaction);
        return;
      case "card-schema-refresh": {
        this.#requireModerator(interaction);
        await interaction.deferReply({ ephemeral: true });
        const schema = await this.#schemas.refresh();
        await interaction.editReply(`Schema refreshed: \`${schema.schema_version.slice(0, 12)}\``);
        return;
      }
      case "card-intake-refresh":
        this.#requireModerator(interaction);
        await interaction.deferReply({ ephemeral: true });
        await this.#publishIntakePanel();
        await interaction.editReply("The card submission panel is up to date.");
        return;
      default:
        await interaction.reply({ content: "Unknown card command.", ephemeral: true });
    }
  }

  async #handleButton(interaction: ButtonInteraction): Promise<void> {
    const customId = parseCustomId(interaction.customId);
    if (!customId) return;
    if (customId.action === "start") {
      if (interaction.guildId !== this.#config.discordGuildId) throw new Error("Card submissions are only available in the configured server");
      const schema = this.#schemas.current;
      const submission = this.#repository.createDraft({
        id: randomUUID(),
        guildId: interaction.guildId,
        submitterId: interaction.user.id,
        schemaVersion: schema.schema_version,
      });
      const firstStep = buildFormPlan(schema, submission.payload)[0];
      if (!firstStep) throw new Error("The game schema did not provide any card fields");
      await interaction.showModal(buildStepModal(schema, submission.id, submission.payload, firstStep));
      return;
    }
    if (!customId.submissionId) throw new Error("Invalid submission action");
    const submission = this.#repository.getRequired(customId.submissionId);
    if (customId.action === "continue") {
      this.#requireSubmitter(interaction, submission);
      if (submission.status !== "draft" || submission.stage !== customId.stage) {
        throw new Error("This form step is no longer active");
      }
      if (customId.stage === "contribution") {
        await interaction.showModal(buildContributionModal(submission.id, submission.payload));
        return;
      }
      const schema = this.#schemaFor(submission);
      const step = buildFormPlan(schema, submission.payload).find((candidate) => candidate.id === customId.stage);
      if (!step) throw new Error("This form step is no longer available");
      await interaction.showModal(buildStepModal(schema, submission.id, submission.payload, step));
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
      await interaction.deferReply({ ephemeral: true });
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

  async #handleModal(interaction: ModalSubmitInteraction): Promise<void> {
    const customId = parseCustomId(interaction.customId);
    if (!customId?.submissionId) return;
    const submission = this.#repository.getRequired(customId.submissionId);
    if (customId.action === "denial") {
      this.#requireModerator(interaction);
      const reason = denialReason(interaction.fields);
      if (!reason) throw new Error("A denial reason is required");
      if (!this.#repository.deny(submission.id, interaction.user.id, reason)) {
        throw new Error("Another moderator already decided this submission");
      }
      await this.#updateReviewStatus(submission, "Denied", Colors.Red);
      await this.#notifySubmitter(submission, `Your card submission was denied: ${reason}`);
      await interaction.reply({ content: "Submission denied.", ephemeral: true });
      return;
    }
    if (customId.action !== "step" || !customId.stage) return;
    this.#requireSubmitter(interaction, submission);
    if (submission.status !== "draft" || submission.stage !== customId.stage) {
      throw new Error("This form step is no longer active");
    }
    if (customId.stage === "contribution") {
      const payload = applyContributionFields(submission.payload, interaction.fields);
      this.#repository.awaitArtwork(submission.id, payload);
      await interaction.reply({
        content: [
          "Card details saved. Add the image privately with:",
          `\`/card-artwork submission:${submission.id} artwork:<your file>\``,
          "Accepted formats: PNG or JPEG, up to 10 MB.",
        ].join("\n"),
        ephemeral: true,
      });
      return;
    }
    const schema = this.#schemaFor(submission);
    const currentPlan = buildFormPlan(schema, submission.payload);
    const step = currentPlan.find((candidate) => candidate.id === customId.stage);
    if (!step) throw new Error("This form step is no longer available");
    const payload = applyStepFields(schema, submission.payload, step, interaction.fields);
    const nextPlan = buildFormPlan(schema, payload);
    const completedIndex = nextPlan.findIndex((candidate) => candidate.id === step.id);
    const nextStage = nextPlan[completedIndex + 1]?.id ?? "contribution";
    this.#repository.saveProgress(submission.id, payload, nextStage);
    await interaction.reply({
      content: `Saved. Submission ID: \`${submission.id}\``,
      components: [new ActionRowBuilder<ButtonBuilder>().addComponents(buildContinueButton(submission.id, nextStage))],
      ephemeral: true,
    });
  }

  async #handleArtwork(interaction: ChatInputCommandInteraction): Promise<void> {
    const submissionId = interaction.options.getString("submission", true);
    const attachment = interaction.options.getAttachment("artwork", true);
    const submission = this.#repository.getRequired(submissionId);
    this.#requireSubmitter(interaction, submission);
    if (submission.status !== "awaiting_artwork") throw new Error("This submission is not waiting for artwork");
    if (attachment.size > MAX_ARTWORK_BYTES) throw new Error("Artwork must be 10 MB or smaller");
    if (attachment.contentType && !["image/png", "image/jpeg"].includes(attachment.contentType)) {
      throw new Error("Artwork must be a PNG or JPEG image");
    }
    await interaction.deferReply({ ephemeral: true });
    const response = await fetch(attachment.url);
    if (!response.ok) throw new Error("Discord could not provide the artwork attachment");
    const source = Buffer.from(await response.arrayBuffer());
    const artworkPath = await this.#artwork.normalize(submission.id, source);
    const pending: SubmissionRecord = { ...submission, status: "pending", stage: "review", artworkPath };
    const reviewChannel = await this.#textChannel(this.#config.reviewChannelId);
    const reviewMessage = await reviewChannel.send(buildReviewMessage(this.#schemaFor(submission), pending));
    this.#repository.queueForReview(submission.id, artworkPath);
    this.#repository.attachReviewMessage(submission.id, reviewChannel.id, reviewMessage.id);
    await interaction.editReply("Artwork normalized to 1024×1024 PNG and sent to the moderator review queue.");
  }

  async #handleStatus(interaction: ChatInputCommandInteraction): Promise<void> {
    const submission = this.#repository.getRequired(interaction.options.getString("submission", true));
    if (submission.submitterId !== interaction.user.id && !this.#isModerator(interaction)) {
      throw new Error("You can only view your own card submissions");
    }
    const details = submission.pullRequestUrl
      ?? submission.decisionReason
      ?? (submission.status === "awaiting_artwork" ? "Upload artwork with /card-artwork." : "No additional details.");
    await interaction.reply({
      content: `Status: **${submission.status.replaceAll("_", " ")}**\n${details}`,
      ephemeral: true,
    });
  }

  async #publishIntakePanel(): Promise<void> {
    const channel = await this.#textChannel(this.#config.intakeChannelId);
    const payload = {
      embeds: [new EmbedBuilder()
        .setTitle("Create a community card")
        .setDescription("Build a card from the game’s current fields, styles, and effects. Your submission goes to moderators for review.")
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
}

function userFacingError(error: unknown): string {
  const message = error instanceof Error ? error.message : "Unexpected card bot error";
  return message.length <= 1900 ? message : `${message.slice(0, 1899)}…`;
}
