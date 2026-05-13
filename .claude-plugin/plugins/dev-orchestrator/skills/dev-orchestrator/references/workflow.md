# Workflow Playbook

End-to-end scenario walkthroughs for `dev-orchestrator`. Each scenario starts from a verbatim user prompt and traces the orchestrator's behavior through Phases 1 → 5, including the exact text blocks the user will see at each step. Use this playbook to:

- Learn what the orchestrator does in response to common prompt shapes.
- Predict the consolidated report a given input will produce.
- Diagnose unexpected behavior by comparing observed output to the documented scenario.

This is a **reference** — it complements but does not replace `SKILL.md` (the authoritative contract) or `references/worktree-mode.md` (the worktree-mode deep dive). Where a scenario depends on worktree-mode mechanics, this playbook links to the relevant section of that reference rather than duplicating it.

## Quick reference: input pattern → scenario

| User prompt pattern | Scenario | Phase 3 mode | Phase 5 QA fires? |
| --- | --- | --- | --- |
| Single actionable task ("create the PR") | [Pass-through (no orchestration)](#scenario-0-single-task-pass-through) | — | n/a |
| Multi-task, all doc-only ("bug report and test plan") | [Doc-only fan-out](#scenario-1-doc-only-multi-task-fan-out) | Mode 1 | No (doc-only) |
| Multi-task, mixed code + doc ("address PR comments and generate test cases") | [Mixed fan-out](#scenario-2-mixed-codedoc-multi-task-fan-out) | Mode 1 | Yes (code slice) |
| Multi-task, all code-touching ("generate tests AND create the PR") | [Code-touching fan-out](#scenario-3-code-touching-multi-task-fan-out) | Mode 1 | Yes (new PR) |
| Soft-sequenced ("generate test plan, then test cases from it") | [Staged waves](#scenario-4-soft-sequenced-staged-waves) | Mode 2 | Depends on artifacts |
| `/orchestrate --worktree <task>` | [Worktree mode (single task)](#scenario-5-worktree-mode-single-cohesive-task) | Mode 3 | Yes (if code-touching) |
| `/orchestrate --worktree <task1> AND <task2>` | [Worktree mode (independent, parallel worktrees)](#scenario-6-worktree-mode-multi-subtask-cohesive-deliverable) | Mode 3 | Yes (if code-touching) |
| `/orchestrate --worktree first X then Y and Z in parallel` | [Worktree mode (soft-sequenced waves)](#scenario-6b-worktree-mode-soft-sequenced-waves) | Mode 3 | Yes (if code-touching) |
| `/orchestrate --worktree --no-merge <task>` | [Worktree mode opt-out](#scenario-7-worktree-mode-with-no-merge) | Mode 3 | No (skipped) |
| Hard-chained ("generate changelog and embed in PR body") | [Hard-chained merge](#scenario-8-hard-chained-task-merge) | Mode 1 (single task) | Yes (PR created) |
| Failure mid-run (any mode) | [Recovery checklist](#recovery-checklist) | varies | Skipped on full failure |

When a scenario starts with an issue-tracker reference in the prompt (Linear `ABC-42`, Jira `PROJ-7`, GitHub `owner/repo#3`, or a Notion page URL), Phase 0 runs first and prepends the ticket's title, state, and acceptance criteria to the prompt body before Phase 1 classification. The post-Phase-0 flow is identical to whichever scenario below matches the resulting prompt — see [`ticket-resolution.md`](ticket-resolution.md) for the worked example.

## Scenario 0: Single-task pass-through

**User prompt:**

> `create the PR`

**Phase 1 — Detection:** exactly one actionable task surfaces. Route is `agent-pr-creator`. No worktree opt-in.

**Result:** orchestration mode does **not** activate. The orchestrator hands the task to `agent-pr-creator` directly in the foreground conversation — no Phase 2 confirmation, no Phase 3 fan-out, no consolidated report. Phase 5 QA can still be invoked by the user later if they want, but `dev-orchestrator` itself is **uninvolved**.

This is the dominant negative-trigger case and is documented mainly so the user understands when the orchestrator *won't* fire.

## Scenario 1: Doc-only multi-task fan-out

**User prompt:**

> `I need the bug report and the test plan for the auth module`

**Phase 1 — Detection:** two tasks, both doc-only.

| Task | Route | Code-touching? |
| --- | --- | --- |
| 1 | `bug-report-gen` (scoped to auth) | No |
| 2 | `test-plan-gen` (scoped to auth) | No |

Classification: **independent** (neither task consumes the other's output).

**Phase 2 — Plan presented (Layout A):**

```text
Detected 2 tasks (all independent — single parallel wave):
  1. bug-report-gen → bug report for the auth module
  2. test-plan-gen → test plan for the auth module

Proceed with all in parallel? (yes / remove N / add something / reorder)
```

User replies `yes`.

**Phase 3 — Execution (Mode 1):** the orchestrator dispatches **two isolated agents in parallel** (per [`dispatch-contract.md`](dispatch-contract.md) — own sessions, scoped tools, awaited individually). Announcement:

> `Dispatching 2 isolated agents in parallel (wave 1 of 1). I'll surface each agent's completion as it lands.`

As each agent returns, the orchestrator surfaces `[wave 1] agent i of 2 — completed Summary: ...` in real time before the consolidated Phase 4 report.

**Phase 4 — Results:**

```text
═══════════════════════════════
  Orchestrator Results
═══════════════════════════════
  ✓ bug-report-gen — completed
    Summary: Authored bug report covering session-expiry regression.
             Output: docs/bugs/auth-session-expiry.md

  ✓ test-plan-gen — completed
    Summary: Drafted auth module test plan with UI flows and API endpoints.
             Output: .qa/test-plan.md
═══════════════════════════════
  2/2 tasks completed
```

**Phase 5 — QA:** skipped. Both tasks were doc-only. The user sees:

> `QA verification skipped — no testable artifacts produced.`

## Scenario 2: Mixed code/doc multi-task fan-out

**User prompt:**

> `Address the PR review comments and generate the matching test cases`

**Phase 1 — Detection:**

| Task | Route | Code-touching? |
| --- | --- | --- |
| 1 | `pr-comments-address` | Yes (edits source) |
| 2 | `test-case-gen` | No |

Classification: **independent**. The test-case generation does not need the PR comment fixes to exist first.

**Phase 2 — Plan presented (Layout A):** two-task table, user confirms `yes`.

**Phase 3 — Execution (Mode 1):** two isolated agents dispatched in parallel. The `pr-comments-address` agent's prompt includes the **Test-plan obligation clause** because it is code-touching; `test-case-gen` does not (doc-only). Each agent gets its own scoped tool list per the dispatch contract — `pr-comments-address` gets `Bash` (git) + `Read` + `Edit`/`StrReplace`; `test-case-gen` gets `Read` + `Glob` + `Grep` + `Write` only.

**Phase 4 — Results:** standard report with both tasks marked completed.

**Phase 5 — QA:** **fires** because at least one task touched code. The orchestrator resolves the existing PR number (`gh pr list --head $(git branch --show-current)`) and hands off to `qa-orchestrator` with the literal phrase `Run a full QA session`, requesting `qa-happy-path`, `qa-chaos-monkey`, and any custom personalities. Closing line:

> `Handing off to qa-orchestrator (full workflow — happy path + chaos monkey + custom agents) to verify the run.`

The user later sees the QA verdict quoted verbatim, plus any BLOCKER/HIGH issue URLs.

## Scenario 3: Code-touching multi-task fan-out

**User prompt:**

> `Generate the test plan for payments, generate the test cases and create the PR`

**Phase 1 — Detection:**

| Task | Route | Code-touching? |
| --- | --- | --- |
| 1 | `test-plan-gen` (payments) | No |
| 2 | `test-case-gen` | No |
| 3 | `agent-pr-creator` | Yes (creates a PR) |

Classification: **independent** (a PR can be drafted from the current diff without waiting for the test plan or test cases — those land as separate deliverables).

**Phase 2 — Plan presented (Layout A):** three-task table, user confirms `yes`.

**Phase 3 — Execution (Mode 1):** three isolated agents dispatched in parallel. The `agent-pr-creator` agent's prompt carries the Test-plan obligation clause; the other two do not. Per-agent completion lines (`[wave 1] agent i of 3 — completed Summary: ...`) surface as each returns.

**Phase 4 — Results:** standard three-task report.

**Phase 5 — QA:** **fires** because `agent-pr-creator` is code-touching. Scope is the **new PR number** that `agent-pr-creator` reported. Full QA workflow runs against that PR.

## Scenario 4: Soft-sequenced staged waves

**User prompt:**

> `Generate the test plan for the new checkout flow, then generate the test cases from it`

**Phase 1 — Detection:** two tasks, but `test-case-gen` benefits from reading `.qa/test-plan.md` that `test-plan-gen` produces. Neither task fails without the other, so **soft-sequenced**, not hard-chained.

**Phase 2 — Plan presented (Layout B):**

```text
Detected 2 tasks across 2 waves (soft-sequenced — wave K+1 waits for wave K):
  Wave 1:
    1. test-plan-gen → test plan for the new checkout flow
  Wave 2:
    2. test-case-gen → test cases derived from the test plan

Proceed staged (wave-by-wave), or run everything in parallel anyway?
(staged / parallel / remove N / add something / reorder)
```

User replies `staged`.

**Phase 3 — Execution (Mode 2):**

- Wave 1: announcement `Dispatching wave 1 of 2: 1 isolated agent in parallel. I'll surface each agent's completion as it lands; wave 2 starts after the slowest wave-1 agent returns.` Then dispatch one isolated agent for `test-plan-gen`. Surface `[wave 1] agent 1 of 1 — completed Summary: wrote .qa/test-plan.md` when it lands.
- Wave 2 only begins after wave 1's agent returns and `.qa/test-plan.md` exists on disk.
- Wave 2: announcement `Dispatching wave 2 of 2: 1 isolated agent in parallel. ...`. Then dispatch one isolated agent for `test-case-gen` whose prompt explicitly references the `.qa/test-plan.md` path that wave 1 produced. Surface `[wave 2] agent 1 of 1 — completed Summary: ...` on return.

**Phase 4 — Results:** both tasks succeed, `2/2 tasks completed`.

**Phase 5 — QA:** skipped — both tasks are doc-only.

**Alternative path** — if the user had replied `parallel` instead of `staged`, the orchestrator would have warned explicitly that the soft-sequencing benefit (test cases informed by the plan) is forfeited, re-presented the plan as Layout A, and waited for a final confirmation before falling back to Mode 1.

## Scenario 5: Worktree mode (single cohesive task)

**User prompt:**

> `/orchestrate --worktree refactor the auth middleware`

**Phase 1 — Detection:** worktree opt-in detected via the `--worktree` flag (before classification). One actionable task survives. Worktree options captured: `integration=auto, base=resolved, validate=on, merge=on, keep-branch=off`. See [`worktree-mode.md`](worktree-mode.md#worktree-options-captured-in-phase-1) for the full options table.

**Phase 2 — Plan presented (Layout C):**

```text
Detected 1 task (worktree mode — single wave, parallel per-task worktrees):
  Integration branch: feature/refactor-the-auth-middleware-1715405200  (off develop, auto: develop/dev preferred; else newer of main/master)
  Wave 1 (parallel, 1 worktree off feature/refactor-the-auth-middleware-1715405200):
    1. free task → refactor the auth middleware

After all tasks merge cleanly into feature/refactor-the-auth-middleware-1715405200, agent-pr-creator will
open a PR from feature/refactor-the-auth-middleware-1715405200 into develop.
Worktree options: integration=feature/refactor-the-auth-middleware-1715405200, base=develop, validate=on, merge=on, keep-branch=off
Proceed? (yes / remove N / add something / reorder / cancel-worktree)
```

User confirms `yes`.

**Phase 3 — Execution (Mode 3):**

1. Runs `scripts/setup-integration-branch.sh --task "refactor the auth middleware"`. Captures `INTEGRATION_BRANCH=feature/refactor-the-auth-middleware-1715405200` and `BASE_BRANCH=develop`.
2. Provisions one per-task worktree via `scripts/setup-worktree.sh --base "$INTEGRATION_BRANCH"`. Captures `WORKTREE_PATH_1` and `WORKTREE_BRANCH_1=agent/refactor-the-auth-middleware-1715405300`.
3. Dispatches **one isolated agent** pinned to the per-task worktree (see [`dispatch-contract.md`](dispatch-contract.md) for the four-part contract — own session, cwd = `WORKTREE_PATH_1`, code-touching tool scope, awaited synchronously since it is the only agent in the wave). After it returns and emits `[wave 1] agent 1 of 1 — completed Summary: ...`, SHA + diff verification confirms a real new commit landed.
4. Merges worktree 1 into the integration branch via `merge-worktree.sh --no-push`.

**Phase 4 — Results:**

```text
═══════════════════════════════
  Orchestrator Results
═══════════════════════════════
  ✓ free task — completed
    Summary: Extracted auth middleware into AuthService; added unit tests.

  Integration:  feature/refactor-the-auth-middleware-1715405200   pending PR
  Worktrees:    1 merged & cleaned, 0 kept, 0 preserved
  Base:         develop
  1/1 tasks completed
```

**Phase 4.5:** `validate-worktree.sh` passes (lint + tests green), the integration branch is pushed to `origin`, `agent-pr-creator` opens PR #842 from `feature/refactor-the-auth-middleware-1715405200` → `develop`. Footer rewritten to `PR opened`.

**Phase 5 — QA:** fires because the task was code-touching. Scope is the new PR number (`--pr 842`), so QA runs against the exact diff the human reviewer will see.

## Scenario 6: Worktree mode (multi-subtask cohesive deliverable)

**User prompt:**

> `/orchestrate --worktree refactor the auth module end-to-end: consolidate AuthService, update unit tests, update integration tests, update docs`

**Phase 1 — Detection:** worktree opt-in, four subtasks. Classification: independent (each touches different files and can run in parallel). Worktree mode now respects this — all four fan out into parallel per-task worktrees off one integration branch.

**Phase 2 — Plan presented (Layout C — single wave):** four-line plan with `Worktree options:` echo and `Wave 1 (parallel, 4 worktrees off <integration-branch>)`. User confirms `yes`.

**Phase 3 — Execution (Mode 3):**

1. Integration branch provisioned via `setup-integration-branch.sh`.
2. Four per-task worktrees provisioned in parallel (one `setup-worktree.sh` call per task), each off the integration branch tip.
3. Wave 1 announcement: `Dispatching wave 1 of 1: 4 isolated agents in parallel, each pinned to its own worktree off <integration-branch>. I'll surface each agent's completion as it lands; wave K+1 starts after the slowest wave-K agent returns and its worktree merges in.` Four isolated agents dispatched in parallel (own sessions, own cwds, scoped tools per the dispatch contract).
4. As each returns, SHA + diff verification confirms a new commit landed.
5. Worktrees merge into the integration branch sequentially via `merge-worktree.sh --no-push`.

If any subtask fails (no new commit, empty diff, or a merge conflict), that task is recorded as failed; sibling tasks in the same wave continue. If any merge conflicts on the integration branch, the wave stops and the troubleshooting entry "Per-task merge conflict on the integration branch" applies. The integration footer ends at `preserved on failure` and the retry menu fires.

**Phase 4 — Results:** four tasks reported, with `Worktrees: 4 merged & cleaned` and integration footer at `pending PR` if all succeeded.

**Phase 4.5:** standard validate → push → `agent-pr-creator` handoff. Footer reaches `PR opened`.

**Phase 5 — QA:** fires because at least one subtask was code-touching. Scope is the new PR number.

## Scenario 6b: Worktree mode (soft-sequenced waves)

**User prompt:**

> `/orchestrate --worktree first add the session model, then build the OAuth callback and the /v1/auth endpoints in parallel`

**Phase 1 — Detection:** worktree opt-in, three tasks. The session model must land first (the callback and the endpoints both depend on it); the callback and endpoints can run in parallel. Classification: **soft-sequenced**, two waves.

**Phase 2 — Plan presented (Layout C — multiple waves):**

```text
Detected 3 tasks across 2 waves (worktree mode — waves sequential, tasks within a wave parallel):
  Integration branch: feature/add-session-model-and-oauth-1715406000  (off develop, auto: develop/dev preferred; else newer of main/master)
  Wave 1 (parallel, 1 worktree off feature/add-session-model-and-oauth-1715406000):
    1. free task → add the session model
  Wave 2 (parallel, 2 worktrees off feature/add-session-model-and-oauth-1715406000 at wave-1-merged tip):
    2. free task → build the OAuth callback
    3. free task → add the /v1/auth endpoints

After all waves merge cleanly into feature/add-session-model-and-oauth-1715406000, agent-pr-creator will
open a PR from feature/add-session-model-and-oauth-1715406000 into develop.
Worktree options: integration=feature/add-session-model-and-oauth-1715406000, base=develop, validate=on, merge=on, keep-branch=off
Proceed staged? (staged / remove N / add something / reorder / cancel-worktree)
```

User confirms `staged`.

**Phase 3 — Execution (Mode 3):**

1. Integration branch provisioned off `origin/develop`.
2. **Wave 1**: one per-task worktree for the session model, run, verify, merge into integration branch. `INTEGRATION_SHA_PREV` advances.
3. **Wave 2**: two per-task worktrees provisioned off the **updated** integration branch tip (so both see the session model). Dispatched in parallel, each verified, each merged sequentially.

**Phase 4 — Results:** three tasks, integration footer at `pending PR`.

**Phase 4.5:** standard validate → push → `agent-pr-creator` handoff.

**Phase 5 — QA:** fires; scope is the new PR.

## Scenario 7: Worktree mode with no-merge

**User prompt:**

> `/orchestrate --worktree --no-merge experiment with a redis cache layer; I'll open the PR later if results look good`

**Phase 1 — Detection:** worktree opt-in with `--no-merge` captured. Worktree options echo: `merge=off`.

**Phase 2 — Plan presented (Layout C):** plan + options echo. User confirms `yes`.

**Phase 3 — Execution (Mode 3):** integration branch provisioned, per-task worktrees run + merge into integration branch as usual.

**Phase 4 — Results:** consolidated report with integration footer at `pending PR`.

**Phase 4.5 — `--no-merge` closing block:**

1. Integration footer rewritten to `preserved (--no-merge)` (not `pending PR`, not `preserved on failure`).
2. The orchestrator emits an opt-out confirmation followed by the exact resume command:

   ```text
   Integration branch preserved per --no-merge. Run this when ready to open the PR:

   bash skills/assistant/dev-orchestrator/scripts/validate-worktree.sh "/repos/myapp-feature-experiment-redis-cache-1715405200" \
     && /orchestrate --resume-pr --integration-branch "feature/experiment-redis-cache-1715405200" --base "develop"
   ```

3. Phase 5 is skipped explicitly.

**Days later — user opens the PR manually and wants QA:** see the "QA after a manual PR from a `--no-merge` run" troubleshooting entry in `SKILL.md` for the exact invocation (priority: PR number lookup via `gh pr list --head <integration-branch>`; fall through to the scope blurb `goal: ... | landed on integration branch: ...`).

## Scenario 8: Hard-chained task merge

**User prompt:**

> `Generate the changelog from the new commits, then create a PR whose body embeds the changelog`

**Phase 1 — Detection:** two phrased tasks, but the second **literally requires** the first's output (the changelog text must appear inside the PR body). Classification: **hard-chained**.

**Phase 1 routing:** merge into a **single combined task**. Do not split. The orchestrator either silently combines them or asks one clarifying question — see SKILL.md Phase 1 troubleshooting "Ambiguous single vs compound prompt".

**Phase 2:** because only one task survives merging, orchestration mode does **not** activate. The user sees no Layout A / B / C confirmation block.

**Phase 3–5:** the combined task runs directly in the foreground (typically as a `agent-pr-creator` invocation whose prompt instructs it to generate the changelog inline before drafting the PR body). Phase 5 fires because the resulting work touches the repo.

**Net effect:** the user gets a single PR with the changelog embedded, not two separate deliverables. If they wanted both deliverables independently, they should rephrase the request so the changelog stands on its own (e.g., committed as `CHANGELOG.md`) and the PR is a separate task.

## Phase 2 confirmation cheatsheet

What every confirmation token does, regardless of layout:

| Token | Layout A | Layout B | Layout C |
| --- | --- | --- | --- |
| `yes` | Run all tasks in parallel (Mode 1). | n/a (use `staged` or `parallel`). | Run sequentially in worktree (Mode 3). |
| `staged` | n/a | Run wave-by-wave (Mode 2). | n/a |
| `parallel` | n/a | Collapse to Layout A; warn that soft-sequencing benefit is forfeited; reconfirm. | n/a |
| `remove N` | Drop task N, rebuild numbered list, re-present, wait for confirmation. | Same; collapse empty waves. | Same; preserves worktree opt-in. |
| `add something` | Remap tasks (re-classify), present refreshed plan, wait. | Same. | Same. |
| `reorder` | Cosmetic only (display order in Phase 4 report). | Reassigns tasks between waves; commits to actual execution order. | Meaningful — task N+1 sees N's commits. |
| `cancel-worktree` | n/a | n/a | Drop worktree mode; re-present plan in Layout A or B per original classification. |
| ambiguous / off-topic reply | Answer the question, re-present current plan, wait again. | Same. | Same. |

Never treat a non-confirmation reply as confirmation. Execute nothing until an explicit go-ahead token arrives.

## Recovery checklist

Use this table when a run does not produce the expected outcome.

| Symptom | Most likely cause | Where to look |
| --- | --- | --- |
| Orchestrator did nothing after the user pressed `yes` | Reply was actually ambiguous (e.g., `ok thanks`); not a confirmation token. | SKILL.md Phase 2 Requirements, plus the cheatsheet above. |
| Sub-agent reports "skill not installed" | Marketplace drift between corvus and Claude Code hosts. | SKILL.md Troubleshooting → "Agent cannot find mapped skill". Fallback: free task. |
| Two parallel agents stepped on each other's files in Mode 1 | Tasks were misclassified as independent when they actually share state. | SKILL.md Troubleshooting → "Misclassified dependency surfaces during execution". Upgrade to soft-sequenced or worktree mode (where each agent is pinned to its own worktree cwd). |
| Worktree run finished but Phase 5 was skipped despite code touch | A code-touching agent skipped the Test-plan obligation update. | SKILL.md Troubleshooting → "Test-plan obligation skipped". |
| Integration footer stuck at `pending PR` | Should never happen if the orchestrator follows the contract. If it does, manually run the resume command from the Phase 4 retry menu. | `worktree-mode.md` → "Phase 4 — worktree footer and retry menu". |
| `setup-worktree.sh` failed with "path already exists" | Stale worktree from a previous run, or sibling-path collision on a per-task slug. | SKILL.md Troubleshooting → "Worktree path collision". Use `git worktree list`, then remove or pass `--branch <unique>` per failing task. |
| `setup-integration-branch.sh` failed with "integration branch already exists" | Stale integration branch from a prior run, or `--integration-branch` collided with an existing branch. | SKILL.md Troubleshooting → "Integration branch already exists". Pass `--reuse-integration` to adopt, or delete the stale branch. |
| `validate-worktree.sh` failed in Phase 4.5 | Cross-task regression on the integration branch, OR worktree missing setup (deps not installed). | SKILL.md Troubleshooting → "Worktree validation fails before PR handoff". |
| A per-task merge into the integration branch conflicted | Two tasks in the same wave edited overlapping lines, or the wave ran on a stale snapshot. | SKILL.md Troubleshooting → "Per-task merge conflict on the integration branch". Resolve manually; re-classify as soft-sequenced on next run. |
| `agent-pr-creator` handoff failed (integration footer ends `validated, awaiting PR`) | Local auth / network / branch-protection issue. | SKILL.md Troubleshooting → "Integration-branch PR handoff failed". Fix auth then re-invoke `agent-pr-creator` directly. |
| Opened PR manually after `--no-merge`, need QA | No live orchestrator session — invoke `qa-orchestrator` by hand against the PR. | SKILL.md Troubleshooting → "QA after a manual PR from a `--no-merge` run". |
| Isolated-agent dispatch cannot run concurrently | Host client does not support concurrent agent fan-out (`Task` + `run_in_background: true` unavailable, Cursor SDK not loaded, etc.). | SKILL.md Troubleshooting → "Isolated-agent dispatch unavailable". Falls back to sequential per-task dispatch within each wave. |

## See also

- [`SKILL.md`](../SKILL.md) — authoritative phase contract and inline troubleshooting entries.
- [`dispatch-contract.md`](dispatch-contract.md) — the four-part isolated-agent contract every dispatch in every scenario follows.
- [`worktree-mode.md`](worktree-mode.md) — worktree-mode deep dive (options table, integration-branch contract, Layout C, Mode 3 dispatch, Phase 4.5 PR handoff pipeline, Case E example).
- `scripts/setup-integration-branch.sh`, `scripts/setup-worktree.sh`, `scripts/validate-worktree.sh`, `scripts/merge-worktree.sh` — operational helpers invoked from Mode 3 and Phase 4.5.
