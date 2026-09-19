# Community card bot

This service reads the card contract exported by Godot, collects a Discord submission, normalizes its artwork, and sends moderator-approved cards through Godot's authoring command. It creates a new GitHub branch and draft pull request; it never commits to `master`.

Phase 1 (`feat/schema-driven-card-authoring`) must be merged before deploying this branch because the runtime checkout calls the schema and card-authoring scripts added there.

## Local checks

Use Node.js 24.19 or newer:

```text
cd bot
npm ci
npm test
```

The test suite does not connect to Discord or GitHub and does not need secrets. GitHub Actions runs the bot tests, audits production dependencies, imports the Godot project, and runs the game suite. This same workflow validates card files created by the bot in future draft PRs.

## Runtime configuration

Copy `.env.example` into your host's secret/configuration system. The process reads environment variables directly; it does not load a local `.env` file itself.

Create a Discord application and bot, invite it with the `bot` and `applications.commands` scopes, and give it these server permissions in the configured intake/review channels:

- View Channels
- Send Messages
- Create Private Threads
- Send Messages in Threads
- Manage Threads
- Embed Links
- Attach Files
- Read Message History
- Use Application Commands

Enable the privileged **Message Content Intent** under the bot settings in the Discord Developer Portal. The bot requests the `Guilds`, `GuildMessages`, and `MessageContent` gateway intents so it can read answers and artwork posted inside card threads. The intake channel must be an ordinary guild text channel; the bot creates private threads beneath it and adds the submitter. Members need View Channel and Send Messages in Threads, while moderators need Manage Threads to inspect every private draft.

Configure the application, guild, intake channel, review channel, and moderator role IDs from Discord.

Create and install a GitHub App on the repository with:

- Metadata: read
- Contents: read and write
- Pull requests: read and write

Set `GITHUB_PRIVATE_KEY` to the PEM with newlines encoded as `\n` when the host only supports one-line environment values. The checkout uses the public Git URL; the GitHub App is used only for generated blobs, branches, and draft PRs.

GitHub repository secrets are not needed by the validation workflow because CI never starts the live bot. Store `DISCORD_TOKEN` and the GitHub App credentials on the server/container platform that runs the long-lived bot. If deployment is later performed by Actions, GitHub Secrets can deliver those values to the deployment step, but they should still not be committed or used in pull-request tests.

## Run in Docker

Build from the repository root so the Dockerfile can copy `bot/`:

```text
docker build --file bot/Dockerfile --tag access-allies-card-bot .
docker run --detach --restart unless-stopped \
  --env-file /secure/path/card-bot.env \
  --volume access-allies-card-bot-data:/data \
  --name access-allies-card-bot \
  access-allies-card-bot
```

The image pins Node 24.19 and Godot 4.4.1 and verifies the official Godot SHA-512 checksum while building. The `/data` volume preserves SQLite submissions, normalized artwork, the repository checkout, and Godot's import cache.

On startup the bot refreshes the schema, registers guild commands, and creates or updates the intake panel. Submitters run `/newcard` or click **Create a card** to open a private, persistent conversation. They reply to schema-generated questions and can attach or replace artwork in the thread at any point; submission IDs are never entered manually. Moderators can run `/card-schema-refresh` and `/card-intake-refresh`.
