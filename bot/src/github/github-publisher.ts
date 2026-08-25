import { createAppAuth } from "@octokit/auth-app";
import { Octokit } from "@octokit/rest";
import type { CardSchema } from "../domain/schema.js";
import type { SubmissionRecord } from "../domain/submission.js";
import { buildPullRequestBody } from "./pull-request-body.js";

export interface GeneratedFile {
  path: string;
  content: Buffer;
}

export interface PublishedPullRequest {
  url: string;
  number: number;
  branch: string;
}

export interface CardPublisher {
  publish(schema: CardSchema, submission: SubmissionRecord, files: GeneratedFile[]): Promise<PublishedPullRequest>;
}

interface GithubPublisherOptions {
  appId: number;
  installationId: number;
  privateKey: string;
  owner: string;
  repository: string;
  baseBranch: string;
}

export class GithubPublisher implements CardPublisher {
  readonly #octokit: Octokit;
  readonly #owner: string;
  readonly #repository: string;
  readonly #baseBranch: string;

  constructor(options: GithubPublisherOptions) {
    this.#octokit = new Octokit({
      authStrategy: createAppAuth,
      auth: {
        appId: options.appId,
        installationId: options.installationId,
        privateKey: options.privateKey,
      },
    });
    this.#owner = options.owner;
    this.#repository = options.repository;
    this.#baseBranch = options.baseBranch;
  }

  async publish(
    schema: CardSchema,
    submission: SubmissionRecord,
    files: GeneratedFile[],
  ): Promise<PublishedPullRequest> {
    if (files.length === 0) throw new Error("Godot did not produce any files to publish");
    const reference = await this.#octokit.git.getRef({
      owner: this.#owner,
      repo: this.#repository,
      ref: `heads/${this.#baseBranch}`,
    });
    const baseCommitSha = reference.data.object.sha;
    const baseCommit = await this.#octokit.git.getCommit({
      owner: this.#owner,
      repo: this.#repository,
      commit_sha: baseCommitSha,
    });
    const treeEntries = await Promise.all(files.map(async (file) => {
      const blob = await this.#octokit.git.createBlob({
        owner: this.#owner,
        repo: this.#repository,
        content: file.content.toString("base64"),
        encoding: "base64",
      });
      return {
        path: file.path,
        mode: "100644" as const,
        type: "blob" as const,
        sha: blob.data.sha,
      };
    }));
    const tree = await this.#octokit.git.createTree({
      owner: this.#owner,
      repo: this.#repository,
      base_tree: baseCommit.data.tree.sha,
      tree: treeEntries,
    });
    const commit = await this.#octokit.git.createCommit({
      owner: this.#owner,
      repo: this.#repository,
      message: `feat(cards): add community submission ${submission.id}`,
      tree: tree.data.sha,
      parents: [baseCommitSha],
    });
    const branch = `card-submission/${submission.id}`;
    try {
      await this.#octokit.git.createRef({
        owner: this.#owner,
        repo: this.#repository,
        ref: `refs/heads/${branch}`,
        sha: commit.data.sha,
      });
    } catch (error) {
      if (!isAlreadyExistsError(error)) throw error;
      await this.#octokit.git.updateRef({
        owner: this.#owner,
        repo: this.#repository,
        ref: `heads/${branch}`,
        sha: commit.data.sha,
        force: true,
      });
    }
    const existing = await this.#octokit.pulls.list({
      owner: this.#owner,
      repo: this.#repository,
      state: "open",
      head: `${this.#owner}:${branch}`,
      base: this.#baseBranch,
      per_page: 1,
    });
    if (existing.data[0]) {
      return { url: existing.data[0].html_url, number: existing.data[0].number, branch };
    }
    const pullRequest = await this.#octokit.pulls.create({
      owner: this.#owner,
      repo: this.#repository,
      head: branch,
      base: this.#baseBranch,
      title: `Community card submission ${submission.id}`,
      body: buildPullRequestBody(schema, submission),
      draft: true,
    });
    return { url: pullRequest.data.html_url, number: pullRequest.data.number, branch };
  }
}

function isAlreadyExistsError(error: unknown): boolean {
  return typeof error === "object" && error !== null && "status" in error && error.status === 422;
}
