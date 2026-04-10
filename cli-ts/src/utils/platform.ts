import { execSync } from "node:child_process";

export function detectPlatform(): "macos" | "linux" | "unknown" {
  switch (process.platform) {
    case "darwin":
      return "macos";
    case "linux":
      return "linux";
    default:
      return "unknown";
  }
}

export function hasCmd(cmd: string): boolean {
  try {
    execSync(`command -v ${cmd}`, { stdio: ["pipe", "pipe", "pipe"] });
    return true;
  } catch {
    return false;
  }
}
