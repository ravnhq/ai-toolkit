import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import chalk from "chalk";
import { execSync } from "node:child_process";
import {
  configGet,
  findProjectRoot,
  parseSkillList,
} from "../core/config.js";
import {
  CORVUS_DIR,
  CORVUSRC,
  REPO_DIR,
  MARKETPLACE_PATH,
  CORVUS_CONFIG,
} from "../core/paths.js";
import { registrySkillExists, ensureRegistry } from "../core/registry.js";
import { success, warn } from "../utils/logger.js";
import { hasCmd } from "../utils/platform.js";

const nl = () => console.log(); // blank line for terminal spacing

export function cmdDoctor(): void {
  nl();
  console.log(chalk.white.bold("corvus doctor"));
  nl();

  let issues = 0;

  // Installation checks
  issues += check("corvus directory", existsSync(CORVUS_DIR));
  issues += check(
    "Repository cache",
    existsSync(join(REPO_DIR, ".git")),
  );
  issues += check("Config file", existsSync(CORVUS_CONFIG));
  issues += check("marketplace.json", existsSync(MARKETPLACE_PATH));

  // Dependencies
  nl();
  console.log(chalk.white.bold("Dependencies"));
  checkCmd("git");
  checkCmd("node");
  checkCmdOptional("bun", "Bun runtime (for compiled binaries)");

  // Project context
  nl();
  console.log(chalk.white.bold("Project"));

  const projectRoot = findProjectRoot();
  const rcFile = join(projectRoot, CORVUSRC);

  if (existsSync(rcFile)) {
    success(`.corvusrc found at ${rcFile}`);

    const installDir = configGet(rcFile, "install_dir", "");
    if (installDir) {
      const target = join(projectRoot, installDir);
      if (existsSync(target)) {
        success(`Install directory exists: ${installDir}`);

        // Check for orphaned skills
        const skillList = configGet(rcFile, "skills", "");
        try {
          const dirSkills = readdirSync(target);
          if (dirSkills.length > 0 && skillList) {
            for (const dirSkill of dirSkills) {
              const inConfig = skillList
                .split(",")
                .some((e) => e.startsWith(`${dirSkill}:`));
              if (!inConfig) {
                warn(
                  `Orphaned skill directory: ${installDir}/${dirSkill}`,
                );
                issues++;
              }
            }
          }
        } catch {
          // ignore read errors
        }
      } else {
        warn(`Install directory missing: ${installDir}`);
        issues++;
      }
    }

    // Check skills in registry
    const skills = configGet(rcFile, "skills", "");
    if (skills) {
      try {
        ensureRegistry();
        const entries = parseSkillList(skills);
        for (const entry of entries) {
          const name = entry.split(":")[0];
          if (!registrySkillExists(name)) {
            warn(`Skill '${name}' not found in registry`);
            issues++;
          }
        }
      } catch {
        // registry not available
      }
    }
  } else {
    console.log(chalk.dim("  No .corvusrc in current project"));
  }

  // Summary
  nl();
  if (issues === 0) {
    success("All checks passed! corvus is healthy.");
  } else {
    warn(
      `${issues} issue(s) found. Run 'corvus update' to fix most issues.`,
    );
  }
  nl();
}

function check(label: string, condition: boolean): number {
  if (condition) {
    success(label);
    return 0;
  } else {
    warn(`${label} \u2014 missing`);
    return 1;
  }
}

function checkCmd(cmd: string): void {
  if (hasCmd(cmd)) {
    let ver = "found";
    try {
      ver = execSync(`${cmd} --version`, {
        encoding: "utf-8",
        stdio: ["pipe", "pipe", "pipe"],
      })
        .trim()
        .split("\n")[0];
    } catch {
      // ignore
    }
    success(`${cmd}: ${ver}`);
  } else {
    warn(`${cmd}: not found`);
  }
}

function checkCmdOptional(cmd: string, desc: string): void {
  if (hasCmd(cmd)) {
    success(`${cmd}: found (${desc})`);
  } else {
    console.log(chalk.dim(`  ${cmd}: not found (${desc})`));
  }
}
