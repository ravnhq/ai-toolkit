import { existsSync, readFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import chalk from "chalk";
import {
  ensureConfigDir,
  findProjectRoot,
  getGlobalSkills,
  getProjectSkills,
  getInstallDir,
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
  registrySkillSource,
  registrySkillSourceDir,
  registrySkillVersion,
} from "../core/registry.js";
import { REPO_DIR } from "../core/paths.js";
import { info, success, warn, die, skillName, dim, bold } from "../utils/logger.js";
import { copySkill } from "../utils/fs.js";
import { pickSkills, pickInstallDir } from "../tui/prompts.js";

export async function cmdInstall(args: string[]): Promise<void> {
  ensureRegistry();

  let globalMode = false;
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
        globalMode = true;
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
    await installRecipe(recipe, globalMode);
    return;
  }

  // Interactive mode (no skills specified)
  if (skills.length === 0) {
    await installInteractive(globalMode);
    return;
  }

  // Direct install
  await installSkills(skills, globalMode, autoDeps);
}

async function installSkills(
  skills: string[],
  globalMode: boolean,
  autoDeps: boolean,
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

  // Prompt for install dir early (project mode)
  if (!globalMode) {
    await ensureInstallDir();
  }

  // Show what will be installed
  console.log();
  console.log(`${bold("Skills to install:")}`);
  for (const skill of allSkills) {
    const version = registrySkillVersion(skill);
    const isDep = skills.includes(skill) ? "" : dim(" (dependency)");
    console.log(`  ${chalk.cyan(skill)} v${version}${isDep}`);
  }
  console.log();

  if (globalMode) {
    installGlobal(allSkills);
  } else {
    installProject(allSkills);
  }
}

function installGlobal(skills: string[]): void {
  ensureConfigDir();
  let currentList = getGlobalSkills();

  for (const skill of skills) {
    const version = registrySkillVersion(skill);
    currentList = skillListUpsert(currentList, skill, version);
    success(`${skillName(skill)} added to global skills`);
  }

  globalConfigSet("global_skills", currentList);
  console.log();
  success("Global skills updated! These skills apply to all your projects.");
}

function installProject(skills: string[]): void {
  const installDir = getInstallDir();
  if (!installDir) {
    die("Install directory not configured.");
    return;
  }

  const projectRoot = findProjectRoot();
  const targetDir = join(projectRoot, installDir);
  mkdirSync(targetDir, { recursive: true });

  let currentList = getProjectSkills();

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
      `${skillName(skill)} v${version} installed to ${installDir}/${skill}/`,
    );
  }

  projectConfigSet("skills", currentList);
  console.log();
  success("Skills installed! ravencito is ready to help.");
}

async function installRecipe(
  recipeName: string,
  globalMode: boolean,
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

  await installSkills(skills, globalMode, true);
}

async function installInteractive(globalMode: boolean): Promise<void> {
  const allSkills = registryAllSkills();
  const selected = await pickSkills(allSkills);

  if (selected.length === 0) {
    info("No skills selected.");
    return;
  }

  await installSkills(selected, globalMode, true);
}

async function ensureInstallDir(): Promise<string> {
  let dir = getInstallDir();
  if (!dir) {
    dir = await pickInstallDir();
    projectConfigSet("install_dir", dir);
  }
  return dir;
}
