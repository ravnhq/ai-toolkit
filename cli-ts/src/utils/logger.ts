import chalk from "chalk";

export function info(msg: string): void {
  console.log(`${chalk.white.bold("\u2192")} ${msg}`);
}

export function success(msg: string): void {
  console.log(`${chalk.green("\u2713")} ${msg}`);
}

export function warn(msg: string): void {
  console.error(`${chalk.yellow("!")} ${msg}`);
}

export function error(msg: string): void {
  console.error(`${chalk.red("\u2717")} ${chalk.red(msg)}`);
}

export function die(msg: string): never {
  error(msg);
  process.exit(1);
}

export function skillName(name: string): string {
  return chalk.cyan(name);
}

export function dim(msg: string): string {
  return chalk.dim(msg);
}

export function bold(msg: string): string {
  return chalk.white.bold(msg);
}
