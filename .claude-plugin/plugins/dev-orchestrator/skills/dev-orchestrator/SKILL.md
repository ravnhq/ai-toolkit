---
name: dev-orchestrator
description: |-
  Detect bundled development work — when one prompt lists multiple independent implementation or repo tasks — and dispatch each as a parallel sub-agent so progress happens concurrently without flooding the parent thread with granular tool traces. Use when a prompt bundles two or more independent dev tasks such as "generate the test cases and create the PR", "write the bug report and the test plan", or "do X and Y in parallel", or when explicitly invoked via /orchestrate. Opt into worktree mode via "--worktree" (or explicit language like "in a worktree", "isolated branch", "auto-merge to main") to run all sub-agents sequentially inside a single isolated git worktree, validate the result, and auto-merge back to the base branch with a reconciler sub-agent on conflicts. Resolves issue-tracker tickets (Linear, Jira, GitHub Issues, Notion) found in the prompt via MCP and prepends their scope to Phase 1 input. Skip for single-task asks, questions, or information requests.
allowed-tools:
- invoke_agent
- Bash
- Glob
- Read
metadata:
  category: assistant
  tags:
  - orchestration
  - parallel
  - multi-task
  - agents
  - workflow
  - git
  - worktree
  - ticket
  - linear
  status: draft
  version: 3
  triggers:
    positive:
    - do X and Y
    - I need A, B and C
    - in parallel
    - "/orchestrate"
    - "/orchestrate --worktree refactor the auth module end-to-end"
    - "/orchestrate ABC-42"
    - generate the test cases and create the PR
    - spin up a worktree and auto-merge to main
    - implement ABC-42 in a worktree
    negative:
    - single-task requests
    - questions
    - information requests
---

# Dev Orchestrator

Coordinate multi-task development prompts by detecting independent tasks, confirming the plan with the user, dispatching parallel sub-agents, and consolidating their results into a single report.

## Workflow

The orchestration runs in five phases. Phase 1 always runs; Phases 2–4 run only when two or more independent tasks survive Phase 1; Phase 5 runs after Phase 4 only when the completed work produced testable artifacts (code or repo state changes). Phase 0 (opt-in) runs ahead of Phase 1 when the prompt references an issue-tracker ticket.

For end-to-end **scenario walkthroughs** (input prompt → phase-by-phase trace → exact reports the user will see), see [`references/workflow.md`](references/workflow.md) — covers doc-only fan-out, mixed code/doc fan-out, soft-sequenced waves, worktree mode (single + multi-subtask), worktree `--no-merge` opt-out, and hard-chained merges, plus a Phase 2 confirmation cheatsheet and a recovery checklist.

### Phase 0: Ticket Resolution (opt-in)

Phase 0 fires **before** Phase 1 whenever the prompt references an issue-tracker ticket — Linear / Jira (`[A-Z]+-\d+`, e.g. `ABC-42`), GitHub Issues (`#123` or `owner/repo#123`), or a Notion page URL — **or** when the user explicitly passed `--ticket <id>`. When no reference is detected, Phase 0 is a no-op and the existing flow runs unchanged.

When fired, the orchestrator resolves the ticket via the matching MCP tool (`mcp__linear__get_issue`, `mcp__jira__get_issue`, `mcp__github__get_issue`, or `mcp__notion__get_page` — confirm the tool is registered before calling) and extracts a normalized envelope (`title`, `state`, `description`, parsed `acceptance_criteria`, `labels`, `url`). The envelope is **prepended** to the prompt body — the bare ticket reference is stripped — so Phase 1 classification sees the ticket's acceptance criteria as natural split anchors. When worktree mode is also on, the resolved ticket id is woven into the feature branch name passed to `setup-worktree.sh --branch`.

Detection patterns, tracker disambiguation (Linear vs Jira), the full MCP fetch contract, per-tracker extraction rules, failure handling (missing MCP / 404 / permission denied / closed ticket / mixed batches), the optional `.dev-orchestrator.yml` config, and a worked end-to-end example all live in [`references/ticket-resolution.md`](references/ticket-resolution.md).

### Phase 1: Task Detection

Read the user's full prompt and pull out discrete **tasks** — units of executable development work.

- Split along natural boundaries ("also", numbered lists, "and", parallel clauses).
- If you detect **only one** actionable task — or several steps that collapse into **one** hard-chained task per the classification below — **do not** use orchestration modes for this skill. Handle it **directly** in the main conversation with **zero** orchestration overhead: no splitting, no parallel sub-agents.
- If task boundaries are ambiguous, ask the user **one** clarifying question before proceeding. Do not guess.

