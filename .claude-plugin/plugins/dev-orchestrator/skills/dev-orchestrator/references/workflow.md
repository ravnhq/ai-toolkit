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
| `/orchestrate --worktree <task1> AND <task2>` | [Worktree mode (multi-subtask)](#scenario-6-worktree-mode-multi-subtask-cohesive-deliverable) | Mode 3 | Yes (if code-touching) |
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

**Phase 3 — Execution (Mode 1):** the orchestrator emits both `invoke_agent` calls in a **single message** so they fan out concurrently, with the announcement:

> `Launching 2 agents in parallel. I'll report back when they finish.`

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

**Phase 3 — Execution (Mode 1):** parallel. The `pr-comments-address` sub-agent prompt includes the **Test-plan obligation clause** because it is code-touching; `test-case-gen` does not (doc-only).

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

**Phase 3 — Execution (Mode 1):** three parallel `invoke_agent` calls. The `agent-pr-creator` prompt carries the Test-plan obligation clause; the other two do not.

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

- Wave 1: announcement `Launching wave 1 of 2 (1 agent in parallel). I'll report back when this wave finishes.` then a single `invoke_agent` for `test-plan-gen`.
- Wait for wave 1 to land `.qa/test-plan.md`.
- Wave 2: announcement `Launching wave 2 of 2 (1 agent in parallel). I'll report back when this wave finishes.` then a single `invoke_agent` for `test-case-gen` whose prompt explicitly references the `.qa/test-plan.md` path that wave 1 produced.

**Phase 4 — Results:** both tasks succeed, `2/2 tasks completed`.

**Phase 5 — QA:** skipped — both tasks are doc-only.

**Alternative path** — if the user had replied `parallel` instead of `staged`, the orchestrator would have warned explicitly that the soft-sequencing benefit (test cases informed by the plan) is forfeited, re-presented the plan as Layout A, and waited for a final confirmation before falling back to Mode 1.

## Scenario 5: Worktree mode (single cohesive task)

**User prompt:**

> `/orchestrate --worktree refactor the auth middleware and auto-merge to main`

**Phase 1 — Detection:** worktree opt-in detected via the `--worktree` flag (before classification). One actionable task survives. Worktree options captured: `branch=auto, base=main, validate=on, merge=on, keep-branch=off`. See [`worktree-mode.md`](worktree-mode.md#worktree-options-captured-in-phase-1) for the full options table.

**Phase 2 — Plan presented (Layout C):**

```text
Detected 1 task (worktree mode — sequential execution on one isolated branch):
  1. free task → refactor the auth middleware

Will auto-merge to main when green, with a reconciler sub-agent on conflicts.
Worktree options: branch=auto, base=main, validate=on, merge=on, keep-branch=off
Proceed? (yes / remove N / add something / reorder / cancel-worktree)
```

User confirms `yes`.

**Phase 3 — Execution (Mode 3):** runs `scripts/setup-worktree.sh --task "refactor the auth middleware"`, captures `WORKTREE_PATH` and `WORKTREE_BRANCH`, snapshots `BRANCH_SHA_PREV`, then issues **one synchronous** `invoke_agent` call inside the worktree. After the call returns, SHA + diff verification confirms a real new commit landed.

**Phase 4 — Results:**

```text
═══════════════════════════════
  Orchestrator Results
═══════════════════════════════
  ✓ free task — completed
    Summary: Extracted auth middleware into AuthService; added unit tests.

  Worktree:   /repos/myapp-refactor-the-auth-middleware-1715405200   pending merge
  Branch:     agent/refactor-the-auth-middleware-1715405200          pending merge
  1/1 tasks completed
```

**Phase 4.5:** `validate-worktree.sh` passes (lint + tests green), `merge-worktree.sh` runs cleanly, pushes to `origin/main`, removes the worktree, deletes the feature branch. Footer rewritten to `merged & cleaned`.

**Phase 5 — QA:** fires because the task was code-touching. The diff is already on `main`, so QA scopes by task summary as usual.

## Scenario 6: Worktree mode (multi-subtask cohesive deliverable)

**User prompt:**

> `/orchestrate --worktree refactor the auth module end-to-end: consolidate AuthService, update unit tests, update integration tests, update docs`

**Phase 1 — Detection:** worktree opt-in, four cohesive subtasks. Worktree mode forces single-branch sequential execution regardless of how the subtasks would normally classify.

**Phase 2 — Plan presented (Layout C):** four-line plan with `Worktree options:` echo. User confirms `yes`.

**Phase 3 — Execution (Mode 3):** one worktree provisioned, four `invoke_agent` calls issued sequentially. After each, SHA + diff verification advances `BRANCH_SHA_PREV` to the new tip. Each sub-agent's prompt closing line forbids `--amend` and `--allow-empty`.

If any subtask fails (no new commit, or empty diff), the chain stops there and the worktree footer is rewritten to `preserved on failure`. See [the Phase 4 retry menu](worktree-mode.md#phase-4-worktree-footer-and-retry-menu) for recovery options.

**Phase 4 — Results:** four tasks reported, with worktree footer at `pending merge` if all succeeded.

**Phase 4.5:** standard validate → merge → footer rewrite flow.

**Phase 5 — QA:** fires because at least one subtask was code-touching.

## Scenario 7: Worktree mode with no-merge

**User prompt:**

> `/orchestrate --worktree --no-merge experiment with a redis cache layer; I'll merge later if results look good`

**Phase 1 — Detection:** worktree opt-in with `--no-merge` captured. Worktree options echo: `merge=off`.

**Phase 2 — Plan presented (Layout C):** plan + options echo. User confirms `yes`.

**Phase 3 — Execution (Mode 3):** standard sequential execution inside the worktree. Each subtask commits on the feature branch.

**Phase 4 — Results:** consolidated report with footer at `pending merge`.

**Phase 4.5 — `--no-merge` closing block:**

1. Footer lines rewritten to `preserved (--no-merge)` (not `pending merge`, not `preserved on failure`).
2. The orchestrator emits an opt-out confirmation followed by the exact resume command:

   ```text
   Worktree preserved per --no-merge. Run this when ready to merge:

   bash skills/assistant/dev-orchestrator/scripts/validate-worktree.sh "/repos/myapp-experiment-redis-cache-1715405200" \
     && bash skills/assistant/dev-orchestrator/scripts/merge-worktree.sh "/repos/myapp-experiment-redis-cache-1715405200" \
          "agent/experiment-redis-cache-1715405200" "main" --summary "experiment with redis cache layer"
   ```

3. Phase 5 is skipped explicitly.

**Days later — user merges manually and wants QA:** see the "QA after a manual merge from a `--no-merge` run" troubleshooting entry in `SKILL.md` for the exact invocation (priority: PR number lookup via `gh pr list --head <feature branch>`; fall through to the scope blurb `goal: ... | landed: ...`).

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
| Two sub-agents stepped on each other's files in Mode 1 | Tasks were misclassified as independent when they actually share state. | SKILL.md Troubleshooting → "Misclassified dependency surfaces during execution". Upgrade to soft-sequenced or worktree mode. |
| Worktree run finished but Phase 5 was skipped despite code touch | A code-touching sub-agent skipped the Test-plan obligation update. | SKILL.md Troubleshooting → "Test-plan obligation skipped". |
| Worktree footer stuck at `pending merge` | Should never happen if the orchestrator follows the contract. If it does, manually run the resume command from the Phase 4 retry menu. | `worktree-mode.md` → "Phase 4 — worktree footer and retry menu". |
| `setup-worktree.sh` failed with "path already exists" | Stale worktree from a previous run, or sibling-path collision. | SKILL.md Troubleshooting → "Worktree path collision". Use `git worktree list`, then remove or pass `--branch <unique>`. |
| `validate-worktree.sh` failed | Real regression OR worktree missing setup (deps not installed). | SKILL.md Troubleshooting → "Worktree validation fails before merge". |
| Reconciler aborted with "semantic ambiguity" | Both branches rewrote the same logic incompatibly. | SKILL.md Troubleshooting → "Worktree merge conflict ambiguous". Manual resolution required. |
| Merged manually after `--no-merge`, need QA | No live orchestrator session — invoke `qa-orchestrator` by hand. | SKILL.md Troubleshooting → "QA after a manual merge from a `--no-merge` run". |
| `invoke_agent` calls cannot run concurrently | Host client does not support concurrent agent fan-out. | SKILL.md Troubleshooting → "Parallel execution unavailable". Falls back to sequential. |

## See also

- [`SKILL.md`](../SKILL.md) — authoritative phase contract and inline troubleshooting entries.
- [`worktree-mode.md`](worktree-mode.md) — worktree-mode deep dive (options table, Layout C, Mode 3, Phase 4.5 pipeline, Case E example).
- `scripts/setup-worktree.sh`, `scripts/validate-worktree.sh`, `scripts/merge-worktree.sh` — operational helpers invoked from Mode 3 and Phase 4.5.
