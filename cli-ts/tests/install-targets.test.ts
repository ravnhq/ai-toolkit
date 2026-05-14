import { describe, it, expect } from "vitest";
import { homedir } from "node:os";
import { join } from "node:path";
import {
  resolveTargetDir,
  isGlobalTarget,
  targetLabel,
  globalSkillInstallParents,
} from "../src/commands/install.js";

describe("resolveTargetDir", () => {
  it("project-claude ends with .claude/skills", () => {
    expect(resolveTargetDir("project-claude")).toMatch(/[\\/]\.claude[\\/]skills$/);
  });

  it("project-cursor ends with .cursor/skills", () => {
    expect(resolveTargetDir("project-cursor")).toMatch(/[\\/]\.cursor[\\/]skills$/);
  });

  it("project-codex ends with .codex/rules", () => {
    expect(resolveTargetDir("project-codex")).toMatch(/[\\/]\.codex[\\/]rules$/);
  });

  it("global-claude starts with homedir and ends with .claude/skills", () => {
    const dir = resolveTargetDir("global-claude");
    expect(dir).toMatch(/[\\/]\.claude[\\/]skills$/);
    expect(dir.startsWith(homedir())).toBe(true);
  });

  it("global-cursor starts with homedir and ends with .cursor/skills", () => {
    const dir = resolveTargetDir("global-cursor");
    expect(dir).toMatch(/[\\/]\.cursor[\\/]skills$/);
    expect(dir.startsWith(homedir())).toBe(true);
  });

  it("global-codex returns ~/.codex/rules", () => {
    const dir = resolveTargetDir("global-codex");
    expect(dir).toMatch(/[\\/]\.codex[\\/]rules$/);
    expect(dir.startsWith(homedir())).toBe(true);
  });

  it("custom returns the provided path", () => {
    expect(resolveTargetDir("custom", "/my/path")).toBe("/my/path");
  });
});

describe("globalSkillInstallParents", () => {
  it("covers each global target dir plus legacy Claude and Cursor rules", () => {
    const home = homedir();
    const parents = globalSkillInstallParents();
    expect(parents).toContain(resolveTargetDir("global-claude"));
    expect(parents).toContain(resolveTargetDir("global-cursor"));
    expect(parents).toContain(resolveTargetDir("global-opencode"));
    expect(parents).toContain(resolveTargetDir("global-codex"));
    expect(parents).toContain(join(home, ".claude", "rules"));
    expect(parents).toContain(join(home, ".cursor", "rules"));
    expect(parents.length).toBe(6);
  });
});

describe("isGlobalTarget", () => {
  it("returns true for global-claude", () => {
    expect(isGlobalTarget("global-claude")).toBe(true);
  });

  it("returns true for global-cursor", () => {
    expect(isGlobalTarget("global-cursor")).toBe(true);
  });

  it("returns true for global-codex", () => {
    expect(isGlobalTarget("global-codex")).toBe(true);
  });

  it("returns false for project-claude", () => {
    expect(isGlobalTarget("project-claude")).toBe(false);
  });

  it("returns false for project-cursor", () => {
    expect(isGlobalTarget("project-cursor")).toBe(false);
  });
});

describe("targetLabel", () => {
  it("project-claude → .claude/skills", () => {
    expect(targetLabel("project-claude")).toBe(".claude/skills");
  });

  it("project-cursor → .cursor/skills", () => {
    expect(targetLabel("project-cursor")).toBe(".cursor/skills");
  });

  it("project-codex → .codex/rules", () => {
    expect(targetLabel("project-codex")).toBe(".codex/rules");
  });

  it("global-claude → ~/.claude/skills", () => {
    expect(targetLabel("global-claude")).toBe("~/.claude/skills");
  });

  it("global-cursor → ~/.cursor/skills", () => {
    expect(targetLabel("global-cursor")).toBe("~/.cursor/skills");
  });

  it("global-codex → ~/.codex/rules", () => {
    expect(targetLabel("global-codex")).toBe("~/.codex/rules");
  });

  it("custom → returns provided custom path", () => {
    expect(targetLabel("custom", "/my/custom/path")).toBe("/my/custom/path");
  });
});