**Dependency classification**

For every pair of detected tasks, classify their relationship into exactly one of these buckets:

| Bucket | Meaning | Routing |
| --- | --- | --- |
| **Independent** | Neither task needs the other's output, and execution order has no measurable impact on quality | Run **all** in a single parallel wave (Phase 3 default) |
| **Soft-sequenced** | Tasks are parallel-safe (no compile/runtime dependency), but one task's output **informs** the other and a specific order improves quality (e.g. *test plan first, then test cases derived from the plan*; *write the bug report first, then the bug-fix PR that references it*) | Run as **multiple waves** — wave N runs in parallel, completes, then wave N+1 launches. Default to parallel unless the user opts into staging during Phase 2 |
| **Hard-chained** | One task **literally requires** another's output as input (B cannot start, or will fail, without A's artifact — e.g. *create the migration, then run it*; *generate the changelog from the new commits, then create a PR whose body embeds the changelog*) | **Merge** into a single combined task; do not split. If they appear as separate items in the user's prompt, either merge silently or ask one clarifying question to confirm |

**Heuristics for distinguishing soft-sequenced from independent:**

- Does task B's prompt or deliverable explicitly **reference** task A's output? → Soft-sequenced.
- Would running A and B in parallel yield duplicated/contradictory work? → Soft-sequenced.
- Would the consolidated report be unchanged regardless of order? → Independent.

**Heuristics for distinguishing soft-sequenced from hard-chained:**

- Can task B run, complete, and produce a non-broken artifact without A's output? → Soft-sequenced (parallel-safe, just lower quality).
- Will task B fail / produce a broken artifact / require manual stitching without A's output? → Hard-chained (must merge).

When multiple independent tasks remain, classify each intent and choose how to execute it. Mapped skills must be installed in the host (corvus or Claude Code marketplace); before routing, run a `Glob` check against `skills/**` to verify the skill directory exists. If a skill is unavailable, treat the task as a **free task** and pass full context in the `invoke_agent` prompt instead.

| Intent (match to user wording) | Route |
| --- | --- |
| create the PR | `agent-pr-creator` |
| generate tests / test cases | `test-case-gen` |
| write the bug report | `bug-report-gen` |
| generate test plan | `test-plan-gen` |
| rewrite commits / clean history | `rewrite-commit-history` |
| address PR review comments | `pr-comments-address` |
| scan page for test locators | `locators-scanner` |
| any task with no known skill | Free task — execute directly in the agent prompt |

**Worktree mode opt-in (cross-cutting):**

Detect worktree mode **before** classification by scanning the prompt for either an explicit `--worktree` flag or explicit worktree language (`in a worktree`, `isolated branch`, `auto-merge to main`, `spin up a worktree`, `use a worktree`). When neither is present, leave the worktree flag off and proceed to classification normally.

When the worktree flag is on, **stop and load [`references/worktree-mode.md`](references/worktree-mode.md)**. That file is the authoritative reference for the full worktree-mode workflow: the options table (`--branch`, `--base`, `--no-validate`, `--no-merge`, `--keep-branch`), Phase 2 Layout C, Phase 3 Mode 3 (including the SHA-comparison + diff-inspection commit verification that catches `--amend` and `--allow-empty`), the Phase 4 worktree footer and retry menu, the full Phase 4.5 merge pipeline with the `--no-merge` closing block, and the Case E end-to-end example. SKILL.md only retains the **inline troubleshooting entries** for worktree mode — workflow details belong in the reference.

Worktree mode forces a **single shared feature branch** for all surviving tasks regardless of dependency bucket: independent tasks (Layout A) and soft-sequenced waves (Layout B) both collapse to sequential execution inside one worktree. Hard-chained merges still happen before provisioning. If only one actionable task survives, worktree mode still applies — provision the worktree and run the single task there.

### Phase 2: User Confirmation

Run this phase **only** when orchestration is active (**two or more** independent tasks after Phase 1 — not when you exited early as a single direct task).

Before **any** delegated execution (`invoke_agent` launches, routed skill runs, or parallel dispatch): present the detected plan in one of the two layouts below depending on Phase 1's classification. Substitute real values for `N`, each numbered line’s route label, and each short description; keep headings, numbering, indentation, prompt line, and option wording unchanged.

**Layout A — all-independent (single wave):**

```text
Detected N tasks (all independent — single parallel wave):
  1. [skill or "free task"] → [short task description]
  2. ...

Proceed with all in parallel? (yes / remove N / add something / reorder)
```

**Layout B — soft-sequenced (multiple waves):**

