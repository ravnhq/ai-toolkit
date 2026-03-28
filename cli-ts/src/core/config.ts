import { existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import {
  CORVUS_DIR,
  CORVUS_CONFIG,
  CORVUSRC,
} from "./paths.js";

// ─── INI-style config ────────────────────────────────────────────────────────

export function configGet(
  file: string,
  key: string,
  defaultValue = "",
): string {
  if (!existsSync(file)) return defaultValue;
  const lines = readFileSync(file, "utf-8").split("\n");
  for (const line of lines) {
    if (line.startsWith(`${key}=`)) {
      return line.slice(key.length + 1);
    }
  }
  return defaultValue;
}

export function configSet(file: string, key: string, value: string): void {
  const dir = dirname(file);
  mkdirSync(dir, { recursive: true });

  if (existsSync(file)) {
    const lines = readFileSync(file, "utf-8").split("\n");
    let found = false;
    const updated = lines.map((line) => {
      if (line.startsWith(`${key}=`)) {
        found = true;
        return `${key}=${value}`;
      }
      return line;
    });
    if (!found) {
      updated.push(`${key}=${value}`);
    }
    writeFileSync(file, updated.join("\n"));
  } else {
    writeFileSync(file, `${key}=${value}\n`);
  }
}

// ─── Global config ───────────────────────────────────────────────────────────

export function ensureConfigDir(): void {
  mkdirSync(CORVUS_DIR, { recursive: true });
}

export function globalConfigGet(key: string, defaultValue = ""): string {
  return configGet(CORVUS_CONFIG, key, defaultValue);
}

export function globalConfigSet(key: string, value: string): void {
  configSet(CORVUS_CONFIG, key, value);
}

// ─── Project config ──────────────────────────────────────────────────────────

export function findProjectRoot(): string {
  let dir = process.cwd();
  while (dir !== "/") {
    if (
      existsSync(join(dir, CORVUSRC)) ||
      existsSync(join(dir, ".git"))
    ) {
      return dir;
    }
    dir = dirname(dir);
  }
  return process.cwd();
}

export function projectConfigGet(key: string, defaultValue = ""): string {
  const root = findProjectRoot();
  return configGet(join(root, CORVUSRC), key, defaultValue);
}

export function projectConfigSet(key: string, value: string): void {
  const root = findProjectRoot();
  configSet(join(root, CORVUSRC), key, value);
}

// ─── Skill list helpers ──────────────────────────────────────────────────────

export function parseSkillList(list: string): string[] {
  if (!list) return [];
  return list.split(",").filter(Boolean);
}

export function skillVersionFromList(
  list: string,
  name: string,
): string | null {
  const entries = parseSkillList(list);
  for (const entry of entries) {
    const [entryName, version] = entry.split(":");
    if (entryName === name) return version ?? null;
  }
  return null;
}

export function skillListUpsert(
  list: string,
  name: string,
  version: string,
): string {
  const entries = parseSkillList(list);
  let found = false;
  const result = entries.map((entry) => {
    const entryName = entry.split(":")[0];
    if (entryName === name) {
      found = true;
      return `${name}:${version}`;
    }
    return entry;
  });
  if (!found) {
    result.push(`${name}:${version}`);
  }
  return result.join(",");
}

export function skillListRemove(list: string, name: string): string {
  const entries = parseSkillList(list);
  return entries
    .filter((entry) => entry.split(":")[0] !== name)
    .join(",");
}

export function getGlobalSkills(): string {
  return globalConfigGet("global_skills", "");
}

export function getProjectSkills(): string {
  return projectConfigGet("skills", "");
}
