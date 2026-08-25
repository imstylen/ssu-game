import { SlashCommandBuilder } from "discord.js";

export const commandDefinitions = [
  new SlashCommandBuilder()
    .setName("card-artwork")
    .setDescription("Attach artwork to your card submission")
    .addStringOption((option) => option
      .setName("submission")
      .setDescription("Submission ID shown by the card form")
      .setRequired(true))
    .addAttachmentOption((option) => option
      .setName("artwork")
      .setDescription("PNG or JPEG, up to 10 MB")
      .setRequired(true)),
  new SlashCommandBuilder()
    .setName("card-status")
    .setDescription("Check a card submission")
    .addStringOption((option) => option
      .setName("submission")
      .setDescription("Submission ID")
      .setRequired(true)),
  new SlashCommandBuilder()
    .setName("card-schema-refresh")
    .setDescription("Refresh card options from the game repository"),
  new SlashCommandBuilder()
    .setName("card-intake-refresh")
    .setDescription("Create or update the public card submission panel"),
].map((command) => command.toJSON());
