import { existsSync } from "node:fs";
import { join } from "node:path";
import chalk from "chalk";
import {
  findProjectRoot,
  getGlobalSkills,
  getProjectSkills,
  globalConfigSet,
  parseSkillList,
  projectConfigSet,
  skillListUpsert,
  projectConfigGet,
} from "../core/config.js";
import {
  clearRegistryCache,
  ensureRegistry,
  registrySkillSourceDir,
  registrySkillVersion,
} from "../core/registry.js";
import { CORVUSRC, REPO_DIR } from "../core/paths.js";
import { touchLastUpdate } from "../core/updater.js";
import { info, success, warn, die, skillName } from "../utils/logger.js";
import { gitPull } from "../utils/git.js";
import { copySkill } from "../utils/fs.js";

export function cmdUpdate(): void {
  console.log();
  console.log(chalk.white.bold("Updating corvus"));
  console.log();

  // Update repo cache
  if (existsSync(join(REPO_DIR, ".git"))) {
    info("Pulling latest changes...");
    if (gitPull(REPO_DIR)) {
      success("Repository updated");
    } else {
      warn("Could not update repository (offline?)");
    }
  } else {
    die("Repository not found. Run the installer again.");
  }

  touchLastUpdate();
  clearRegistryCache();
  ensureRegistry();

  // Update project skills
  const projectRoot = findProjectRoot();
  const rcFile = join(projectRoot, CORVUSRC);

  if (existsSync(rcFile)) {
    console.log();
    info("Updating project skills...");

    const installDir = projectConfigGet("install_dir", "");
    const projectSkills = getProjectSkills();

    if (projectSkills && installDir) {
      const targetDir = join(projectRoot, installDir);
      let updated = 0;

      const entries = parseSkillList(projectSkills);
      for (const entry of entries) {
        const [name, installedVer] = entry.split(":");
        const latestVer = registrySkillVersion(name);

        if (!latestVer) {
          warn(`${skillName(name)}: not found in registry`);
          continue;
        }

        if (installedVer !== latestVer) {
          const sourceDir = registrySkillSourceDir(name);
          if (sourceDir && existsSync(sourceDir)) {
            const skillTarget = join(targetDir, name);
            copySkill(sourceDir, skillTarget);

            // Update version in config
            let currentList = getProjectSkills();
            currentList = skillListUpsert(currentList, name, latestVer);
            projectConfigSet("skills", currentList);

            success(`${skillName(name)} v${installedVer} \u2192 v${latestVer}`);
            updated++;
          }
        }
      }

      if (updated === 0) {
        success("All project skills are up to date!");
      } else {
        console.log();
        success(`${updated} skill(s) updated.`);
      }
    }
  }

  // Update global skill versions
  const globalSkills = getGlobalSkills();
  if (globalSkills) {
    console.log();
    info("Checking global skills...");

    const entries = parseSkillList(globalSkills);
    const newEntries: string[] = [];
    let gUpdated = 0;

    for (const entry of entries) {
      const [name, installedVer] = entry.split(":");
      const latestVer = registrySkillVersion(name) || installedVer;
      newEntries.push(`${name}:${latestVer}`);
      if (installedVer !== latestVer) {
        success(`${skillName(name)} v${installedVer} \u2192 v${latestVer}`);
        gUpdated++;
      }
    }

    globalConfigSet("global_skills", newEntries.join(","));
    if (gUpdated === 0) {
      success("All global skills are up to date!");
    }
  }

  console.log();
}