```text
Detected N tasks across W waves (soft-sequenced — wave K+1 waits for wave K):
  Wave 1:
    1. [skill or "free task"] → [short task description]
    2. ...
  Wave 2:
    3. [skill or "free task"] → [short task description]
    ...

Proceed staged (wave-by-wave), or run everything in parallel anyway?
(staged / parallel / remove N / add something / reorder)
```

**Layout C — worktree mode** is used when Phase 1 set the worktree flag, regardless of dependency classification. It adds a `cancel-worktree` option that drops worktree mode and re-presents the plan in Layout A or B based on the original classification. Full template and option semantics are in [`references/worktree-mode.md`](references/worktree-mode.md) under "Phase 2 — Layout C".

Requirements:

- After sending that message, **stop** and wait for the user’s reply. **Execute nothing** — no tools, no sub-agents, no shell commands tied to carrying out tasks — until **explicit confirmation** arrives.
- **Explicit go-ahead** means an unambiguous affirmative to proceed with the **current** plan (`yes` for Layout A; `staged` or `parallel` for Layout B). Until then, execute **nothing**.
- **`reorder` semantics depend on the layout:**
  - Layout A (all-independent): `reorder` is **cosmetic only** — it changes the display order in the Phase 4 consolidated report, never the execution order (everything still fires in one parallel batch).
  - Layout B (soft-sequenced): `reorder` reassigns tasks **between waves** — moving a task into an earlier wave commits to running it before any task in later waves. Acknowledge the move explicitly when re-presenting the plan.
- If the user says **remove N** (task index): drop that task, **rebuild** the numbered list (`N` decrements; collapse empty waves in Layout B), and present the template **again**. Wait for confirmation again — same stop rule.
- If the user picks **`parallel`** under Layout B: collapse all waves into one parallel batch, **warn explicitly** that the soft-sequencing benefit (e.g. *test cases informed by the plan*) is forfeited, and re-present the plan as Layout A for one final confirmation before executing.
- If the user **add something** or changes scope: remap tasks per Phase 1 (re-classifying dependencies), then present the refreshed plan in the appropriate layout and wait again before any execution.
- If the reply is **ambiguous or off-topic**: answer the question or clarify, then re-present the current plan unchanged and wait again. Never treat a non-confirmation as confirmation.

### Phase 3: Parallel Execution

After Phase 2 confirmation on the final plan, choose the execution mode based on the confirmed layout:

**Mode 1 — Single parallel batch** (Layout A confirmed with `yes`, or Layout B collapsed via `parallel`):

- Issue **all** `invoke_agent` calls in a **single message** — Claude Code runs them concurrently without background flags or spawning overhead.

**Mode 2 — Staged execution / waves** (Layout B confirmed with `staged`):

- For each wave in order: emit **all** `invoke_agent` calls **for that wave** in a single message, wait until **every** sub-agent in the wave returns (success or failure), then proceed to the next wave.
- If any task in wave K fails, surface a brief status (`Wave K finished with M/Q successes — proceed with wave K+1?`) and wait for the user's go-ahead before launching wave K+1. This protects later waves that consume earlier output from operating on broken artifacts.
- If a wave completes fully, proceed to the next wave **without** asking — the staged mode is already a confirmed plan.
- Pass each downstream wave the relevant **completed-artifact paths or summaries** from earlier waves so soft-sequenced tasks can actually consume the prior output (e.g. wave 2's `test-case-gen` prompt should reference the `.qa/test-plan.md` path that wave 1's `test-plan-gen` produced).

**Mode 3 — Worktree-isolated sequential execution** runs when worktree mode is active (any layout). It provisions a sibling worktree via `scripts/setup-worktree.sh`, issues one **synchronous** `invoke_agent` call per task inside the worktree (sequentially — each commits before the next starts), and verifies each commit with SHA comparison + non-empty diff inspection (so `--amend` and `--allow-empty` cannot mask a no-op). After the chain finishes (success or first failure), proceed to Phase 4 and then Phase 4.5. Full step-by-step contract — including the exact SHA-verification snippet, sub-agent prompt template, and Test-plan obligation interaction — lives in [`references/worktree-mode.md`](references/worktree-mode.md) under "Phase 3 — Mode 3".

**Common to all modes:**

- **Mapped skill:** Each `invoke_agent` prompt must tell the sub-agent to invoke **that skill by name**, passing enough task-specific context (what to do, scope, filenames, acceptance hints) from the user's original prompt.
- **Free task:** The `invoke_agent` prompt is the task description plus whatever minimal project context is required (repo layout, conventions, paths) so it can succeed without ambiguity.

**Test-plan obligation (code-touching tasks only):**

