# Dispatch Contract — Isolated Agent Dispatch

Authoritative reference for **how** `dev-orchestrator` spawns the agents that carry out each task. The orchestrator does **not** issue in-session sub-agent calls (e.g. `invoke_agent` running inside the parent conversation). Every task — parallel or sequential, code-touching or doc-only, worktree-mode or not — is dispatched as an **isolated agent** that satisfies the four-part contract below. The dispatch primitive is selected at runtime based on the host the skill is running in; the contract itself stays the same.

Read this file whenever SKILL.md mentions "dispatch an agent", "the wave's agents", "the QA agent", or "the PR-creator agent". It defines what those phrases mean operationally so the SKILL stays focused on workflow semantics.

## The four-part isolated-agent contract

Every agent the orchestrator dispatches must satisfy **all four** properties below. Any dispatch primitive that cannot satisfy them is unfit for this skill — degrade gracefully (see the fallback table at the end of this file) rather than violating the contract.

| Property | Requirement | Why it matters |
| --- | --- | --- |
| Isolated session | No parent conversation context bleeds in. The agent receives only the prompt the orchestrator supplies; it cannot read the parent's message history, previously-loaded files, or sibling agents' partial output. | Prevents cross-task contamination — a code-touching agent must not accidentally see a sibling agent's in-progress diff. |
| Isolated working directory | The agent's cwd is fixed at dispatch time. In Mode 3 (worktree mode) it is the per-task worktree path. Outside Mode 3 it is the repo root in a fresh session. The agent cannot `cd` outside it. | Parallel worktree dispatch only works if each agent is pinned to its own worktree path; sibling tasks editing the same files in the same cwd would corrupt the run. |
| Scoped tool list | Only the tools the task actually needs are exposed. A `bug-report-gen` agent does not get `git push` or `gh pr create`; a `qa-orchestrator` agent does not get `git commit`. The scope is declared in the dispatch call. | Minimizes blast radius — a doc-only agent that gets only `Read` + `Write` cannot accidentally push or merge, even if its skill mis-fires. |
| Orchestrator-awaited completion | The parent dispatches, then awaits a final exit status (success / failure + structured summary). The parent observes the result and surfaces it in Phase 4. Failures do not crash the orchestrator — they become Phase 4 "failed" rows. | Without an explicit await, Phase 4 consolidation cannot report a per-task verdict, and Phase 4.5 / Phase 5 cannot make routing decisions on the run's success ratio. |

## Host mapping

Same contract, different dispatch primitive per host. The orchestrator detects the host at runtime and routes accordingly. Skill authors and reviewers only need to understand the contract; the per-host wiring is the orchestrator's responsibility.

| Host | Dispatch primitive | Await primitive | Background-by-default? |
| --- | --- | --- | --- |
| Claude Code marketplace (skill installed via `/plugin marketplace add`) | `Task` tool with `subagent_type: <type>` + `run_in_background: true` + an explicit `allowed_tools` (or equivalent scope hint) in the prompt | Polled via the returned task id; per-agent completion notifications fire when each agent finishes. The orchestrator surfaces each completion individually as it lands. | Yes — every dispatch is backgrounded so siblings actually run in parallel. |
| Cursor / corvus (skill installed via `corvus install`) | Cursor SDK `Agent.create({ runtime: "cloud", ... })` for long-running or CI-style runs; `Agent.prompt({ ... })` for local in-process runs that still satisfy the isolation contract (fresh session, scoped tools) | `Agent.resume()` for cloud agents; stream awaits + `agent.send` for local agents. Both expose a final exit status the orchestrator consumes. | Yes — cloud is implicitly async; local prompt agents are awaited but run in their own session so sibling local agents are still independent. |

The SKILL never names a specific primitive in its workflow phrasing. It says **"dispatch an agent"** and lets the dispatch helper translate.

## Wave dispatch + poll pattern

This replaces the legacy "concurrent in one message, parent waits for the whole batch" model. The new pattern works the same for Layout A (one wave), Layout B (W waves), and Mode 3 (worktree mode, same per-wave shape):

1. **Provision per-task context.** For Mode 3, run `setup-worktree.sh --base "$INTEGRATION_BRANCH"` once per task in the wave and capture each `WORKTREE_PATH_<i>`. Outside Mode 3, the context is the repo root at the parent's cwd (no worktree).

2. **Dispatch all N agents in the wave at once.** Issue N dispatch calls back-to-back. Each agent starts immediately and runs independently. Do **not** wait between dispatch calls. Each call passes:
   - The agent's task prompt (skill invocation or free-task description).
   - The cwd (worktree path in Mode 3; repo root otherwise).
   - The scoped tool list (only what the task needs — see "Tool-scope cheatsheet" below).
   - The Test-plan obligation clause **only** for code-touching tasks (verbatim text in SKILL.md Phase 3).

3. **Poll for completion individually.** As each agent finishes, surface a per-agent line immediately so the user sees progress in real time:

   ```text
   [wave K] agent i of N — completed   Summary: <one-line>
   [wave K] agent j of N — failed      Reason: <one-line>
   ```

   Use `i of N`, `j of N`, etc. so the user knows the wave's expected size. Surface completions in arrival order, **not** dispatch order — slower agents land later and that's fine.

