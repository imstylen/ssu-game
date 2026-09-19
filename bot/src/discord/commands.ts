import { SlashCommandBuilder } from "discord.js";

export const commandDefinitions = [
  new SlashCommandBuilder()
    .setName("newcard")
    .setDescription("Start a private card-building conversation"),
  new SlashCommandBuilder()
    .setName("card-schema-refresh")
    .setDescription("Refresh card options from the game repository"),
  new SlashCommandBuilder()
    .setName("card-intake-refresh")
    .setDescription("Create or update the public card submission panel"),
].map((command) => command.toJSON());