Every `invoke_agent` prompt for a **code-touching** task (see the Phase 5 classification table) must include this contract clause **verbatim** in the prompt body, alongside the primary task instructions:

```text
After completing your primary task, append or update `.qa/test-plan.md`
with the surface area you changed, so qa-orchestrator can pick the right
QA agents in its Phase 2 selector:
  - If you added or modified a UI flow, add it under `## UI Flows` with
    the entry point URL/route, steps, and expected outcome.
  - If you added or modified an API endpoint, add it under
    `## API Endpoints` with method, path, auth requirements, and
    request/response shape.
  - If `.qa/test-plan.md` does not yet exist, scaffold it from
    `skills/qa/qa-orchestrator/references/test-plan.md` first, then
    add your section.
  - Do not delete or rewrite entries that belong to unchanged surface
    area — only add or update what your change touched.
  - If `.qa/test-plan.md` is being modified by another process, retry
    the update after a brief delay (a few seconds) rather than overwriting.
This update is required, not optional. The dev-orchestrator will hand
off to qa-orchestrator immediately after, and the test plan is the
input that decides which QA agents (qa-happy-path, qa-chaos-monkey,
custom personalities) actually run.
```

Doc-only tasks (`test-case-gen`, `test-plan-gen`, `bug-report-gen`, `locators-scanner`) are exempt — they do not change runtime behavior, so there is no surface area to register.

**Announcement (in the same message that issues the wave's `invoke_agent` calls — not a separate follow-up):**

- **Mode 1** — emit exactly this line (`N` = task count):

  `Launching N agents in parallel. I'll report back when they finish.`

- **Mode 2** — emit exactly this line per wave (`K` = current wave number, `W` = total waves, `N` = tasks in this wave):

  `Launching wave K of W (N agents in parallel). I'll report back when this wave finishes.`

- **Mode 3** — emit the announcement template defined in [`references/worktree-mode.md`](references/worktree-mode.md) once before the first sub-agent call.

After Phase 3 completes (all batches in Mode 1, all waves in Mode 2, or all sequential tasks in Mode 3), proceed to Phase 4.

### Phase 4: Result Consolidation

When **every** Phase 3 agent has finished (success or failure), consolidate outcomes into **one** user-visible report using **exactly** this structure. Substitute per-task icons, statuses, summaries, errors, and remediation; reuse the same separator lines. In the footer, replace `<successes>` with the count of completed tasks and `<total>` with the total tasks launched in this run:

```text
═══════════════════════════════
  Orchestrator Results
═══════════════════════════════
  ✓ [task 1] — completed
    Summary: [2 lines of what was done]

  ✓ [task 2] — completed
    Summary: [2 lines of what was done]

  ✗ [task 3] — failed
    Error: [reason]
    Action: [what to do to resolve it]
═══════════════════════════════
  <successes>/<total> tasks completed
```

- Use **✓ … — completed** (with a two-line `Summary:` indent block) only for successes.
- Use **✗ … — failed** only for failures; always include **`Error:`** and **`Action:`** on the indented lines afterward.
- The footer line is required and renders as e.g. `2/3 tasks completed`. Do not omit it.
- Preserve spacing, separators, and labels (`Summary:`, `Error:`, `Action:`) so the block stays skimmable.
- If **any** task **failed**, after the consolidated report ask whether the user wants to **retry the failed task(s) individually** before doing anything else that assumes the run is fully closed out.

**Worktree footer and retry menu (Mode 3 only):** append two `Worktree:` / `Branch:` lines to the consolidated report when Mode 3 was used. Footer terminal states are mutually exclusive: `merged & cleaned`, `merged & kept`, `preserved (--no-merge)`, or `preserved on failure`. On failure, the worktree-specific retry menu (`retry-failed / resume-merge / keep / discard`) **replaces** the default retry prompt and emits the exact resume command for `keep`. The retry menu fires **only** on failure — `--no-merge` follows its own closing block in Phase 4.5. The full footer enum, retry menu layout, and the resume command template (including the dynamic stripping of `validate-worktree.sh` for `--no-validate` and the `--keep-branch` append rule) live in [`references/worktree-mode.md`](references/worktree-mode.md) under "Phase 4 — worktree footer and retry menu".

### Phase 4.5: Worktree Merge (Mode 3 only)

