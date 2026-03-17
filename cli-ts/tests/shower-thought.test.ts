import { describe, it, expect, vi } from "vitest";
import { thoughts, cmdShowerThought } from "../src/commands/shower-thought.js";

describe("thoughts array", () => {
  it("is non-empty", () => {
    expect(thoughts.length).toBeGreaterThan(0);
  });

  it("every entry is a non-empty string", () => {
    for (const t of thoughts) {
      expect(typeof t).toBe("string");
      expect(t.length).toBeGreaterThan(0);
    }
  });
});

describe("cmdShowerThought", () => {
  it("prints a quote and Dave attribution", () => {
    const spy = vi.spyOn(console, "log").mockImplementation(() => {});
    cmdShowerThought();
    const output = spy.mock.calls.map((c) => c.join(" ")).join("\n");
    expect(output).toContain("Dave");
    spy.mockRestore();
  });
});
