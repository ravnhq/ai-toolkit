import chalk from "chalk";
import {
  ensureRegistry,
  registrySkillCount,
  registryCategories,
  registrySkillsByCategory,
} from "../core/registry.js";
import { capitalize } from "../tui/display.js";

const CATEGORY_ORDER = [
  "universal",
  "platform",
  "framework",
  "design",
  "assistant",
];

export function cmdList(args: string[]): void {
  ensureRegistry();

  const filter = args[0] ?? "";
  const total = registrySkillCount();
  const categories = registryCategories();

  console.log();
  console.log(
    `${chalk.white.bold("Available Skills")} ${chalk.dim(`(${total} total)`)}`,
  );
  console.log();

  for (const cat of CATEGORY_ORDER) {
    const count = categories.get(cat);
    if (!count) continue;
    if (filter && cat !== filter) continue;

    console.log(
      `${chalk.white.bold(capitalize(cat))} ${chalk.dim(`(${count})`)}`,
    );

    const skills = registrySkillsByCategory(cat);
    for (const s of skills) {
      const extendsLabel = s.extends
        ? ` ${chalk.dim(`\u2190 ${s.extends}`)}`
        : "";
      console.log(
        `  ${chalk.cyan(s.name.padEnd(30))}${extendsLabel}`,
      );
      console.log(`    ${chalk.dim(s.description)}`);
    }

    console.log();
  }
}