Skip entirely when Mode 1 or Mode 2 was used. When Mode 3 ran with `--no-merge` captured in Phase 1, run only the dedicated **`--no-merge` closing block** (rewrites footer to `preserved (--no-merge)`, emits the resume command, skips Phase 5). Otherwise run the four-step pipeline — validate → merge → reconciler (only on merge exit code `2`) → footer rewrite — only when Phase 4 shows `<total>/<total>` tasks completed; if any task failed, defer to the worktree retry prompt instead. The full pipeline, script invocations (with the `--no-validate`, `--no-merge`, `--keep-branch` routing), the reconciler prompt template, and the `--no-merge` closing block are documented in [`references/worktree-mode.md`](references/worktree-mode.md) under "Phase 4.5 — worktree merge pipeline".

### Phase 5: QA Verification

After the Phase 4 report is posted (and Phase 4.5 has merged, when Mode 3 was used), hand off to **`qa-orchestrator`** to verify the work end-to-end — but only when there is something to verify.

**Worktree-mode note:** when Mode 3 was used and Phase 4.5 completed cleanly, the changes are already on the base branch in the primary worktree, so QA runs unchanged — the handoff scope (PR number or task summary) is identical to Mode 1 / Mode 2. If Phase 4.5 left the worktree as `preserved on failure` **or** `preserved (--no-merge)`, **skip** Phase 5 — nothing has reached the base branch yet in either case, so there is nothing merged to verify.

**Classify each completed task as code-touching or doc-only:**

| Mapped skill | Touches code/repo state? |
| --- | --- |
| `agent-pr-creator` | Yes (creates / pushes a PR) |
| `pr-comments-address` | Yes (edits source) |
| `rewrite-commit-history` | Yes (rewrites git history) |
| Free task that wrote or edited working-tree files | Yes |
| `test-case-gen` / `test-plan-gen` / `bug-report-gen` / `locators-scanner` | No (doc-only) |
| Free task that only generated docs | No |

**Run QA when:** at least one completed task is code-touching.

**Skip QA when:**

- Every completed task is doc-only — print `QA verification skipped — no testable artifacts produced.` and stop.
- Every Phase 3 task failed — defer to the Phase 4 retry prompt; do not run QA on broken work.

**How to invoke:**

- Issue **one** `invoke_agent` call instructing the sub-agent to **"Run a full QA session"** using the `qa-orchestrator` skill (Mode A — Full Run: Phase 1 Gather Context → Phase 2 Select Agents → Phase 3 Spawn QA Agents → Phase 4 Collect Results → Phase 5 Bug Triage → Phase 6 Generate Report). Use that exact phrase — "Run a full QA session" — so `qa-orchestrator`'s positive trigger fires immediately without ambiguity.
- Because every code-touching Phase 3 task already updated `.qa/test-plan.md` (Test-plan obligation), `qa-orchestrator`'s Phase 2 selector will see fresh `## UI Flows` and/or `## API Endpoints` matching exactly the surface area that just changed — no manual test-plan editing is needed between Phase 4 and Phase 5.
- The `invoke_agent` prompt **must explicitly request all available QA agents** so the run includes:
  - **`qa-happy-path`** — UI flow coverage via Playwright (when test plan has `## UI Flows`).
  - **`qa-chaos-monkey`** — adversarial / stress / boundary API testing (when test plan has `## API Endpoints`).
  - **All custom personalities** declared in `.qa/config.yml → personalities.custom`.
  - Do **not** narrow the agent set — only `qa-orchestrator`'s own gating (Playwright availability, test-plan section content) may exclude an agent. If a gate still excludes one despite the Phase 3 obligation, that means a code-touching Phase 3 task skipped its test-plan update — flag it as the troubleshooting case "Test-plan obligation skipped" and have the user re-run that slice or update the plan manually before QA.
- Pass scope as the argument:
  - **PR number** if `agent-pr-creator` succeeded in this run (use the PR it created), or if a PR already exists on the current branch (`gh pr list --head $(git branch --show-current)`).
  - Otherwise pass a short scope blurb: original user goal + list of code-touching task summaries from Phase 4 so `qa-orchestrator` can scope its test plan.
- Inherit the parent session's interactive vs non-interactive mode — propagate `--non-interactive` if `$CI=true` or the flag was set on the parent.

**Announcement (in the same message that issues the QA `invoke_agent` call):**

`Handing off to qa-orchestrator (full workflow — happy path + chaos monkey + custom agents) to verify the run.`

**After QA completes:**

- Quote the qa-orchestrator verdict line (`Verdict: PASS / FAIL` plus the report path) **verbatim** to the user — do not paraphrase.
- If QA filed BLOCKER or HIGH issues, list their URLs underneath the verdict so the user can jump to them.
- Treat a QA FAIL as a follow-up signal, not a dev-orchestrator failure: the dev tasks already completed; QA simply found regressions to address next.

## Examples

### Positive Trigger

User: "Generate the test plan for payments, generate the test cases and create the PR"

