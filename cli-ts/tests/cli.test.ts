import { describe, it, expect } from "vitest";
import { execFile } from "node:child_process";
import { resolve } from "node:path";

const CLI = resolve(import.meta.dirname, "../dist/index.js");

function run(...args: string[]): Promise<{ code: number; stdout: string; stderr: string }> {
  return new Promise((resolve) => {
    execFile("node", [CLI, ...args], { timeout: 10_000 }, (error, stdout, stderr) => {
      resolve({
        code: error?.code ?? 0,
        stdout: stdout ?? "",
        stderr: stderr ?? "",
      });
    });
  });
}

describe("CLI integration", () => {
  it("rejects unknown commands with exit 1 and shows help hint", async () => {
    const result = await run("x");
    expect(result.code).toBe(1);
    expect(result.stderr).toContain("unknown command 'x'");
    expect(result.stderr).toContain('Run "ravencito help" for usage information.');
  });

  it("rejects typos like 'drs' with exit 1 and shows help hint", async () => {
    const result = await run("drs");
    expect(result.code).toBe(1);
    expect(result.stderr).toContain("unknown command 'drs'");
    expect(result.stderr).toContain('Run "ravencito help" for usage information.');
  });

  it("--version prints version and exits 0", async () => {
    const result = await run("--version");
    expect(result.code).toBe(0);
    expect(result.stdout.trim()).toMatch(/^\d+\.\d+\.\d+/);
  });

  it("--logo prints ravencito and exits 0", async () => {
    const result = await run("--logo");
    expect(result.code).toBe(0);
    expect(result.stdout.toLowerCase()).toContain("r a v e n c i t o");
  });

  it("shower-thought prints a Dave quote", async () => {
    const result = await run("shower-thought");
    expect(result.code).toBe(0);
    expect(result.stdout).toContain("Dave");
  });

  it("shower-thoughts alias works", async () => {
    const result = await run("shower-thoughts");
    expect(result.code).toBe(0);
    expect(result.stdout).toContain("Dave");
  });

  it("help shows Skills Manager description", async () => {
    const result = await run("help");
    expect(result.code).toBe(0);
    expect(result.stdout).toContain("Skills Manager");
  });

  it("completions --shell zsh prints setup instructions", async () => {
    const result = await run("completions", "--shell", "zsh");
    expect(result.code).toBe(0);
    expect(result.stdout).toContain("Zsh completions for ravencito");
    expect(result.stdout).toContain("oh-my-zsh");
  });

  it("completions --shell bash prints setup instructions", async () => {
    const result = await run("completions", "--shell", "bash");
    expect(result.code).toBe(0);
    expect(result.stdout).toContain("Bash completions for ravencito");
  });

  it("install --help lists all target flags", async () => {
    const result = await run("install", "--help");
    expect(result.code).toBe(0);
    expect(result.stdout).toContain("--claude");
    expect(result.stdout).toContain("--cursor");
    expect(result.stdout).toContain("--global-claude");
    expect(result.stdout).toContain("--global-cursor");
  });
});
