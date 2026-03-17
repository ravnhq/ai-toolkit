import {
  checkbox,
  search,
  select,
  confirm as inquirerConfirm,
  input,
} from "@inquirer/prompts";
import { basename } from "node:path";
import chalk from "chalk";
import type { Skill } from "../core/registry.js";
import { registryResolveDeps } from "../core/registry.js";
import { warn } from "../utils/logger.js";

function isVSCodeTerminal(): boolean {
  return process.env.TERM_PROGRAM === "vscode";
}

const CATEGORY_ORDER = [
  "universal",
  "platform",
  "framework",
  "design",
  "assistant",
];

/**
 * Build a rich multi-line description for a skill's detail preview.
 */
function buildSkillDescription(s: Skill): string {
  const lines = [s.description];
  const meta = [`Category: ${s.category}`, `Version: ${s.version}`];
  if (s.rules) meta.push(`Rules: ${s.rules}`);
  lines.push(meta.join(" | "));
  if (s.extends) {
    const chain = registryResolveDeps(s.name).join(" \u2192 ");
    lines.push(`Chain: ${chain}`);
  }
  lines.push(`Tags: ${s.tags.join(", ")}`);
  return lines.join("\n");
}

/**
 * Interactive multi-select skill picker with arrow keys + space toggle.
 * Includes rich descriptions for each skill.
 */
export async function pickSkills(skills: Skill[]): Promise<string[]> {
  const vscode = isVSCodeTerminal();
  if (vscode) {
    warn(
      "VSCode terminal detected \u2014 reduced view. For best experience, use an external terminal.",
    );
  }

  // Group by category
  const grouped = new Map<string, Skill[]>();
  for (const skill of skills) {
    const existing = grouped.get(skill.category) ?? [];
    existing.push(skill);
    grouped.set(skill.category, existing);
  }

  // Build choices with category separators and rich descriptions
  const choices: Array<{
    name: string;
    value: string;
    description?: string;
  }> = [];

  for (const cat of CATEGORY_ORDER) {
    const catSkills = grouped.get(cat);
    if (!catSkills?.length) continue;

    for (const s of catSkills) {
      const extendsLabel = s.extends
        ? chalk.dim(` \u2190 ${s.extends}`)
        : "";
      choices.push({
        name: `${chalk.cyan(s.name)}${extendsLabel}  ${chalk.dim(`[${cat}]`)}`,
        value: s.name,
        description: buildSkillDescription(s),
      });
    }
  }

  const selected = await checkbox({
    message: "Select skills to install (space to toggle, enter to confirm)",
    choices,
    pageSize: vscode ? 8 : 20,
  });

  return selected;
}

/**
 * Interactive skill search with live filtering.
 * Returns a single skill name or null if cancelled.
 */
export async function searchSkills(skills: Skill[]): Promise<string | null> {
  const vscode = isVSCodeTerminal();
  const pageSize = vscode ? 8 : 20;

  const result = await search<string | null>({
    message: "Search skills by name, description, or tag",
    pageSize,
    source: (term) => {
      const q = (term ?? "").toLowerCase();
      const filtered = skills.filter((s) => {
        if (!q) return true;
        return (
          s.name.toLowerCase().includes(q) ||
          s.description.toLowerCase().includes(q) ||
          s.tags.some((t) => t.toLowerCase().includes(q))
        );
      });

      return filtered.map((s) => {
        const extendsLabel = s.extends
          ? chalk.dim(` \u2190 ${s.extends}`)
          : "";
        return {
          name: `${chalk.cyan(s.name)}${extendsLabel}  ${chalk.dim(`[${s.category}]`)}`,
          value: s.name as string | null,
          short: s.name,
          description: buildSkillDescription(s),
        };
      });
    },
  });

  return result;
}

/**
 * Pick a single category from the list.
 */
export async function pickCategory(
  categories: string[],
): Promise<string> {
  return select({
    message: "Select a category",
    choices: categories.map((c) => ({ name: c, value: c })),
  });
}

/**
 * Pick install directory for the project.
 */
export async function pickInstallDir(): Promise<string> {
  const cwd = process.cwd();
  const choice = await select({
    message: "Where should skills be installed?",
    choices: [
      {
        name: `. (current directory: ${basename(cwd)})`,
        value: ".",
      },
      {
        name: ".cursor/rules  (works with Cursor + Claude Code)",
        value: ".cursor/rules",
      },
      {
        name: ".claude/rules  (Claude Code only)",
        value: ".claude/rules",
      },
      { name: "Custom path", value: "__custom__" },
    ],
  });

  if (choice === "__custom__") {
    return input({ message: "Enter path:" });
  }
  return choice;
}

/**
 * Yes/No confirmation prompt.
 */
export async function confirm(
  message: string,
  defaultValue = true,
): Promise<boolean> {
  return inquirerConfirm({ message, default: defaultValue });
}