Expected behavior: Identify **three** independent tasks mapped to **`test-plan-gen`** (payments test plan), **`test-case-gen`** ("generate … test cases"), and **`agent-pr-creator`** ("create the PR"). Run Phase 2 and show **`Detected 3 tasks:`** with those routes plus short descriptions, then **stop** until the user confirms (**yes** / remove / add / reorder). After confirmation, Phase 3 issues **parallel** `invoke_agent` calls for each task (skill-bearing prompts); Phase 4 posts the **`Orchestrator Results`** consolidation. Phase 5 fires because **`agent-pr-creator`** is code-touching: hand off to **`qa-orchestrator`** with the new PR number, requesting the **full QA workflow** (Mode A) with **all available agents — `qa-happy-path` + `qa-chaos-monkey` + any custom personalities** — then quote its verdict back to the user verbatim.

Case B — doc-only run, QA skipped:

User: "I need the bug report and the test plan for the auth module"

Expected behavior: Detect **two** tasks — **`bug-report-gen`** for the bug report scoped to auth, **`test-plan-gen`** for the auth test plan — then the same Phase 2 → Phase 3 → Phase 4 path with **`N=2`**. Phase 5 is **skipped** — both tasks are doc-only — and the user sees `QA verification skipped — no testable artifacts produced.`

Case C — mixed run, QA runs on the code-touching slice:

User: "Address the PR review comments and generate the matching test cases"

Expected behavior: Detect **two** tasks — **`pr-comments-address`** (code-touching) and **`test-case-gen`** (doc-only). After Phase 4, Phase 5 fires because at least one completed task touched code; pass the existing PR number (read from `gh pr list --head $(git branch --show-current)`) to **`qa-orchestrator`** so it scopes QA to the addressed comments.

Case D — soft-sequenced run (waves):

User: "Generate the test plan for the new checkout flow, then generate the test cases from it"

Expected behavior: Phase 1 detects **two** tasks but classifies them as **soft-sequenced** — `test-case-gen` benefits from reading `test-plan-gen`'s output (`.qa/test-plan.md`) but does not literally fail without it. Present **Layout B** in Phase 2: `Wave 1: test-plan-gen`, `Wave 2: test-case-gen`. User picks `staged`. Phase 3 runs in Mode 2: emit wave 1's single `invoke_agent` call, wait for the test plan file to land, then emit wave 2's `invoke_agent` call passing the test plan path so the test-case generator can consume it. Phase 4 consolidates results from both waves. Phase 5 is **skipped** — both tasks are doc-only.

Case E — worktree mode (single isolated branch, sequential execution): see [`references/worktree-mode.md`](references/worktree-mode.md) "End-to-end example (Case E)" for the full `/orchestrate --worktree generate the migration and the matching service refactor` walkthrough covering Phases 1 → 5.

### Non-Trigger (negative triggers)

User: "create the PR"

Expected behavior: Exactly **one** actionable task routed to **`agent-pr-creator`**. **Do not** run multi-task orchestration (no **`Detected N tasks:`** plan, no parallel batch framing). Carry out **`agent-pr-creator`** norms **directly** in the foreground conversation.

Follow-up (**also** Non-Trigger):

User: "what does this file do?"

Expected behavior: Informational question — **not** actionable implementation work — so **exclude** **`dev-orchestrator`**. Answer from **`Read`/context** normally without skill routing or phased orchestration.

## Troubleshooting

### Agent cannot find mapped skill

- Error: Delegate reports unknown skill / "skill not installed" while running a routed task.
- Cause: Marketplace drift, typo, Claude Code slash menu vs corvus installs, or a skill referenced in the routing table that is not packaged in this host.
- Solution: Retry that slice as a **free task** — send a standalone `invoke_agent` call with the concrete goal, files, constraints, and acceptance hints so the sub-agent can fulfill it without relying on skill discovery. Mention the unavailable skill id to the user; offer installing it or simplifying to one manual pass.
- Expected behavior: The task completes via the free-task fallback, the consolidated report flags it as `[free task]`, and the user is told which skill was missing and how to install it.

### Ambiguous single vs compound prompt

- Error: Prompt could be **one chained goal** ("do A then B as one workflow") versus **two separable deliveries**.
- Cause: Boundary words ("then", nested scope) obscure independence.
- Solution: Pause orchestration until resolved — ask **one** targeted question (e.g. "Separate deliverables?", "Must A finish before B?"). Prefer **merged single task** unless the user insists on splitting. Only reopen Phase 2 when **two-plus** mutually independent tasks survive.
- Expected behavior: No sub-agents launch until the user disambiguates; the run either continues as a single direct task or restarts Phase 2 with the corrected task list.

