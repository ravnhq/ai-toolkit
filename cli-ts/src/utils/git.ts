import { execSync } from "node:child_process";

function exec(cmd: string): string {
  return execSync(cmd, {
    encoding: "utf-8",
    stdio: ["pipe", "pipe", "pipe"],
  }).trim();
}

function execSafe(cmd: string): string | null {
  try {
    return exec(cmd);
  } catch {
    return null;
  }
}

export function gitFetch(repoDir: string): boolean {
  return execSafe(`git -C "${repoDir}" fetch origin main --quiet`) !== null;
}

export function gitPull(repoDir: string): boolean {
  return (
    execSafe(
      `git -C "${repoDir}" pull --rebase origin main --quiet`,
    ) !== null
  );
}

export function gitRevParse(repoDir: string, ref: string): string {
  return execSafe(`git -C "${repoDir}" rev-parse ${ref}`) ?? "";
}

export function gitRevListCount(
  repoDir: string,
  from: string,
  to: string,
): number {
  const result = execSafe(
    `git -C "${repoDir}" rev-list ${from}..${to} --count`,
  );
  return result ? parseInt(result, 10) : 0;
}

export function gitClone(url: string, targetDir: string): boolean {
  return execSafe(`git clone --depth 1 "${url}" "${targetDir}" --quiet`) !== null;
}
