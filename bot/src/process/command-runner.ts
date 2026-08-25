import { execFile } from "node:child_process";

export interface CommandResult {
  stdout: string;
  stderr: string;
}

export interface CommandRunner {
  run(executable: string, arguments_: readonly string[], workingDirectory?: string): Promise<CommandResult>;
}

export class ExecFileCommandRunner implements CommandRunner {
  run(executable: string, arguments_: readonly string[], workingDirectory?: string): Promise<CommandResult> {
    return new Promise((resolve, reject) => {
      execFile(
        executable,
        [...arguments_],
        {
          cwd: workingDirectory,
          encoding: "utf8",
          maxBuffer: 10 * 1024 * 1024,
          windowsHide: true,
        },
        (error, stdout, stderr) => {
          if (error) {
            reject(new Error(
              `${executable} exited unsuccessfully: ${stderr.trim() || stdout.trim() || error.message}`,
              { cause: error },
            ));
            return;
          }
          resolve({ stdout, stderr });
        },
      );
    });
  }
}