### Parallel execution unavailable

- Error: Concurrent `invoke_agent` calls not supported in the current client or session.
- Cause: Older client, restrictive session, or host policy without concurrent `invoke_agent` fan-out.
- Solution: Announce the fallback so expectations stay aligned, then execute **sequentially** — run each `invoke_agent` call start-to-finish in plan order, only moving to N+1 after N completes. Preserve Phase 4 consolidation and per-task summaries.
- Expected behavior: All tasks still complete and the same Phase 4 report is produced; only the wall-clock time degrades — correctness is preserved.

### QA verification cannot run

- Error: Phase 5 hand-off to `qa-orchestrator` aborts (skill not installed, missing `.qa/config.yml`, missing `.qa/test-plan.md`, or `.env.qa` URLs absent).
- Cause: This repo has not been initialized for QA, or the `qa-orchestrator` skill is not packaged in the host marketplace.
- Solution: Do **not** retry the dev tasks — they already completed. Surface the qa-orchestrator setup error verbatim, point the user at `skills/qa/qa-orchestrator/SKILL.md` (template files in `references/`), and offer to skip QA for this run.
- Expected behavior: The Phase 4 report stays valid, the user is told exactly which QA prerequisite is missing, and dev-orchestrator exits cleanly without overwriting completed work.

### Misclassified dependency surfaces during execution

- Error: A task launched in parallel (Mode 1) or in an earlier wave (Mode 2) actually depends on output that doesn't exist yet — sub-agent reports a missing file, missing PR number, or empty input artifact.
- Cause: Phase 1 classified the task as Independent or Soft-sequenced when it was really **Hard-chained**, OR Phase 2's `parallel` collapse was used on a Layout B plan whose dependency was tighter than soft.
- Solution: Cancel any still-running sibling tasks if safe, mark the failing task as `failed` in Phase 4, and re-present the plan in Phase 2 with the dependency upgraded one level (Independent → Soft-sequenced, or two soft-sequenced tasks merged into a single Hard-chained task). Ask the user to confirm `staged` (or merged) before re-launching.
- Expected behavior: After the re-classification, the same prompt completes successfully because the dependency now executes in the correct order or as a unified task. Future runs of similar prompts should land in the corrected bucket from the start.

### Test-plan obligation skipped

- Error: A code-touching Phase 3 task completed but did not append or update `.qa/test-plan.md` for the surface area it changed; `qa-orchestrator`'s Phase 2 selector then excludes `qa-happy-path` or `qa-chaos-monkey` because the relevant `## UI Flows` / `## API Endpoints` section is empty or missing the new entry.
- Cause: The `invoke_agent` prompt for that task either omitted the Test-plan obligation clause, or the sub-agent finished its primary work and stopped before the post-task update.
- Solution: Identify the offending task from the Phase 4 report (compare the diff to `.qa/test-plan.md`). Either (a) re-spawn that single task with the obligation clause as the only remaining work, or (b) update `.qa/test-plan.md` manually with the changed UI flow / API endpoint, then re-run Phase 5. Do **not** mark the run "complete" until coverage is registered.
- Expected behavior: After the patch, `qa-orchestrator`'s Phase 2 picks up `qa-happy-path` and/or `qa-chaos-monkey` matching the new surface area, and the full QA workflow runs as designed.

### Worktree path collision

- Error: `scripts/setup-worktree.sh` aborts in Phase 3 Mode 3 with `path already exists: <path>`.
- Cause: A previous worktree-mode run left a stale sibling worktree, or the auto-derived path collides with an unrelated directory next to the repo.
- Solution: Run `git worktree list` to confirm whether the offending path is a tracked worktree. If yes, remove it with `git worktree remove "<path>"` (or `--force` if dirty) and retry the original prompt. If it is an unrelated directory, instruct the user to pass an explicit `--branch <unique name>` on the retry so the derived sibling path shifts to a fresh slug. Do **not** launch any sub-agent until the path is clear — the worktree flag stays armed for the retry.
- Expected behavior: The retry creates a fresh worktree, Phase 2 reconfirms via Layout C, and Phase 3 Mode 3 runs the full sequential chain through Phase 4.5.

### Worktree validation fails before merge

