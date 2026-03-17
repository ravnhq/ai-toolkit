import {
  existsSync,
  cpSync,
  mkdirSync,
  rmSync,
} from "node:fs";
import { join } from "node:path";

/**
 * Copy a skill from source directory to target directory.
 * Copies: SKILL.md, rules/, references/, scripts/, assets/
 */
export function copySkill(sourceDir: string, targetDir: string): void {
  // Remove existing if present
  if (existsSync(targetDir)) {
    rmSync(targetDir, { recursive: true, force: true });
  }
  mkdirSync(targetDir, { recursive: true });

  const items = ["SKILL.md", "rules", "references", "scripts", "assets"];
  for (const item of items) {
    const src = join(sourceDir, item);
    if (existsSync(src)) {
      cpSync(src, join(targetDir, item), { recursive: true });
    }
  }
}
