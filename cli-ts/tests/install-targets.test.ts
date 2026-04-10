import { describe, it, expect } from "vitest";
import { homedir } from "node:os";
import { resolveTargetDir, isGlobalTarget, targetLabel } from "../src/commands/install.js";

describe("resolveTargetDir", () => {
  it("project-claude ends with .claude/rules", () => {
    expect(resolveTargetDir("project-claude")).toMatch(/\.claude\/rules$/);
  });

  it("project-cursor ends with .cursor/rules", () => {
    expect(resolveTargetDir("project-cursor")).toMatch(/\.cursor\/rules$/);
  });

  it("project-codex ends with .codex/rules", () => {
    expect(resolveTargetDir("project-codex")).toMatch(/\.codex\/rules$/);
  });

  it("global-claude starts with homedir and ends with .claude/rules", () => {
    const dir = resolveTargetDir("global-claude");
    expect(dir).toMatch(/\.claude\/rules$/);
    expect(dir.startsWith(homedir())).toBe(true);
  });

  it("global-cursor starts with homedir and ends with .cursor/rules", () => {
    const dir = resolveTargetDir("global-cursor");
    expect(dir).toMatch(/\.cursor\/rules$/);
    expect(dir.startsWith(homedir())).toBe(true);
  });

  it("global-codex returns ~/.codex/rules", () => {
    const dir = resolveTargetDir("global-codex");
    expect(dir).toMatch(/\.codex\/rules$/);
    expect(dir.startsWith(homedir())).toBe(true);
  });

  it("custom returns the provided path", () => {
    expect(resolveTargetDir("custom", "/my/path")).toBe("/my/path");
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
  it("project-claude → .claude/rules", () => {
    expect(targetLabel("project-claude")).toBe(".claude/rules");
  });

  it("project-cursor → .cursor/rules", () => {
    expect(targetLabel("project-cursor")).toBe(".cursor/rules");
  });

  it("project-codex → .codex/rules", () => {
    expect(targetLabel("project-codex")).toBe(".codex/rules");
  });

  it("global-claude → ~/.claude/rules", () => {
    expect(targetLabel("global-claude")).toBe("~/.claude/rules");
  });

  it("global-cursor → ~/.cursor/rules", () => {
    expect(targetLabel("global-cursor")).toBe("~/.cursor/rules");
  });

  it("global-codex → ~/.codex/rules", () => {
    expect(targetLabel("global-codex")).toBe("~/.codex/rules");
  });

  it("custom → returns provided custom path", () => {
    expect(targetLabel("custom", "/my/custom/path")).toBe("/my/custom/path");
  });
});
