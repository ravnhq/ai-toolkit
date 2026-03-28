import chalk from "chalk";
import {
  ensureRegistry,
  registrySkillVersion,
} from "../core/registry.js";
import {
  findProjectRoot,
  getGlobalSkills,
  getProjectSkills,
  parseSkillList,
  projectConfigGet,
} from "../core/config.js";
import { CORVUSRC } from "../core/paths.js";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { info } from "../utils/logger.js";

export function cmdStatus(): void {
  ensureRegistry();

  console.log();
  console.log(chalk.white.bold("Skill Status"));
  console.log();

  // Global skills
  const globalSkills = getGlobalSkills();
  process.stdout.write(chalk.white.bold("Global Skills"));
  if (!globalSkills) {
    console.log(` ${chalk.dim("(none)")}`);
    info("Run 'corvus install --global <skill>' to add global defaults.");
  } else {
    console.log();
    showSkillStatus(globalSkills);
  }
  console.log();

  // Project skills
  const projectRoot = findProjectRoot();
  const rcFile = join(projectRoot, CORVUSRC);

  process.stdout.write(
    `${chalk.white.bold("Project Skills")} ${chalk.dim(`(${projectRoot})`)}`,
  );

  if (!existsSync(rcFile)) {
    console.log(` ${chalk.dim("(no .corvusrc)")}`);
    info("Run 'corvus install <skill>' in a project to get started.");
  } else {
    console.log();
    const projectSkills = getProjectSkills();
    const installDir = projectConfigGet("install_dir", "");

    if (installDir) {
      console.log(`  ${chalk.dim(`Install dir: ${installDir}`)}`);
    }

    if (!projectSkills) {
      info("No skills installed in this project.");
    } else {
      showSkillStatus(projectSkills);
    }
  }
  console.log();
}

function showSkillStatus(skillList: string): void {
  console.log(
    `  ${chalk.dim("SKILL".padEnd(30))} ${chalk.dim("INSTALLED".padEnd(10))} ${chalk.dim("LATEST".padEnd(10))} ${chalk.dim("STATUS")}`,
  );

  const entries = parseSkillList(skillList);
  for (const entry of entries) {
    const [name, installedVer] = entry.split(":");
    let latestVer: string;
    try {
      latestVer = registrySkillVersion(name) || "?";
    } catch {
      latestVer = "?";
    }

    let statusIcon: string;
    let statusColor: (s: string) => string;

    if (latestVer === "?") {
      statusIcon = "?";
      statusColor = chalk.yellow;
    } else if (installedVer === latestVer) {
      statusIcon = "\u2713";
      statusColor = chalk.green;
    } else {
      statusIcon = "\u2191";
      statusColor = chalk.yellow;
    }

    console.log(
      `  ${chalk.cyan(name.padEnd(30))} v${(installedVer ?? "?").toString().padEnd(9)} v${latestVer.padEnd(9)} ${statusColor(statusIcon)}`,
    );
  }
}
