import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";
import {
  CORVUS_DIR,
  CORVUS_CONFIG,
  CORVUSRC,
} from "./paths.js";
import { warn } from "../utils/logger.js";

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

/** Legacy Claude/Cursor dirs before Agent Skills under `.claude/skills` / `.cursor/skills`. */
const LEGACY_TO_CANONICAL_INSTALL_DIR: Readonly<Record<string, string>> = {
  ".claude/rules": ".claude/skills",
  ".cursor/rules": ".cursor/skills",
};

/**
 * Normalize a stored `install_dir` for comparison against known legacy layouts.
 */
export function normalizeProjectInstallDirValue(value: string): string {
  let resolved = value.trim().replace(/\\/g, "/");
  if (resolved.startsWith("./")) {
    resolved = resolved.slice(2);
  }
  while (resolved.length > 1 && resolved.endsWith("/")) {
    resolved = resolved.slice(0, -1);
  }
  return resolved;
}

function joinProjectRelativeDir(projectRoot: string, relativePosix: string): string {
  const segments = relativePosix.split("/").filter(Boolean);
  return segments.length === 0 ? projectRoot : join(projectRoot, ...segments);
}

/**
 * Move or merge `fromAbs` into `toAbs` (both skill install roots or nested trees).
 * When both exist as directories, children are merged; matching file paths are left in place and warned.
 */
function moveInstallTreeMerge(fromAbs: string, toAbs: string): void {
  if (!existsSync(fromAbs)) {
    return;
  }
  if (!existsSync(toAbs)) {
    mkdirSync(dirname(toAbs), { recursive: true });
    renameSync(fromAbs, toAbs);
    return;
  }
  const fromStat = statSync(fromAbs);
  const toStat = statSync(toAbs);
  if (!fromStat.isDirectory() || !toStat.isDirectory()) {
    warn(
      `Cannot migrate install tree: expected directories at\n  ${fromAbs}\n  ${toAbs}`,
    );
    return;
  }
  for (const ent of readdirSync(fromAbs, { withFileTypes: true })) {
    const sourcePath = join(fromAbs, ent.name);
    const destPath = join(toAbs, ent.name);
    if (!existsSync(destPath)) {
      renameSync(sourcePath, destPath);
      continue;
    }
    if (ent.isDirectory() && statSync(destPath).isDirectory()) {
      moveInstallTreeMerge(sourcePath, destPath);
      continue;
    }
    warn(
      `Skipping migrate (path exists in both trees): ${ent.name}`,
    );
  }
}

function pruneEmptyDirectories(rootDir: string): void {
  if (!existsSync(rootDir) || !statSync(rootDir).isDirectory()) {
    return;
  }
  for (const ent of readdirSync(rootDir, { withFileTypes: true })) {
    if (ent.isDirectory()) {
      pruneEmptyDirectories(join(rootDir, ent.name));
    }
  }
  if (readdirSync(rootDir).length === 0) {
    rmSync(rootDir, { recursive: true });
  }
}

function relocateLegacySkillInstallTree(
  projectRoot: string,
  legacyRelative: string,
  canonicalRelative: string,
): void {
  const fromAbs = joinProjectRelativeDir(projectRoot, legacyRelative);
  const toAbs = joinProjectRelativeDir(projectRoot, canonicalRelative);
  if (!existsSync(fromAbs)) {
    return;
  }
  mkdirSync(dirname(toAbs), { recursive: true });
  moveInstallTreeMerge(fromAbs, toAbs);
  if (existsSync(fromAbs)) {
    pruneEmptyDirectories(fromAbs);
  }
  if (existsSync(fromAbs)) {
    const remaining = readdirSync(fromAbs);
    if (remaining.length > 0) {
      warn(
        `Some paths under ${legacyRelative} could not be moved to ${canonicalRelative} (${remaining.length} top-level item(s) left). Resolve conflicts manually.`,
      );
    }
  }
}

/**
 * Rewrite `install_dir` in `.corvusrc` when it matches a documented legacy layout
 * (skills previously installed under `.claude/rules` / `.cursor/rules`).
 * On-disk skill trees are renamed or merged into `.claude/skills` or `.cursor/skills` first.
 */
export function migrateLegacyProjectInstallDirIfNeeded(options?: {
  readonly projectRoot?: string;
}): boolean {
  const root = options?.projectRoot ?? findProjectRoot();
  const rcPath = join(root, CORVUSRC);
  if (!existsSync(rcPath)) {
    return false;
  }
  const rawInstallDir = configGet(rcPath, "install_dir", "");
  if (!rawInstallDir) {
    return false;
  }
  const key = normalizeProjectInstallDirValue(rawInstallDir);
  const canonical = LEGACY_TO_CANONICAL_INSTALL_DIR[key];
  if (!canonical || canonical === key) {
    return false;
  }
  relocateLegacySkillInstallTree(root, key, canonical);
  configSet(rcPath, "install_dir", canonical);
  return true;
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
