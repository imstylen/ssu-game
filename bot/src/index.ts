import { mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { Client, GatewayIntentBits } from "discord.js";
import { ArtworkNormalizer } from "./artwork/artwork-normalizer.js";
import { loadConfig } from "./config.js";
import { DiscordCardBot } from "./discord/card-bot.js";
import { GithubPublisher } from "./github/github-publisher.js";
import { CardApprovalService } from "./godot/card-approval-service.js";
import { SchemaStore } from "./godot/schema-store.js";
import { WorkingCheckout } from "./godot/working-checkout.js";
import { ExecFileCommandRunner } from "./process/command-runner.js";
import { SubmissionRepository } from "./storage/submission-repository.js";

const config = loadConfig();
await mkdir(dirname(config.databasePath), { recursive: true });
const runner = new ExecFileCommandRunner();
const remoteUrl = `https://github.com/${config.githubOwner}/${config.githubRepository}.git`;
const checkout = new WorkingCheckout(config.workingCheckout, remoteUrl, config.githubBaseBranch, runner);
const schemas = new SchemaStore(checkout, config.godotExecutable, runner);
const repository = new SubmissionRepository(config.databasePath);
const publisher = new GithubPublisher({
  appId: config.githubAppId,
  installationId: config.githubInstallationId,
  privateKey: config.githubPrivateKey,
  owner: config.githubOwner,
  repository: config.githubRepository,
  baseBranch: config.githubBaseBranch,
});
const approval = new CardApprovalService(checkout, schemas, config.godotExecutable, runner, publisher);
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
});
const bot = new DiscordCardBot(
  client,
  config,
  repository,
  schemas,
  new ArtworkNormalizer(config.artworkDirectory),
  approval,
);

await bot.start();
