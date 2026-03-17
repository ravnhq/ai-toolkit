import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import chalk from "chalk";
import { REPO_DIR, RAVENCITO_VERSION } from "../core/paths.js";

export function showBanner(): void {
  const bannerFile = join(REPO_DIR, "cli/assets/banner.txt");
  if (existsSync(bannerFile)) {
    console.log(chalk.cyan(readFileSync(bannerFile, "utf-8")));
  } else {
    console.log(`${chalk.cyan("ravencito")} \u2014 AI Skills Manager\n`);
  }
}

export function showLogo(): void {
  const logoFile = join(REPO_DIR, "cli/assets/logo.txt");
  if (existsSync(logoFile)) {
    console.log(chalk.cyan(readFileSync(logoFile, "utf-8")));
  } else {
    showBanner();
  }
}

export function showHelp(): void {
  const w = chalk.white.bold;
  console.log(`${w("ravencito")} \u2014 AI Skills Manager (v${RAVENCITO_VERSION})\n`);
  console.log(`${w("Usage:")}`);
  console.log("  ravencito                          Interactive skill picker (TUI)");
  console.log("  ravencito install <skills...>      Install skills to current project");
  console.log("  ravencito install --global <s...>  Install as global defaults");
  console.log("  ravencito install --recipe <name>  Install a predefined stack recipe");
  console.log("  ravencito update                   Pull latest + update installed skills");
  console.log("  ravencito list                     Browse available skills by category");
  console.log("  ravencito search <query>           Search skills by keyword or tag");
  console.log("  ravencito info <skill>             Preview skill details");
  console.log("  ravencito status                   Show installed vs latest versions");
  console.log("  ravencito remove <skill>           Uninstall a skill");
  console.log("  ravencito sync                     Sync team skills from .ravencitorc");
  console.log("  ravencito doctor                   Health check");
  console.log("  ravencito help                     Show this banner + help");
  console.log();
  console.log(`${w("Options:")}`);
  console.log("  --help, -h                         Show this help");
  console.log("  --version, -v                      Show version");
  console.log("  --logo                             Show full-size ravencito art");
  console.log();
}

export function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}
