#!/usr/bin/env node

import { Command } from "commander";
import { RAVENCITO_VERSION } from "./core/paths.js";
import { ensureConfigDir } from "./core/config.js";
import { autoUpdateCheck } from "./core/updater.js";
import { showBanner, showLogo } from "./tui/display.js";
import { cmdInstall } from "./commands/install.js";
import { cmdList } from "./commands/list.js";
import { cmdSearch } from "./commands/search.js";
import { cmdInfo } from "./commands/info.js";
import { cmdStatus } from "./commands/status.js";
import { cmdUpdate } from "./commands/update.js";
import { cmdRemove } from "./commands/remove.js";
import { cmdSync } from "./commands/sync.js";
import { cmdDoctor } from "./commands/doctor.js";
import { cmdShowerThought } from "./commands/shower-thought.js";
import { cmdCompletions } from "./commands/completions.js";

function isExitPromptError(err: unknown): boolean {
  return (
    err != null &&
    typeof err === "object" &&
    "name" in err &&
    (err as { name: string }).name === "ExitPromptError"
  );
}

// Handle --logo before parsing
if (process.argv.includes("--logo")) {
  showLogo();
  process.exit(0);
}

// No args → interactive TUI
if (process.argv.length <= 2) {
  ensureConfigDir();
  await autoUpdateCheck();
  cmdShowerThought();
  try {
    await cmdInstall([]);
  } catch (err: unknown) {
    if (isExitPromptError(err)) {
      process.exit(0);
    }
    throw err;
  }
  process.exit(0);
}

const program = new Command();

program
  .name("ravencito")
  .description("AI Skills Manager")
  .version(RAVENCITO_VERSION, "-v, --version")
  .showHelpAfterError('Run "ravencito --help" for usage information.')
  .addHelpText("before", () => { showBanner(); return ""; })
  .hook("preAction", () => {
    ensureConfigDir();
  });

program
  .command("install [skills...]")
  .description("Install skills to a target location")
  .option("-g, --global", "Install to global (Claude Code by default)")
  .option("--claude", "Target Claude Code (.claude/rules)")
  .option("--cursor", "Target Cursor (.cursor/rules)")
  .option("--codex", "Target Codex (.codex/rules)")
  .option("--global-claude", "Install to ~/.claude/rules")
  .option("--global-cursor", "Install to ~/.cursor/rules")
  .option("--global-codex", "Install to ~/.codex/rules")
  .option("-r, --recipe <name>", "Install a predefined stack recipe")
  .option("--no-deps", "Skip automatic dependency resolution")
  .action(async (skills: string[], opts) => {
    await autoUpdateCheck();
    const args: string[] = [];
    if (opts.global) args.push("--global");
    if (opts.claude) args.push("--claude");
    if (opts.cursor) args.push("--cursor");
    if (opts.codex) args.push("--codex");
    if (opts.globalClaude) args.push("--global-claude");
    if (opts.globalCursor) args.push("--global-cursor");
    if (opts.globalCodex) args.push("--global-codex");
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

program
  .command("completions")
  .description("Print shell completion setup instructions")
  .option("-s, --shell <shell>", "Shell type (zsh, bash, or fish)")
  .action((opts) => {
    cmdCompletions(opts.shell);
  });

program
  .command("shower-thought")
  .alias("shower-thoughts")
  .description("Random shower thought from Dave")
  .action(() => {
    cmdShowerThought();
  });

program.parseAsync().catch((err: unknown) => {
  // Gracefully handle Ctrl+C / ESC during interactive prompts
  if (isExitPromptError(err)) {
    process.exit(0);
  }
  throw err;
});
