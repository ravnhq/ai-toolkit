import { existsSync, readFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import chalk from "chalk";
import {
  ensureConfigDir,
  findProjectRoot,
  getGlobalSkills,
  getProjectSkills,
  globalConfigSet,
  projectConfigSet,
  skillListUpsert,
  globalConfigGet,
} from "../core/config.js";
import {
  ensureRegistry,
  registryAllSkills,
  registryResolveDeps,
  registrySkillExists,
  registrySkillSourceDir,
  registrySkillVersion,
} from "../core/registry.js";
import { REPO_DIR } from "../core/paths.js";
import { info, success, warn, die, skillName, dim, bold } from "../utils/logger.js";
import { copySkill } from "../utils/fs.js";
import { pickSkills, pickInstallTarget } from "../tui/prompts.js";
import type { InstallTarget } from "../tui/prompts.js";

export function resolveTargetDir(target: InstallTarget, customPath?: string): string {
  const home = homedir();
  switch (target) {
    case "project-claude":
      return join(findProjectRoot(), ".claude", "rules");
    case "project-cursor":
      return join(findProjectRoot(), ".cursor", "rules");
    case "project-codex":
      return join(findProjectRoot(), ".codex", "rules");
    case "global-claude":
      return join(home, ".claude", "rules");
    case "global-cursor":
      return join(home, ".cursor", "rules");
    case "global-codex":
      return join(home, ".codex", "rules");
    case "custom":
      return customPath!;
  }
}

export function isGlobalTarget(target: InstallTarget): boolean {
  return target === "global-claude" || target === "global-cursor" || target === "global-codex";
}

export function targetLabel(target: InstallTarget, customPath?: string): string {
  switch (target) {
    case "project-claude":
      return ".claude/rules";
    case "project-cursor":
      return ".cursor/rules";
    case "project-codex":
      return ".codex/rules";
    case "global-claude":
      return "~/.claude/rules";
    case "global-cursor":
      return "~/.cursor/rules";
    case "global-codex":
      return "~/.codex/rules";
    case "custom":
      return customPath!;
  }
}

export async function cmdInstall(args: string[]): Promise<void> {
  ensureRegistry();

  let target: InstallTarget | null = null;
  let customPath: string | undefined;
  let recipe = "";
  let autoDeps = globalConfigGet("auto_deps", "true") === "true";
  const skills: string[] = [];

  // Parse arguments
  let i = 0;
  while (i < args.length) {
    const arg = args[i];
    switch (arg) {
      case "--global":
      case "-g":
        if (!target) target = "global-claude";
        else if (target === "project-claude") target = "global-claude";
        else if (target === "project-cursor") target = "global-cursor";
        else if (target === "project-codex") target = "global-codex";
        break;
      case "--claude":
        if (target === "global-claude" || target === "global-cursor" || target === "global-codex") target = "global-claude";
        else target = "project-claude";
        break;
      case "--cursor":
        if (target === "global-claude" || target === "global-cursor" || target === "global-codex") target = "global-cursor";
        else target = "project-cursor";
        break;
      case "--codex":
        if (target === "global-claude" || target === "global-cursor" || target === "global-codex") target = "global-codex";
        else target = "project-codex";
        break;
      case "--global-claude":
        target = "global-claude";
        break;
      case "--global-cursor":
        target = "global-cursor";
        break;
      case "--global-codex":
        target = "global-codex";
        break;
      case "--recipe":
      case "-r":
        recipe = args[++i] ?? "";
        break;
      case "--no-deps":
        autoDeps = false;
        break;
      default:
        if (arg.startsWith("-")) {
          die(`Unknown option: ${arg}`);
        }
        skills.push(arg);
    }
    i++;
  }

  // Recipe mode
  if (recipe) {
    await installRecipe(recipe, target, customPath);
    return;
  }

  // Interactive mode (no skills specified)
  if (skills.length === 0) {
    await installInteractive(target, customPath);
    return;
  }

  // Direct install
  await installSkills(skills, target, autoDeps, customPath);
}

async function installSkills(
  skills: string[],
  target: InstallTarget | null,
  autoDeps: boolean,
  customPath?: string,
): Promise<void> {
  // Validate all skills exist
  for (const skill of skills) {
    if (!registrySkillExists(skill)) {
      die(
        `Skill not found: ${skill}. Run 'ravencito search ${skill}' to find similar skills.`,
      );
    }
  }

  // Resolve dependencies
  let allSkills: string[];
  if (autoDeps) {
    const seen = new Set<string>();
    allSkills = [];
    for (const skill of skills) {
      const deps = registryResolveDeps(skill);
      for (const dep of deps) {
        if (!seen.has(dep)) {
          seen.add(dep);
          allSkills.push(dep);
        }
      }
    }
  } else {
    allSkills = [...skills];
  }

  // Prompt for target if not specified
  if (!target) {
    const result = await pickInstallTarget();
    target = result.target;
    customPath = result.customPath;
  }

  // Show what will be installed
  console.log();
  console.log(`${bold("Skills to install:")} ${dim(`→ ${targetLabel(target, customPath)}`)}`);
  for (const skill of allSkills) {
    const version = registrySkillVersion(skill);
    const isDep = skills.includes(skill) ? "" : dim(" (dependency)");
    console.log(`  ${chalk.cyan(skill)} v${version}${isDep}`);
  }
  console.log();

  installToTarget(allSkills, target, customPath);
}

function installToTarget(skills: string[], target: InstallTarget, customPath?: string): void {
  const targetDir = resolveTargetDir(target, customPath);
  mkdirSync(targetDir, { recursive: true });

  const isGlobal = isGlobalTarget(target);
  let currentList = isGlobal ? getGlobalSkills() : getProjectSkills();

  for (const skill of skills) {
    const version = registrySkillVersion(skill);
    const sourceDir = registrySkillSourceDir(skill);

    if (!sourceDir || !existsSync(sourceDir)) {
      warn(`Source not found for ${skillName(skill)}, skipping`);
      continue;
    }

    const skillTarget = join(targetDir, skill);
    copySkill(sourceDir, skillTarget);

    currentList = skillListUpsert(currentList, skill, version);
    success(
      `${skillName(skill)} v${version} installed to ${targetLabel(target, customPath)}/${skill}/`,
    );
  }

  if (isGlobal) {
    ensureConfigDir();
    globalConfigSet("global_skills", currentList);
    console.log();
    success("Global skills updated! These skills apply to all your projects.");
  } else if (target === "custom") {
    projectConfigSet("skills", currentList);
    projectConfigSet("install_dir", customPath!);
    console.log();
    success(`Skills installed to ${customPath}!`);
  } else {
    projectConfigSet("skills", currentList);
    const dirMap: Record<string, string> = {
      "project-cursor": ".cursor/rules",
      "project-codex": ".codex/rules",
    };
    projectConfigSet("install_dir", dirMap[target] ?? ".claude/rules");
    console.log();
    success("Skills installed! ravencito is ready to help.");
  }
}

async function installRecipe(
  recipeName: string,
  target: InstallTarget | null,
  customPath?: string,
): Promise<void> {
  const recipeFile = join(REPO_DIR, "cli/recipes", `${recipeName}.txt`);

  if (!existsSync(recipeFile)) {
    die(`Recipe not found: ${recipeName}.`);
  }

  info(`Installing recipe: ${recipeName}`);

  const lines = readFileSync(recipeFile, "utf-8").split("\n");
  const skills = lines
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith("#"));

  if (skills.length === 0) {
    die(`Recipe is empty: ${recipeName}`);
  }

  console.log(`${dim("Skills in recipe:")} ${skills.join(" ")}`);
  console.log();

  await installSkills(skills, target, true, customPath);
}

async function installInteractive(target: InstallTarget | null, customPath?: string): Promise<void> {
  const allSkills = registryAllSkills();
  const selected = await pickSkills(allSkills);

  if (selected.length === 0) {
    info("No skills selected.");
    return;
  }

  await installSkills(selected, target, true, customPath);
}
