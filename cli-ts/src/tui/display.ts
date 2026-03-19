import { existsSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import chalk from "chalk";

const ASSETS_DIR = join(dirname(fileURLToPath(import.meta.url)), "../../assets");

export function showBanner(): void {
  const bannerFile = join(ASSETS_DIR, "banner.txt");
  if (existsSync(bannerFile)) {
    console.log(chalk.cyan(readFileSync(bannerFile, "utf-8")));
  } else {
    console.log(`${chalk.cyan("ravencito")} \u2014 AI Skills Manager\n`);
  }
}

export function showLogo(): void {
  const logoFile = join(ASSETS_DIR, "logo.txt");
  if (existsSync(logoFile)) {
    console.log(chalk.cyan(readFileSync(logoFile, "utf-8")));
  } else {
    showBanner();
  }
}

export function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}
