import { describe, it, expect, beforeEach } from "vitest";
import { mkdtempSync, writeFileSync, mkdirSync, existsSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { tmpdir } from "node:os";
import {
  configGet,
  configSet,
  parseSkillList,
  skillListUpsert,
  skillListRemove,
  skillVersionFromList,
  normalizeProjectInstallDirValue,
  migrateLegacyProjectInstallDirIfNeeded,
} from "../src/core/config.js";
import { CORVUSRC } from "../src/core/paths.js";

function tmpFile(): string {
  const dir = mkdtempSync(join(tmpdir(), "corvus-test-"));
  return join(dir, "config");
}

describe("configGet", () => {
  it("returns default when file missing", () => {
    expect(configGet("/nonexistent/path/config", "key", "default")).toBe("default");
  });

  it("reads existing key from file", () => {
    const file = tmpFile();
    writeFileSync(file, "foo=bar\n");
    expect(configGet(file, "foo", "")).toBe("bar");
  });

  it("returns default when key missing in file", () => {
    const file = tmpFile();
    writeFileSync(file, "other=value\n");
    expect(configGet(file, "missing", "fallback")).toBe("fallback");
  });
});

describe("configSet", () => {
  it("creates file with key=value when file does not exist", () => {
    const file = tmpFile();
    configSet(file, "name", "ravencito");
    expect(configGet(file, "name", "")).toBe("ravencito");
  });

  it("updates existing key", () => {
    const file = tmpFile();
    configSet(file, "key", "old");
    configSet(file, "key", "new");
    expect(configGet(file, "key", "")).toBe("new");
  });

  it("appends new key to existing file", () => {
    const file = tmpFile();
    configSet(file, "first", "1");
    configSet(file, "second", "2");
    expect(configGet(file, "first", "")).toBe("1");
    expect(configGet(file, "second", "")).toBe("2");
  });
});

describe("parseSkillList", () => {
  it("returns empty array for empty string", () => {
    expect(parseSkillList("")).toEqual([]);
  });

  it("parses single entry", () => {
    expect(parseSkillList("tech-react:5")).toEqual(["tech-react:5"]);
  });

  it("parses multiple entries", () => {
    expect(parseSkillList("tech-react:5,lang-typescript:3")).toEqual([
      "tech-react:5",
      "lang-typescript:3",
    ]);
  });

  it("filters empty segments", () => {
    expect(parseSkillList("tech-react:5,,lang-typescript:3")).toEqual([
      "tech-react:5",
      "lang-typescript:3",
    ]);
  });
});

describe("skillListUpsert", () => {
  it("inserts into empty list", () => {
    expect(skillListUpsert("", "tech-react", "5")).toBe("tech-react:5");
  });

  it("updates existing skill version", () => {
    const list = skillListUpsert("tech-react:5", "tech-react", "6");
    expect(list).toBe("tech-react:6");
  });

  it("appends new skill to existing list", () => {
    const list = skillListUpsert("lang-typescript:3", "tech-react", "5");
    expect(list).toBe("lang-typescript:3,tech-react:5");
  });
});

describe("skillListRemove", () => {
  it("removes entry from list", () => {
    const list = skillListRemove("tech-react:5,lang-typescript:3", "tech-react");
    expect(list).toBe("lang-typescript:3");
  });

  it("no-op when name not in list", () => {
    const list = skillListRemove("lang-typescript:3", "tech-react");
    expect(list).toBe("lang-typescript:3");
  });
});

describe("skillVersionFromList", () => {
  it("finds version for existing skill", () => {
    expect(skillVersionFromList("tech-react:5,lang-typescript:3", "tech-react")).toBe("5");
  });

  it("returns null when skill not in list", () => {
    expect(skillVersionFromList("lang-typescript:3", "tech-react")).toBeNull();
  });
});

describe("normalizeProjectInstallDirValue", () => {
  it("trims, strips trailing slashes, strips ./ and normalizes backslashes", () => {
    expect(normalizeProjectInstallDirValue(`  ./.claude/rules/  `)).toBe(".claude/rules");
    expect(normalizeProjectInstallDirValue(`.\\.cursor\\rules`)).toBe(".cursor/rules");
  });
});

describe("migrateLegacyProjectInstallDirIfNeeded", () => {
  it("moves on-disk skills from .claude/rules to .claude/skills", () => {
    const projectRoot = mkdtempSync(join(tmpdir(), "corvus-install-migrate-fs-"));
    const legacyFile = join(projectRoot, ".claude", "rules", "demo-skill", "SKILL.md");
    mkdirSync(dirname(legacyFile), { recursive: true });
    writeFileSync(legacyFile, "# skill\n");
    const rc = join(projectRoot, CORVUSRC);
    writeFileSync(rc, "install_dir=.claude/rules\nskills=demo-skill:1\n");
    expect(migrateLegacyProjectInstallDirIfNeeded({ projectRoot })).toBe(true);
    const moved = join(projectRoot, ".claude", "skills", "demo-skill", "SKILL.md");
    expect(existsSync(moved)).toBe(true);
    expect(readFileSync(moved, "utf-8")).toContain("# skill");
    expect(existsSync(join(projectRoot, ".claude", "rules"))).toBe(false);
    expect(configGet(rc, "install_dir", "")).toBe(".claude/skills");
  });

  it("merges legacy .claude/rules entries into an existing .claude/skills tree", () => {
    const projectRoot = mkdtempSync(join(tmpdir(), "corvus-install-migrate-merge-"));
    const onlyLegacy = join(projectRoot, ".claude", "rules", "skill-a", "a.txt");
    mkdirSync(dirname(onlyLegacy), { recursive: true });
    writeFileSync(onlyLegacy, "a");
    const onlyCanon = join(projectRoot, ".claude", "skills", "skill-b", "b.txt");
    mkdirSync(dirname(onlyCanon), { recursive: true });
    writeFileSync(onlyCanon, "b");
    const rc = join(projectRoot, CORVUSRC);
    writeFileSync(rc, "install_dir=.claude/rules\nskills=skill-a:1,skill-b:1\n");
    expect(migrateLegacyProjectInstallDirIfNeeded({ projectRoot })).toBe(true);
    expect(existsSync(join(projectRoot, ".claude", "skills", "skill-a", "a.txt"))).toBe(true);
    expect(existsSync(join(projectRoot, ".claude", "skills", "skill-b", "b.txt"))).toBe(true);
    expect(existsSync(join(projectRoot, ".claude", "rules"))).toBe(false);
    expect(configGet(rc, "install_dir", "")).toBe(".claude/skills");
  });

  it("rewrites legacy .claude/rules to .claude/skills in .corvusrc", () => {
    const projectRoot = mkdtempSync(join(tmpdir(), "corvus-install-migrate-"));
    const rc = join(projectRoot, CORVUSRC);
    writeFileSync(rc, "install_dir=.claude/rules\nskills=foo:1\n");
    expect(migrateLegacyProjectInstallDirIfNeeded({ projectRoot })).toBe(true);
    expect(configGet(rc, "install_dir", "")).toBe(".claude/skills");
  });

  it("rewrites legacy .cursor/rules to .cursor/skills", () => {
    const projectRoot = mkdtempSync(join(tmpdir(), "corvus-install-migrate-"));
    const rc = join(projectRoot, CORVUSRC);
    writeFileSync(rc, "install_dir=.cursor/rules\nskills=foo:1\n");
    expect(migrateLegacyProjectInstallDirIfNeeded({ projectRoot })).toBe(true);
    expect(configGet(rc, "install_dir", "")).toBe(".cursor/skills");
  });

  it("does not change unrelated install_dir values", () => {
    const projectRoot = mkdtempSync(join(tmpdir(), "corvus-install-migrate-"));
    const rc = join(projectRoot, CORVUSRC);
    writeFileSync(rc, "install_dir=.opencode/rules\nskills=foo:1\n");
    expect(migrateLegacyProjectInstallDirIfNeeded({ projectRoot })).toBe(false);
    expect(configGet(rc, "install_dir", "")).toBe(".opencode/rules");
  });

  it("returns false when .corvusrc is missing", () => {
    const projectRoot = mkdtempSync(join(tmpdir(), "corvus-install-migrate-"));
    expect(migrateLegacyProjectInstallDirIfNeeded({ projectRoot })).toBe(false);
  });

  it("does not rewrite again once install_dir is already canonical", () => {
    const projectRoot = mkdtempSync(join(tmpdir(), "corvus-install-migrate-"));
    const rc = join(projectRoot, CORVUSRC);
    writeFileSync(rc, "install_dir=.claude/skills\nskills=foo:1\n");
    expect(migrateLegacyProjectInstallDirIfNeeded({ projectRoot })).toBe(false);
    expect(configGet(rc, "install_dir", "")).toBe(".claude/skills");
  });
});
