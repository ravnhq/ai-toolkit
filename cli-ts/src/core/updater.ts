import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { globalConfigGet } from "./config.js";
import {
  LAST_UPDATE_FILE,
  REPO_DIR,
  UPDATE_CHECK_DAYS,
} from "./paths.js";
import { info, success, warn } from "../utils/logger.js";
import { gitFetch, gitPull, gitRevParse } from "../utils/git.js";
import { confirm } from "../tui/prompts.js";

export function epochNow(): number {
  return Math.floor(Date.now() / 1000);
}

export function shouldCheckUpdate(): boolean {
  const checkDays = parseInt(
    globalConfigGet("update_check", String(UPDATE_CHECK_DAYS)),
    10,
  );
  if (checkDays === 0) return false;
  if (!existsSync(LAST_UPDATE_FILE)) return true;

  const lastCheck =
    parseInt(readFileSync(LAST_UPDATE_FILE, "utf-8").trim(), 10) || 0;
  const diff = epochNow() - lastCheck;
  const threshold = checkDays * 86400;
  return diff >= threshold;
}

export function touchLastUpdate(): void {
  writeFileSync(LAST_UPDATE_FILE, String(epochNow()));
}

export function checkRemoteUpdates(): boolean {
  if (!existsSync(`${REPO_DIR}/.git`)) return false;
  if (!gitFetch(REPO_DIR)) return false;
  const localHead = gitRevParse(REPO_DIR, "HEAD");
  const remoteHead = gitRevParse(REPO_DIR, "origin/main");
  return localHead !== remoteHead;
}

export function countRemoteUpdates(): number {
  try {
    const count = execSync(
      `git -C "${REPO_DIR}" rev-list HEAD..origin/main --count`,
      { encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] },
    ).trim();
    return parseInt(count, 10) || 0;
  } catch {
    return 0;
  }
}

export function pullUpdates(): boolean {
  return gitPull(REPO_DIR);
}

export async function autoUpdateCheck(): Promise<void> {
  if (!shouldCheckUpdate()) return;

  if (checkRemoteUpdates()) {
    const count = countRemoteUpdates();
    console.log();
    warn(
      `ravencito found ${count} shiny new update${count === 1 ? "" : "s"}!`,
    );
    const doUpdate = await confirm("Install now?");
    if (doUpdate) {
      pullUpdates();
      touchLastUpdate();
      success("Updated! Restart ravencito to use the latest version.");
    } else {
      touchLastUpdate();
      info("Skipped. Run 'ravencito update' anytime.");
    }
    console.log();
  } else {
    touchLastUpdate();
  }
}