- Error: `scripts/validate-worktree.sh` exits non-zero in Phase 4.5; the merge is skipped and the worktree footer is rewritten to `preserved on failure`.
- Cause: A code-touching sub-agent introduced a regression in lint, typecheck, or tests, OR the worktree is missing setup the checks require (dependencies not installed, env vars not copied beyond what `setup-worktree.sh` migrated).
- Solution: `cd <worktree path>` and run the failing command manually. For a real regression, fix it inside the worktree (either by hand or via a fresh `/orchestrate --worktree --no-merge` pass that lets a sub-agent address it), then finish the merge manually with `bash skills/assistant/dev-orchestrator/scripts/merge-worktree.sh "<path>" "<branch>" "<base>"`. For a setup gap, install deps in the worktree (`npm ci` etc.) and rerun the merge script. Use `--no-validate` only when the gap is structural and unrelated to the diff.
- Expected behavior: After the fix, the merge runs cleanly, the worktree and feature branch are cleaned up, the footer reaches `merged & cleaned`, and Phase 5 (QA) fires normally because the diff is now on the base branch.

### Worktree merge conflict ambiguous

- Error: The reconciler sub-agent ran `git merge --abort` and flagged a file as semantically ambiguous; the worktree and feature branch are preserved.
- Cause: Both branches rewrote the same logic in incompatible ways — typical when the base branch evolved while the worktree run was active (e.g. another developer landed an overlapping refactor on `main` mid-flight).
- Solution: Do **not** retry the reconciler — it already decided. Open the feature branch and the base branch side by side, decide which intent should win (or merge them manually), commit the resolution on the base branch, then run cleanup manually: `git worktree remove "<path>"` and `git branch -d "<branch>"`. To preserve both intents alive, rebase the feature branch onto the updated base, resolve interactively, then rerun `scripts/merge-worktree.sh`. Phase 5 (QA) only fires after the base branch is in its intended state — if the conflict resolution changed the diff significantly, rerun the QA handoff manually with the corrected scope.
- Expected behavior: After manual resolution, the base branch carries the intended diff, the worktree and feature branch are cleaned up, and the QA pass scopes against the actually-landed change set rather than the pre-merge feature branch.

### QA after a manual merge from a `--no-merge` run

- Error: The user opted into `--no-merge`, the run ended at the Phase 4.5 closing block with the worktree `preserved (--no-merge)`, the user later finished the merge manually (either by pasting the emitted resume command or by handling the merge by hand), and now wants `qa-orchestrator` to verify the diff that finally landed — but the original dev-orchestrator run is long-since closed and never auto-fired Phase 5.
- Cause: `--no-merge` is an explicit opt-out from both Phase 4.5 and Phase 5, so the orchestrator stops at the closing block with the worktree preserved and never hands off to QA. After the manual merge there is no live orchestrator session to resume from — Phase 5 must be invoked by hand against the now-landed change set.
- Solution: Re-invoke `qa-orchestrator` directly with the same scope shape Phase 5 would have used. Issue **one** `invoke_agent` call whose prompt opens with the literal phrase `Run a full QA session` (so `qa-orchestrator`'s positive trigger fires unambiguously) and explicitly requests all available agents — `qa-happy-path`, `qa-chaos-monkey`, and every custom personality declared in `.qa/config.yml → personalities.custom`. Pass scope in this priority order:

  1. **PR number, if a PR actually exists** for the merge. After the typical local-merge path (paste the resume command → `merge-worktree.sh` pushes the merge commit directly to `origin/<BASE>`) **no PR is opened**, so this branch usually does not apply. Try the lookups in this order before giving up: (a) `gh pr list --head "<WORKTREE_BRANCH>" --state all --json number,url` — works only when the feature branch still exists on the remote (the user passed `--keep-branch` or opened a PR before cleanup); `--head` filters by **source** branch, never the base; (b) `gh pr list --state merged --search "<merge-commit-sha>" --json number,url` — works once the merge commit is on `origin/<BASE>` and the user (or another bot) opened a retroactive PR — the SHA comes from `git log -1 --merges --format=%H "<BASE>"`. If both return empty, fall through.
  2. **Scope blurb (the typical case)**: pass `goal: <original user prompt> | landed: <comma-separated list of code-touching Phase 4 task summaries>`. Both halves are already in the user's preserved Phase 4 report, so no fresh inspection is needed.

  Inherit `--non-interactive` if `$CI=true`. The `.qa/test-plan.md` entries that the code-touching tasks registered (via the Test-plan obligation clause) during their Phase 3 Mode 3 runs are still in the file, so `qa-orchestrator`'s Phase 2 selector will pick up the right agents without manual editing.
- Expected behavior: `qa-orchestrator` runs the full workflow (Mode A — happy path + chaos monkey + custom agents) against the merged base branch exactly as it would have in the auto-merge path, scoped to the same surface area registered during the original run. The verdict line plus any BLOCKER/HIGH issue URLs are returned to the user; nothing about the manual merge changes the QA contract.