4. **Wait for every agent in the wave** (success or failure) before moving on. Failures do **not** auto-cancel siblings — let the wave run to completion. Only after the last agent returns does the orchestrator:
   - In Mode 3: run SHA + diff verification on the successful agents' commits, then merge them into the integration branch sequentially.
   - In Mode 1 / 2: just record results.

5. **Between waves (Layout B / multi-wave Mode 3):** wave K+1 dispatches **only after the slowest wave-K agent returns** (and, in Mode 3, only after wave K's merges have all landed on the integration branch). This preserves the soft-sequencing guarantee — wave K+1 always sees wave K's full output, never a partial view.

### Failure behavior

- A failed agent is surfaced as it happens via the `failed Reason:` line above.
- Siblings in the same wave **keep running**. The orchestrator never auto-cancels parallel work on the first failure — the user paid the cost to start it, and partial success is still useful.
- After every agent in the wave has returned, if any failure happened, the orchestrator branches on the active mode. In **Mode 1 or Mode 2** it posts the Phase 4 consolidated report with the per-task verdicts, then asks the user whether to retry the failed ones (same UX as today, but the visibility is per-agent rather than all-or-nothing). In **Mode 3** it refuses to dispatch the next wave (or to proceed to Phase 4.5) and falls into the worktree retry menu documented in [`worktree-mode.md`](worktree-mode.md) "Phase 4 — worktree footer and retry menu".

### Hard-chained tasks

Hard-chained tasks are merged into a single task during Phase 1 classification (unchanged). The resulting single task is still dispatched as **one isolated agent** following the same four-part contract; it is just awaited synchronously because there are no siblings to run in parallel with.

## Per-agent completion line format

Use this exact shape whenever an agent in a wave returns. The bracket header anchors the line so a scroll-back through a long run reads cleanly.

```text
[wave K] agent i of N — completed
  Summary: <≤120-char one-liner — what landed, paths/PR numbers if relevant>
[wave K] agent j of N — failed
  Reason:  <≤120-char one-liner — exit code, error class, or the agent's failure message>
```

- Use `agent i of N` rather than the task name; the task name appears in Phase 4 consolidation. Mid-run scroll-back is easier to scan with the wave/index header.
- Wrap the lines into the Phase 4 consolidated report as the "Summary" / "Error / Action" fields for that task — no new rendering required, just promote the live line into the final report.
- For single-task runs (hard-chained merge, Layout A with one survivor, single-task worktree mode), `N = 1` and `K = 1` — the line still appears, both for consistency and so the user sees a heartbeat on long-running tasks.

## Tool-scope cheatsheet

The scoped tool list passed at dispatch time should match the task's intent. Use this as a starting point; the dispatch helper can widen the scope when a task's prompt requires extra capabilities (e.g. a free task that needs `Glob` to find files).

| Task type | Suggested tool scope |
| --- | --- |
| `agent-pr-creator` | `Bash` (gh, git), `Read`, `Glob`, `Grep`, MCP issue-tracker tools when ticket linking is needed |
| `pr-comments-address` | `Bash` (git), `Read`, `Write`, `Edit` / `StrReplace`, `Glob`, `Grep` |
| `rewrite-commit-history` | `Bash` (git) only |
| `test-case-gen`, `test-plan-gen`, `bug-report-gen`, `locators-scanner` | `Read`, `Glob`, `Grep`, `Write` (doc-only — no `git`, no `gh`) |
| Free task that writes code | `Read`, `Write`, `Edit` / `StrReplace`, `Glob`, `Grep`, `Bash` (git inside the worktree only) |
| Free task that only generates docs | `Read`, `Glob`, `Grep`, `Write` |
| `qa-orchestrator` (Phase 5) | `Bash`, `Read`, `Write`, MCP tools the QA agents themselves need (Playwright bridge, Sentry, Linear, etc.) |
| PR-creation handoff agent (Phase 4.5 step 3) | `Bash` (git, gh), `Read` — explicitly **no** write/edit; the agent only opens the PR, it does not modify the integration branch |

When in doubt, prefer **narrower** — the agent can return with "I needed tool X but did not have it" and the orchestrator can widen on retry. The other direction (a too-broad agent accidentally pushing the wrong thing) is harder to recover from.

## Fallback when a host cannot satisfy the contract

If neither the Claude Code `Task` primitive nor the Cursor SDK is available in the current host (older client, sandboxed CI runner, etc.) the orchestrator must **announce the degradation** before falling back:

1. Print exactly: `Isolated-agent dispatch unavailable in this host; falling back to in-session sequential execution. Parallel waves will run serially and the four-part isolation contract is best-effort only.`
2. Dispatch each task synchronously, one at a time, even within a Layout A "single wave" — true parallelism is forfeited.
3. Continue using the per-agent completion line format and Phase 4 consolidation. Phase 4.5 and Phase 5 still run as documented; only the dispatch shape degrades.

The fallback is the same code path as the existing "Parallel execution unavailable" troubleshooting entry in SKILL.md, just with explicit messaging about the isolation contract.

## See also

- [`../SKILL.md`](../SKILL.md) — phase contract that consumes this dispatch contract.
- [`worktree-mode.md`](worktree-mode.md) — Phase 3 Mode 3 dispatch and Phase 4.5 step 3 PR-handoff agent both reference this file.
- [`workflow.md`](workflow.md) — scenario walkthroughs that show the per-agent completion lines in context.
