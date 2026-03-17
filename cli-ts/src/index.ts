#!/usr/bin/env node

import { Command } from "commander";
import { RAVENCITO_VERSION } from "./core/paths.js";
import { ensureConfigDir } from "./core/config.js";
import { autoUpdateCheck } from "./core/updater.js";
import { showBanner, showHelp, showLogo } from "./tui/display.js";
import { cmdInstall } from "./commands/install.js";
import { cmdList } from "./commands/list.js";
import { cmdSearch } from "./commands/search.js";
import { cmdInfo } from "./commands/info.js";
import { cmdStatus } from "./commands/status.js";
import { cmdUpdate } from "./commands/update.js";
import { cmdRemove } from "./commands/remove.js";
import { cmdSync } from "./commands/sync.js";
import { cmdDoctor } from "./commands/doctor.js";

const program = new Command();

program
  .name("ravencito")
  .description("AI Skills Manager")
  .version(RAVENCITO_VERSION, "-v, --version")
  .option("--logo", "Show full-size ravencito art")
  .hook("preAction", () => {
    ensureConfigDir();
  });

// No-args → interactive TUI
program.action(async (opts) => {
  if (opts.logo) {
    showLogo();
    return;
  }
  // Default: interactive install
  await autoUpdateCheck();
  await cmdInstall([]);
});

program
  .command("help")
  .description("Show banner + help")
  .action(() => {
    showBanner();
    showHelp();
  });

program
  .command("install [skills...]")
  .description("Install skills to current project")
  .option("-g, --global", "Install as global defaults")
  .option("-r, --recipe <name>", "Install a predefined stack recipe")
  .option("--no-deps", "Skip automatic dependency resolution")
  .action(async (skills: string[], opts) => {
    await autoUpdateCheck();
    const args: string[] = [];
    if (opts.global) args.push("--global");
    if (opts.recipe) args.push("--recipe", opts.recipe);
    if (opts.deps === false) args.push("--no-deps");
    args.push(...skills);
    await cmdInstall(args);
  });

program
  .command("update")
  .description("Pull latest + update installed skills")
  .action(() => {
    cmdUpdate();
  });

program
  .command("list [category]")
  .description("Browse available skills by category")
  .action((category?: string) => {
    const args = category ? [category] : [];
    cmdList(args);
  });

program
  .command("search <query...>")
  .description("Search skills by keyword or tag")
  .action((query: string[]) => {
    cmdSearch(query);
  });

program
  .command("info <skill>")
  .description("Preview skill details")
  .action((skill: string) => {
    cmdInfo([skill]);
  });

program
  .command("status")
  .description("Show installed vs latest versions")
  .action(() => {
    cmdStatus();
  });

program
  .command("remove <skills...>")
  .description("Uninstall a skill")
  .option("-g, --global", "Remove from global defaults")
  .action((skills: string[], opts) => {
    const args: string[] = [];
    if (opts.global) args.push("--global");
    args.push(...skills);
    cmdRemove(args);
  });

program
  .command("sync")
  .description("Sync team skills from .ravencitorc")
  .action(() => {
    cmdSync();
  });

program
  .command("doctor")
  .description("Health check")
  .action(() => {
    cmdDoctor();
  });

program.parseAsync().catch((err: unknown) => {
  // Gracefully handle Ctrl+C / ESC during interactive prompts
  if (
    err != null &&
    typeof err === "object" &&
    "name" in err &&
    (err as { name: string }).name === "ExitPromptError"
  ) {
    process.exit(0);
  }
  throw err;
});
