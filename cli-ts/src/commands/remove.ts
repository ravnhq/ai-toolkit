import { existsSync, rmSync } from "node:fs";
import { join } from "node:path";
import {
  findProjectRoot,
  getGlobalSkills,
  getProjectSkills,
  globalConfigSet,
  projectConfigGet,
  projectConfigSet,
  skillListRemove,
} from "../core/config.js";
import { die, skillName, success, warn } from "../utils/logger.js";

export function cmdRemove(args: string[]): void {
  if (args.length === 0) {
    die("Usage: ravencito remove <skill-name> [--global]");
  }

  let globalMode = false;
  const skills: string[] = [];

  for (const arg of args) {
    if (arg === "--global" || arg === "-g") {
      globalMode = true;
    } else if (arg.startsWith("-")) {
      die(`Unknown option: ${arg}`);
    } else {
      skills.push(arg);
    }
  }

  if (skills.length === 0) {
    die("No skill name provided.");
  }

  for (const skill of skills) {
    if (globalMode) {
      removeGlobal(skill);
    } else {
      removeProject(skill);
    }
  }
}

function removeGlobal(name: string): void {
  const currentList = getGlobalSkills();

  if (!currentList.split(",").some((e) => e.startsWith(`${name}:`))) {
    warn(`${skillName(name)} is not in global skills.`);
    return;
  }

  const newList = skillListRemove(currentList, name);
  globalConfigSet("global_skills", newList);
  success(`Removed ${skillName(name)} from global skills.`);
}

const KNOWN_PROJECT_DIRS = [".claude/rules", ".cursor/rules", ".opencode/rules", ".codex/rules"];

function removeProject(name: string): void {
  const currentList = getProjectSkills();

  if (!currentList.split(",").some((e) => e.startsWith(`${name}:`))) {
    warn(`${skillName(name)} is not installed in this project.`);
    return;
  }

  // Remove files from all known directories
  const projectRoot = findProjectRoot();
  for (const dir of KNOWN_PROJECT_DIRS) {
    const skillDir = join(projectRoot, dir, name);
    if (existsSync(skillDir)) {
      rmSync(skillDir, { recursive: true, force: true });
    }
  }
  // Also check install_dir in case it's a custom path not in the known list
  const installDir = projectConfigGet("install_dir", "");
  if (installDir && !KNOWN_PROJECT_DIRS.includes(installDir)) {
    const skillDir = join(projectRoot, installDir, name);
    if (existsSync(skillDir)) {
      rmSync(skillDir, { recursive: true, force: true });
    }
  }

  // Update config
  const newList = skillListRemove(currentList, name);
  projectConfigSet("skills", newList);
  success(`Removed ${skillName(name)} from project.`);
}
