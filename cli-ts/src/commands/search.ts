import chalk from "chalk";
import { ensureRegistry, registrySearch } from "../core/registry.js";
import { info, warn, die } from "../utils/logger.js";

export function cmdSearch(args: string[]): void {
  if (args.length === 0) {
    die("Usage: corvus search <query>");
  }

  const query = args.join(" ");
  ensureRegistry();

  const results = registrySearch(query);

  if (results.length === 0) {
    warn(`No skills found matching '${query}'`);
    console.log();
    info("Try broader terms or run 'corvus list' to see all skills.");
    return;
  }

  console.log();
  console.log(
    `${chalk.white.bold(`Search results for '${query}'`)} ${chalk.dim(`(${results.length} found)`)}`,
  );
  console.log();

  for (const s of results) {
    console.log(
      `  ${chalk.cyan(s.name.padEnd(30))} ${chalk.dim(`[${s.category}]`)}`,
    );
    console.log(`    ${chalk.dim(s.description)}`);
  }
  console.log();
}
