export interface BotConfig {
  discordToken: string;
  discordApplicationId: string;
  discordGuildId: string;
  intakeChannelId: string;
  reviewChannelId: string;
  moderatorRoleId: string;
  githubAppId: number;
  githubInstallationId: number;
  githubPrivateKey: string;
  githubOwner: string;
  githubRepository: string;
  githubBaseBranch: string;
  databasePath: string;
  artworkDirectory: string;
  workingCheckout: string;
  godotExecutable: string;
}

function required(environment: NodeJS.ProcessEnv, name: string): string {
  const value = environment[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function positiveInteger(environment: NodeJS.ProcessEnv, name: string): number {
  const value = Number(required(environment, name));
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new Error(`${name} must be a positive integer`);
  }
  return value;
}

export function loadConfig(environment: NodeJS.ProcessEnv = process.env): BotConfig {
  return {
    discordToken: required(environment, "DISCORD_TOKEN"),
    discordApplicationId: required(environment, "DISCORD_APPLICATION_ID"),
    discordGuildId: required(environment, "DISCORD_GUILD_ID"),
    intakeChannelId: required(environment, "INTAKE_CHANNEL_ID"),
    reviewChannelId: required(environment, "REVIEW_CHANNEL_ID"),
    moderatorRoleId: required(environment, "MODERATOR_ROLE_ID"),
    githubAppId: positiveInteger(environment, "GITHUB_APP_ID"),
    githubInstallationId: positiveInteger(environment, "GITHUB_INSTALLATION_ID"),
    githubPrivateKey: required(environment, "GITHUB_PRIVATE_KEY").replaceAll("\\n", "\n"),
    githubOwner: required(environment, "GITHUB_OWNER"),
    githubRepository: required(environment, "GITHUB_REPOSITORY"),
    githubBaseBranch: environment.GITHUB_BASE_BRANCH?.trim() || "master",
    databasePath: required(environment, "DATABASE_PATH"),
    artworkDirectory: required(environment, "ARTWORK_DIRECTORY"),
    workingCheckout: required(environment, "WORKING_CHECKOUT"),
    godotExecutable: environment.GODOT_EXECUTABLE?.trim() || "godot",
  };
}
