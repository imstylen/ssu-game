import { access, mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import type { CommandRunner } from "../process/command-runner.js";

export class WorkingCheckout {
  readonly path: string;
  readonly #remoteUrl: string;
  readonly #baseBranch: string;
  readonly #runner: CommandRunner;

  constructor(path: string, remoteUrl: string, baseBranch: string, runner: CommandRunner) {
    this.path = resolve(path);
    this.#remoteUrl = remoteUrl;
    this.#baseBranch = baseBranch;
    this.#runner = runner;
  }

  async sync(): Promise<string> {
    if (!(await this.#hasGitDirectory())) {
      await mkdir(dirname(this.path), { recursive: true });
      await this.#runner.run("git", [
        "clone",
        "--branch",
        this.#baseBranch,
        "--single-branch",
        this.#remoteUrl,
        this.path,
      ]);
    } else {
      await this.#runner.run("git", ["fetch", "origin", this.#baseBranch], this.path);
    }

    await this.#runner.run("git", ["reset", "--hard", `origin/${this.#baseBranch}`], this.path);
    await this.#runner.run("git", ["clean", "-fd"], this.path);
    const result = await this.#runner.run("git", ["rev-parse", "HEAD"], this.path);
    return result.stdout.trim();
  }

  async #hasGitDirectory(): Promise<boolean> {
    try {
      await access(resolve(this.path, ".git"));
      return true;
    } catch {
      return false;
    }
  }
}
