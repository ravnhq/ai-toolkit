import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import {
  findProjectRoot,
  getProjectSkills,
  parseSkillList,
  projectConfigGet,
} from "../core/config.js";
import { info, success } from "../utils/logger.js";

const SECTION_START = "# corvus — managed, do not edit this block";
const SECTION_END = "# end corvus";

export function cmdGitignore(): void {
  const projectRoot = findProjectRoot();
  const gitignorePath = join(projectRoot, ".gitignore");

  const installDir = projectConfigGet("install_dir", ".claude/rules");
  const skillEntries = parseSkillList(getProjectSkills())
    .map((entry) => entry.split(":")[0])
    .map((name) => `${installDir}/${name}/`);

  const lines = [SECTION_START, ".corvusrc", ...skillEntries, SECTION_END];

  let content = existsSync(gitignorePath)
    ? readFileSync(gitignorePath, "utf-8")
    : "";

  const startIdx = content.indexOf(SECTION_START);
  const endIdx = content.indexOf(SECTION_END);

  if (startIdx !== -1 && endIdx !== -1) {
    content =
      content.slice(0, startIdx) +
      lines.join("\n") +
      content.slice(endIdx + SECTION_END.length);
    info("Updated corvus section in .gitignore");
  } else {
    const sep =
      content.length > 0 && !content.endsWith("\n")
        ? "\n\n"
        : content.length > 0
          ? "\n"
          : "";
    content = content + sep + lines.join("\n") + "\n";
    info("Added corvus section to .gitignore");
  }

  writeFileSync(gitignorePath, content);
  success(
    `.corvusrc and ${skillEntries.length} skill path(s) added to .gitignore`,
  );
}
