import { describe, it, expect, beforeEach } from "vitest";
import { mkdtempSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  configGet,
  configSet,
  parseSkillList,
  skillListUpsert,
  skillListRemove,
  skillVersionFromList,
} from "../src/core/config.js";

function tmpFile(): string {
  const dir = mkdtempSync(join(tmpdir(), "ravencito-test-"));
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
