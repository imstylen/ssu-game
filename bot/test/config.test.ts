import assert from "node:assert/strict";
import test from "node:test";
import { loadConfig } from "../src/config.js";

const environment: NodeJS.ProcessEnv = {
  DISCORD_TOKEN: "discord",
  DISCORD_APPLICATION_ID: "application",
  DISCORD_GUILD_ID: "guild",
  INTAKE_CHANNEL_ID: "intake",
  REVIEW_CHANNEL_ID: "review",
  MODERATOR_ROLE_ID: "moderator",
  GITHUB_APP_ID: "123",
  GITHUB_INSTALLATION_ID: "456",
  GITHUB_PRIVATE_KEY: "line-one\\nline-two",
  GITHUB_OWNER: "owner",
  GITHUB_REPOSITORY: "repository",
  DATABASE_PATH: "/data/database.sqlite",
  ARTWORK_DIRECTORY: "/data/artwork",
  WORKING_CHECKOUT: "/data/repository",
};

test("loads runtime secrets and safe defaults", () => {
  const config = loadConfig(environment);
  assert.equal(config.githubPrivateKey, "line-one\nline-two");
  assert.equal(config.githubBaseBranch, "master");
  assert.equal(config.godotExecutable, "godot");
});

test("rejects incomplete configuration", () => {
  assert.throws(() => loadConfig({ ...environment, DISCORD_TOKEN: "" }), /DISCORD_TOKEN/);
});
