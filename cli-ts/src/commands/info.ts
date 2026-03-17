import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join, basename } from "node:path";
import chalk from "chalk";
import {
  ensureRegistry,
  registrySkillExists,
  registrySkillInfo,
  registryResolveDeps,
  registrySearch,
  registrySkillSourceDir,
} from "../core/registry.js";
import { error, info, die } from "../utils/logger.js";

export function cmdInfo(args: string[]): void {
  if (args.length === 0) {
    die("Usage: ravencito info <skill-name>");
  }

  const name = args[0];
  ensureRegistry();

  if (!registrySkillExists(name)) {
    error(`Skill not found: ${name}`);
    console.log();
    info("Did you mean one of these?");
    const matches = registrySearch(name).slice(0, 5);
    for (const m of matches) {
      console.log(`  ${chalk.cyan(m.name)}`);
    }
    process.exit(1);
  }

  console.log();
  console.log(chalk.white.bold("Skill Details"));
  console.log(chalk.dim("\u2500".repeat(41)));
  console.log(registrySkillInfo(name));
  console.log();

  // Dependency chain
  const deps = registryResolveDeps(name);
  if (deps.length > 1) {
    console.log(chalk.white.bold("Dependency Chain:"));
    const chain = deps
      .map((d, i) =>
        i === 0 ? chalk.dim(d) : `${chalk.dim("\u2192")} ${chalk.cyan(d)}`,
      )
      .join(" ");
    console.log(`  ${chain}`);
    console.log();
  }

  // Show rules if source exists
  const sourceDir = registrySkillSourceDir(name);
  const rulesDir = sourceDir ? join(sourceDir, "rules") : "";

  if (rulesDir && existsSync(rulesDir)) {
    const ruleFiles = readdirSync(rulesDir)
      .filter((f) => f.endsWith(".md") && !f.startsWith("_"))
      .sort();

    if (ruleFiles.length > 0) {
      console.log(
        `${chalk.white.bold("Rules")} ${chalk.dim(`(${ruleFiles.length})`)}:`,
      );
      for (const file of ruleFiles) {
        const ruleName = basename(file, ".md");
        const content = readFileSync(join(rulesDir, file), "utf-8");
        const titleMatch = content.match(/^title:\s*(.+)/m);
        const title = titleMatch?.[1] ?? "";

        if (title) {
          console.log(
            `  ${chalk.cyan(ruleName.padEnd(35))} ${title}`,
          );
        } else {
          console.log(`  ${chalk.cyan(ruleName)}`);
        }
      }
      console.log();
    }
  }

  console.log(chalk.white.bold("Install:"));
  console.log(`  ravencito install ${name}`);
  console.log(`  ravencito install --global ${name}`);
  console.log();
}
