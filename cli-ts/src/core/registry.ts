import { existsSync, readFileSync } from "node:fs";
import { MARKETPLACE_PATH, REPO_DIR } from "./paths.js";
import { die } from "../utils/logger.js";

// ─── Types ───────────────────────────────────────────────────────────────────

export interface Skill {
  name: string;
  source: string;
  description: string;
  category: string;
  tags: string[];
  extends?: string;
  status: string;
  rules?: number;
  version: number;
}

interface Marketplace {
  name: string;
  description: string;
  owner: { name: string };
  skills: Skill[];
  drafts: Skill[];
}

// ─── Registry loader ─────────────────────────────────────────────────────────

let _cache: Marketplace | null = null;

function loadMarketplace(): Marketplace {
  if (_cache) return _cache;
  if (!existsSync(MARKETPLACE_PATH)) {
    die("Registry not found. Run 'corvus update' to refresh.");
  }
  _cache = JSON.parse(readFileSync(MARKETPLACE_PATH, "utf-8")) as Marketplace;
  return _cache;
}

export function ensureRegistry(): void {
  loadMarketplace();
}

/** Clear cached marketplace (used after git pull) */
export function clearRegistryCache(): void {
  _cache = null;
}

// ─── Queries ─────────────────────────────────────────────────────────────────

export function registrySkillCount(): number {
  return loadMarketplace().skills.length;
}

export function registrySkillNames(): string[] {
  return loadMarketplace().skills.map((s) => s.name);
}

export function registrySkill(name: string): Skill | undefined {
  return loadMarketplace().skills.find((s) => s.name === name);
}

export function registrySkillField(
  name: string,
  field: keyof Skill,
): string {
  const skill = registrySkill(name);
  if (!skill) return "";
  const val = skill[field];
  if (Array.isArray(val)) return val.join(", ");
  return val != null ? String(val) : "";
}

export function registrySkillExists(name: string): boolean {
  return loadMarketplace().skills.some((s) => s.name === name);
}

export function registrySkillVersion(name: string): string {
  return registrySkillField(name, "version");
}

export function registrySkillSource(name: string): string {
  return registrySkillField(name, "source");
}

export function registrySkillInfo(name: string): string {
  const s = registrySkill(name);
  if (!s) return `Skill not found: ${name}`;
  return [
    `Name:        ${s.name}`,
    `Description: ${s.description}`,
    `Category:    ${s.category}`,
    `Tags:        ${s.tags.join(", ")}`,
    `Extends:     ${s.extends ?? "\u2014"}`,
    `Version:     ${s.version ?? "\u2014"}`,
    `Rules:       ${s.rules ?? "\u2014"}`,
    `Source:      ${s.source}`,
  ].join("\n");
}

// ─── Dependencies ────────────────────────────────────────────────────────────

export function registryResolveDeps(name: string): string[] {
  const chain: string[] = [];
  let current: string | undefined = name;
  while (current) {
    chain.unshift(current);
    const skill = registrySkill(current);
    current = skill?.extends;
  }
  return chain;
}

// ─── Browsing ────────────────────────────────────────────────────────────────

export function registrySkillsByCategory(category: string): Skill[] {
  return loadMarketplace().skills.filter((s) => s.category === category);
}

export function registryCategories(): Map<string, number> {
  const counts = new Map<string, number>();
  for (const s of loadMarketplace().skills) {
    counts.set(s.category, (counts.get(s.category) ?? 0) + 1);
  }
  return counts;
}

export function registrySearch(query: string): Skill[] {
  const q = query.toLowerCase();
  return loadMarketplace().skills.filter(
    (s) =>
      s.name.toLowerCase().includes(q) ||
      s.description.toLowerCase().includes(q) ||
      s.tags.some((t) => t.toLowerCase().includes(q)),
  );
}

export function registrySkillSourceDir(name: string): string {
  const sourceRel = registrySkillSource(name);
  if (!sourceRel) return "";
  return `${REPO_DIR}/${sourceRel.replace(/^\.\//, "")}`;
}

export function registryAllSkills(): Skill[] {
  return loadMarketplace().skills;
}
