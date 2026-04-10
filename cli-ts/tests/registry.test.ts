import { describe, it, expect } from "vitest";
import {
  registrySkillExists,
  registrySkill,
  registrySkillVersion,
  registrySearch,
  registryResolveDeps,
  registrySkillsByCategory,
  registryCategories,
} from "../src/core/registry.js";

describe("registrySkillExists", () => {
  it("returns true for known skill", () => {
    expect(registrySkillExists("tech-react")).toBe(true);
  });

  it("returns false for unknown skill", () => {
    expect(registrySkillExists("does-not-exist")).toBe(false);
  });
});

describe("registrySkill", () => {
  it("returns skill object with expected fields", () => {
    const skill = registrySkill("tech-react");
    expect(skill).toBeDefined();
    expect(skill!.name).toBe("tech-react");
    expect(skill!.category).toBeDefined();
    expect(skill!.description).toBeDefined();
    expect(Array.isArray(skill!.tags)).toBe(true);
  });
});

describe("registrySkillVersion", () => {
  it("returns a numeric string for known skill", () => {
    const version = registrySkillVersion("tech-react");
    expect(version).toMatch(/^\d+$/);
  });
});

describe("registrySearch", () => {
  it("returns array containing tech-react for query 'react'", () => {
    const results = registrySearch("react");
    const names = results.map((s) => s.name);
    expect(names).toContain("tech-react");
  });

  it("returns empty array for unmatched query", () => {
    expect(registrySearch("zzznomatch")).toEqual([]);
  });
});

describe("registryResolveDeps", () => {
  it("chain for tech-react includes platform-frontend", () => {
    const chain = registryResolveDeps("tech-react");
    expect(chain).toContain("platform-frontend");
    expect(chain).toContain("tech-react");
  });
});

describe("registrySkillsByCategory", () => {
  it("returns non-empty array for framework category", () => {
    const skills = registrySkillsByCategory("framework");
    expect(skills.length).toBeGreaterThan(0);
  });

  it("all returned skills have category === framework", () => {
    const skills = registrySkillsByCategory("framework");
    expect(skills.every((s) => s.category === "framework")).toBe(true);
  });
});

describe("registryCategories", () => {
  it("returns a Map with entries for standard categories", () => {
    const cats = registryCategories();
    expect(cats instanceof Map).toBe(true);
    expect(cats.has("universal")).toBe(true);
    expect(cats.has("platform")).toBe(true);
    expect(cats.has("framework")).toBe(true);
  });
});
