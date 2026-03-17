import { existsSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import chalk from "chalk";
import { configGet, findProjectRoot, parseSkillList } from "../core/config.js";
import { RAVENCITORC } from "../core/paths.js";
import {
  ensureRegistry,
  registrySkillSourceDir,
} from "../core/registry.js";
import { die, info, skillName, success, warn } from "../utils/logger.js";
import { copySkill } from "../utils/fs.js";

export function cmdSync(): void {
  ensureRegistry();

  const projectRoot = findProjectRoot();
  const rcFile = join(projectRoot, RAVENCITORC);

  if (!existsSync(rcFile)) {
    die("No .ravencitorc found in project. Nothing to sync.");
  }

  console.log();
  console.log(chalk.white.bold("Syncing skills from .ravencitorc"));
  console.log();

  const installDir = configGet(rcFile, "install_dir", "");
  if (!installDir) {
    die(".ravencitorc is missing install_dir. Run 'ravencito install' first.");
  }

  const skillList = configGet(rcFile, "skills", "");
  if (!skillList) {
    info("No skills listed in .ravencitorc.");
    return;
  }

  const targetDir = join(projectRoot, installDir);
  mkdirSync(targetDir, { recursive: true });

  let installed = 0;
  let skipped = 0;

  const entries = parseSkillList(skillList);
  for (const entry of entries) {
    const [name, version] = entry.split(":");
    const skillTarget = join(targetDir, name);

    // Already installed?
    if (existsSync(skillTarget)) {
      skipped++;
      console.log(
        `  ${chalk.dim(`${name} v${version} (already installed)`)}`,
      );
      continue;
    }

    const sourceDir = registrySkillSourceDir(name);
    if (!sourceDir) {
      warn(`${skillName(name)}: not found in registry, skipping`);
      continue;
    }
    if (!existsSync(sourceDir)) {
      warn(`${skillName(name)}: source missing, skipping`);
      continue;
    }

    copySkill(sourceDir, skillTarget);
    success(`${skillName(name)} v${version} installed`);
    installed++;
  }

  console.log();
  success(
    `Sync complete: ${installed} installed, ${skipped} already up to date.`,
  );
  console.log();
}
