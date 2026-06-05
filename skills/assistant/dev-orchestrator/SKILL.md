---
name: dev-orchestrator
description: Detect bundled dev work — multiple implementation tasks in one prompt
  — and dispatch each as an isolated agent (own session, own cwd, scoped tools, awaited),
  classifying dependencies so independent tasks fan out in parallel and dependent
  ones run in order. Use when a prompt bundles two or more dev tasks like "generate
  test cases and create the PR", "bug report and test plan", "do X and Y in parallel",
  or explicit /orchestrate. Opt into worktree mode via "--worktree" (or "in a worktree",
  "isolated branch", "auto-merge to main") to provision an integration branch off
  the protected base (develop/dev preferred; else newer main/master tip), spawn one
  worktree per task off that branch (parallel for independent, waves for soft-sequenced,
  merged-into-one for hard-chained), and hand off to agent-pr-creator for the protected-base
  PR. Resolves issue-tracker tickets (Linear, Jira, GitHub Issues, Notion) via MCP
  and uses the ticket id as the integration branch name. Skip for single-task asks,
  questions, or info requests.
allowed-tools:
- Task
- Bash
- Glob
- Grep
- Read
effort: high
metadata:
  category: assistant
  tags:
  - orchestration
  - parallel
  - multi-task
  - agents
  - isolated-agents
  - workflow
  - git
  - worktree
  - integration-branch
  - ticket
  - linear
  status: draft
  version: 5
  triggers:
    positive:
    - do X and Y
    - I need A, B and C
    - in parallel
    - "/orchestrate"
    - run tasks in parallel
    - generate the test cases and create the PR
    - spin up a worktree and open the PR
    - implement ticket in a worktree
    - orchestrate tasks
    negative:
    - what does this do
    - explain this
    - just create the PR
    - only one task
---

# Dev Orchestrator

Coordinate multi-task development prompts by detecting tasks, confirming the plan with the user, dispatching one **isolated agent** per task, and consolidating their results into a single report.

## Workflow

The orchestration runs in five phases. Phase 1 always runs; Phases 2–4 run only when two or more independent tasks survive Phase 1; Phase 5 runs after Phase 4 only when the completed work produced testable artifacts (code or repo state changes). Phase 0 (opt-in) runs ahead of Phase 1 when the prompt references an issue-tracker ticket.

**Agent dispatch is host-agnostic.** Every task — parallel or sequential, code-touching or doc-only, worktree-mode or not — is dispatched as an **isolated agent** with its own session, own working directory, scoped tool list, and an orchestrator-awaited completion. The contract and the per-host primitive (Claude Code `Task` with `run_in_background: true`, Cursor SDK `Agent.create` / `Agent.prompt`, etc.) live in [`references/dispatch-contract.md`](references/dispatch-contract.md). SKILL.md says "dispatch an agent"; that reference documents what that means operationally.

For end-to-end **scenario walkthroughs** (input prompt → phase-by-phase trace → exact reports the user will see), see [`references/workflow.md`](references/workflow.md) — covers doc-only fan-out, mixed code/doc fan-out, soft-sequenced waves, worktree mode (single + multi-subtask), worktree `--no-merge` opt-out, and hard-chained merges, plus a Phase 2 confirmation cheatsheet and a recovery checklist.

### Phase 0: Ticket Resolution (opt-in)

Phase 0 fires **before** Phase 1 whenever the prompt references an issue-tracker ticket — Linear / Jira (`[A-Z]+-\d+`, e.g. `ABC-42`), GitHub Issues (`#123` or `owner/repo#123`), or a Notion page URL — **or** when the user explicitly passed `--ticket <id>`. When no reference is detected, Phase 0 is a no-op and the existing flow runs unchanged.

When fired, the orchestrator resolves the ticket via the matching MCP tool (`mcp__linear__get_issue`, `mcp__jira__get_issue`, `mcp__github__get_issue`, or `mcp__notion__get_page` — confirm the tool is registered before calling) and extracts a normalized envelope (`title`, `state`, `description`, parsed `acceptance_criteria`, `labels`, `url`). The envelope is **prepended** to the prompt body — the bare ticket reference is stripped — so Phase 1 classification sees the ticket's acceptance criteria as natural split anchors. When worktree mode is also on, the resolved ticket id becomes the **integration branch** name (`ticket/<TICKET-ID>` by default, or `<prefix>/<ticket-id>-<slug>` when a `--prefix` / `--slug` override is captured) — every per-task worktree provisioned in Phase 3 is branched off that integration branch, and Phase 4.5 hands the integration branch off to `agent-pr-creator` for the protected-base PR.

Detection patterns, tracker disambiguation (Linear vs Jira), the full MCP fetch contract, per-tracker extraction rules, failure handling (missing MCP / 404 / permission denied / closed ticket / mixed batches), the optional `.dev-orchestrator.yml` config, and a worked end-to-end example all live in [`references/ticket-resolution.md`](references/ticket-resolution.md).

### Phase 1: Task Detection

Read the user's full prompt and pull out discrete **tasks** — units of executable development work.

- Split along natural boundaries ("also", numbered lists, "and", parallel clauses).
- If you detect **only one** actionable task — or several steps that collapse into **one** hard-chained task per the classification below — **do not** use orchestration modes for this skill. Handle it **directly** in the main conversation with **zero** orchestration overhead: no splitting, no parallel agent dispatch.
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

When multiple independent tasks remain, classify each intent and choose how to execute it. Mapped skills must be installed in the host (corvus or Claude Code marketplace); before routing, run a `Glob` check against `skills/**` to verify the skill directory exists. If a skill is unavailable, treat the task as a **free task** and pass full context in the agent's dispatch prompt instead.

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

When the worktree flag is on, **stop and load [`references/worktree-mode.md`](references/worktree-mode.md)**. That file is the authoritative reference for the full worktree-mode workflow: the options table (`--integration-branch`, `--base`, `--no-validate`, `--no-merge`, `--keep-branch`), the protected-base resolution rules (`develop` then `dev`; else `main` vs `master` by newer tip), Phase 2 Layout C, Phase 3 Mode 3 (integration-branch provisioning, per-task worktree dispatch, parallel-vs-wave routing, SHA-comparison + diff-inspection commit verification), the Phase 4 worktree footer and retry menu, the full Phase 4.5 PR-handoff pipeline with the `--no-merge` closing block, and the Case E end-to-end example. SKILL.md only retains the **inline troubleshooting entries** for worktree mode — workflow details belong in the reference.

Worktree mode is **dependency-aware** — it does **not** collapse all surviving tasks into a single branch:

- **Integration branch**: every run provisions one integration branch off the protected base (resolved by preferring `develop`, then `dev`; if neither exists, `main` or `master` — whichever exists alone, or whichever tip is newer when both exist — then fetched fresh from origin before branching). The integration branch is named from the ticket id when Phase 0 resolved one (`ticket/<TICKET-ID>` by default), from `--integration-branch <name>` when the user passed it, or auto-derived as `feature/<slug>-<unix>` otherwise. **All** per-task worktrees branch off this integration branch.
- **Independent tasks** (Layout A) → each task gets its **own** per-task worktree off the integration branch tip; the orchestrator dispatches one **isolated agent per task** (per [`references/dispatch-contract.md`](references/dispatch-contract.md)) and lets them run in **parallel**. As each agent returns, its worktree merges back into the integration branch **sequentially** (one at a time, because git merges serialize).
- **Soft-sequenced tasks** (Layout B) → each wave runs the same independent-parallel pattern internally (per-task worktrees, one isolated agent per task dispatched in parallel within the wave, sequential merges into the integration branch). Wave N's merges complete **before** wave N+1's worktrees and agents are provisioned, so wave N+1 sees wave N's commits via the updated integration branch tip.
- **Hard-chained tasks** → merged into a single combined task during Phase 1 classification (unchanged from non-worktree mode). The merged task still runs in one isolated agent inside one worktree, awaited synchronously.
- **Single surviving task** → still applies — provision the integration branch, then a single per-task worktree off it, dispatch one isolated agent, await it, merge back. Phase 4.5 still hands the integration branch off to `agent-pr-creator`.

### Phase 2: User Confirmation

Run this phase **only** when orchestration is active (**two or more** independent tasks after Phase 1 — not when you exited early as a single direct task).

Before **any** delegated execution (agent dispatch, routed skill runs, or parallel fan-out): present the detected plan in one of the two layouts below depending on Phase 1's classification. Substitute real values for `N`, each numbered line’s route label, and each short description; keep headings, numbering, indentation, prompt line, and option wording unchanged.

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

**Layout C — worktree mode** is used when Phase 1 set the worktree flag. It echoes the integration branch name, the resolved protected base, and the per-wave per-task worktree breakdown so the user sees up-front whether tasks will fan out in parallel or run as waves. It adds a `cancel-worktree` option that drops worktree mode and re-presents the plan in Layout A or B based on the original classification. Full template and option semantics — including the worktree options echo line — are in [`references/worktree-mode.md`](references/worktree-mode.md) under "Phase 2 — Layout C".

Requirements:

- After sending that message, **stop** and wait for the user’s reply. **Execute nothing** — no tools, no agent dispatches, no shell commands tied to carrying out tasks — until **explicit confirmation** arrives.
- **Explicit go-ahead** means an unambiguous affirmative to proceed with the **current** plan (`yes` for Layout A; `staged` or `parallel` for Layout B). Until then, execute **nothing**.
- **`reorder` semantics depend on the layout:**
  - Layout A (all-independent): `reorder` is **cosmetic only** — it changes the display order in the Phase 4 consolidated report, never the execution order (everything still fires in one parallel batch).
  - Layout B (soft-sequenced): `reorder` reassigns tasks **between waves** — moving a task into an earlier wave commits to running it before any task in later waves. Acknowledge the move explicitly when re-presenting the plan.
- If the user says **remove N** (task index): drop that task, **rebuild** the numbered list (`N` decrements; collapse empty waves in Layout B), and present the template **again**. Wait for confirmation again — same stop rule.
- If the user picks **`parallel`** under Layout B: collapse all waves into one parallel batch, **warn explicitly** that the soft-sequencing benefit (e.g. *test cases informed by the plan*) is forfeited, and re-present the plan as Layout A for one final confirmation before executing.
- If the user **add something** or changes scope: remap tasks per Phase 1 (re-classifying dependencies), then present the refreshed plan in the appropriate layout and wait again before any execution.
- If the reply is **ambiguous or off-topic**: answer the question or clarify, then re-present the current plan unchanged and wait again. Never treat a non-confirmation as confirmation.

### Phase 3: Agent Dispatch

After Phase 2 confirmation on the final plan, dispatch one **isolated agent per task**. All three modes below share the dispatch contract documented in [`references/dispatch-contract.md`](references/dispatch-contract.md) — read it before issuing the first agent call. Each agent has its own session, its own working directory (worktree path in Mode 3; repo root otherwise), a scoped tool list matching the task's intent, and is awaited individually so the orchestrator can surface per-agent completion lines in real time.

**Mode 1 — Single-wave parallel dispatch** (Layout A confirmed with `yes`, or Layout B collapsed via `parallel`):

- Dispatch **all N agents at once** (back-to-back dispatch calls — see `dispatch-contract.md` for the per-host primitive). Each agent starts immediately and runs in its own session.
- **Poll each agent individually** as it returns. Surface a per-agent completion line the moment it lands — the format is fixed by `dispatch-contract.md` "Per-agent completion line format" (`[wave 1] agent i of N — completed / — failed: <reason>`). Don't wait for the whole batch before reporting partial progress; the user wants to see slow agents finish in real time.
- A failed agent does **not** auto-cancel its siblings. Let the wave run to completion, then move to Phase 4.

**Mode 2 — Multi-wave parallel dispatch** (Layout B confirmed with `staged`):

- For each wave in order: dispatch **all agents in that wave at once**, then poll each individually using the same per-agent completion line format (`[wave K] agent i of N — completed / — failed: <reason>`).
- Wave K+1 only begins after the **slowest** wave-K agent returns (success or failure). This preserves the soft-sequencing guarantee — wave K+1 always sees wave K's full output, never a partial view.
- If any task in wave K fails, surface a brief status (`Wave K finished with M/Q successes — proceed with wave K+1?`) and wait for the user's go-ahead before launching wave K+1. This protects later waves that consume earlier output from operating on broken artifacts.
- If a wave completes fully, proceed to the next wave **without** asking — the staged mode is already a confirmed plan.
- Pass each downstream wave the relevant **completed-artifact paths or summaries** from earlier waves so soft-sequenced tasks can actually consume the prior output (e.g. wave 2's `test-case-gen` agent prompt should reference the `.qa/test-plan.md` path that wave 1's `test-plan-gen` agent produced).

**Mode 3 — Worktree-isolated dependency-aware dispatch** runs when worktree mode is active (any layout). It provisions an **integration branch** off the protected base via `scripts/setup-integration-branch.sh`, then for each wave runs `scripts/setup-worktree.sh --base <integration-branch>` once per task and dispatches one **isolated agent per worktree** in parallel (same dispatch+poll pattern as Mode 1, but the cwd pinned to that task's worktree path). When each agent returns, its commit is verified with SHA comparison + non-empty diff inspection (so `--amend` and `--allow-empty` cannot mask a no-op) and the worktree is merged back into the integration branch sequentially via `scripts/merge-worktree.sh --no-push`. Independent (Layout A) plans run as one wave; soft-sequenced (Layout B) plans run as W waves with wave N's merges completing before wave N+1's worktrees and agents are provisioned. Full step-by-step contract — integration-branch provisioning, per-task worktree dispatch, the SHA-verification snippet, agent prompt template, Test-plan obligation interaction, and the failure-handling rules — lives in [`references/worktree-mode.md`](references/worktree-mode.md) under "Phase 3 — Mode 3".

**Common to all modes:**

- **Mapped skill:** Each agent's dispatch prompt must tell the agent to invoke **that skill by name**, passing enough task-specific context (what to do, scope, filenames, acceptance hints) from the user's original prompt. The agent's scoped tool list (see `dispatch-contract.md` "Tool-scope cheatsheet") should match the skill's needs.
- **Free task:** The dispatch prompt is the task description plus whatever minimal project context is required (repo layout, conventions, paths) so it can succeed without ambiguity. Scope tools per the cheatsheet — `Read` + `Glob` + `Grep` + `Write` for doc-only, add `Edit`/`StrReplace` + `Bash` (git) for code-touching.
- **Per-agent completion line:** every agent in every wave surfaces a line in the `[wave K] agent i of N — …` shape the moment it returns. Single-task runs use `agent 1 of 1` so the user still sees a heartbeat.

**Test-plan obligation (code-touching tasks only):**

Every dispatch prompt for a **code-touching** task (see the Phase 5 classification table) must include the contract clause from [`references/test-plan-obligation.md`](references/test-plan-obligation.md) **verbatim** in the prompt body, alongside the primary task instructions. Read that file at dispatch time to get the exact clause text — do not paraphrase it.

Doc-only tasks (`test-case-gen`, `test-plan-gen`, `bug-report-gen`, `locators-scanner`) are exempt — they do not change runtime behavior, so there is no surface area to register.

**Announcement (in the same message that issues the wave's agent dispatches — not a separate follow-up):**

- **Mode 1** — emit exactly this line (`N` = task count):

  `Dispatching N isolated agents in parallel (wave 1 of 1). I'll surface each agent's completion as it lands.`

- **Mode 2** — emit exactly this line per wave (`K` = current wave number, `W` = total waves, `N` = tasks in this wave):

  `Dispatching wave K of W: N isolated agents in parallel. I'll surface each agent's completion as it lands; wave K+1 starts after the slowest wave-K agent returns.`

- **Mode 3** — emit the announcement template defined in [`references/worktree-mode.md`](references/worktree-mode.md) once before each wave's parallel agent dispatch (so the user sees per-wave fan-out, not one chain-level announcement).

After Phase 3 completes (all agents returned in Mode 1, all waves' agents returned in Mode 2, or all waves' agents returned and merged in Mode 3), proceed to Phase 4.

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

**Worktree footer and retry menu (Mode 3 only):** append three `Integration:` / `Worktrees:` / `Base:` lines to the consolidated report when Mode 3 was used. The integration branch footer terminal states are mutually exclusive: `PR opened`, `validated, awaiting PR`, `preserved (--no-merge)`, or `preserved on failure`. On failure, the worktree-specific retry menu (`retry-failed / resume-pr / keep / discard`) **replaces** the default retry prompt and emits the exact resume command for `keep`. The retry menu fires **only** on failure — `--no-merge` follows its own closing block in Phase 4.5. The full footer enum, retry menu layout, and the resume command template (including the dynamic stripping of `validate-worktree.sh` for `--no-validate` and the `--keep-branch` append rule) live in [`references/worktree-mode.md`](references/worktree-mode.md) under "Phase 4 — worktree footer and retry menu".

### Phase 4.5: Integration-branch PR handoff (Mode 3 only)

Skip entirely when Mode 1 or Mode 2 was used. When Mode 3 ran with `--no-merge` captured in Phase 1, run only the dedicated **`--no-merge` closing block** (rewrites footer to `preserved (--no-merge)`, emits the resume command, skips Phase 5). Otherwise run the three-step pipeline — validate the integration branch → push the integration branch to origin → delegate PR creation (integration branch → protected base) to `agent-pr-creator` — only when Phase 4 shows `<total>/<total>` tasks completed; if any task failed, defer to the worktree retry prompt instead. The orchestrator no longer merges directly to the protected base in this phase — `agent-pr-creator` owns the PR (and the eventual merge, when the user approves it on the platform). The full pipeline, script invocations (with the `--no-validate`, `--no-merge`, `--keep-branch` routing), the `agent-pr-creator` handoff prompt template, and the `--no-merge` closing block are documented in [`references/worktree-mode.md`](references/worktree-mode.md) under "Phase 4.5 — integration-branch PR handoff".

### Phase 5: QA Verification

After the Phase 4 report is posted (and Phase 4.5 has merged, when Mode 3 was used), hand off to **`qa-orchestrator`** to verify the work end-to-end — but only when there is something to verify.

**Worktree-mode note:** when Mode 3 was used and Phase 4.5 completed cleanly, `agent-pr-creator` already opened the integration-branch → protected-base PR. Pass that PR number into `qa-orchestrator` as the scope so QA runs against the same diff the human reviewer will see. If Phase 4.5 left the run at `preserved on failure` **or** `preserved (--no-merge)`, **skip** Phase 5 — no PR exists yet in either case, so there is nothing to verify. The `validated, awaiting PR` state (Phase 4.5 validated but the PR handoff failed) also skips Phase 5; the troubleshooting entry "Integration-branch PR handoff failed" explains how to resume.

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

- **Dispatch one isolated agent** carrying the `qa-orchestrator` skill, awaited synchronously (only one agent in this wave, so there is no parallelism to exploit). Follow the four-part contract in [`references/dispatch-contract.md`](references/dispatch-contract.md): the agent runs in its own session at the repo root with the QA tool scope from the cheatsheet (`Bash`, `Read`, `Write`, plus MCP tools QA needs). Its prompt opens with the literal phrase **"Run a full QA session"** so `qa-orchestrator`'s positive trigger fires immediately without ambiguity.
- This launches Mode A — Full Run: Phase 1 Gather Context → Phase 2 Select Agents → Phase 3 Spawn QA Agents → Phase 4 Collect Results → Phase 5 Bug Triage → Phase 6 Generate Report.
- Because every code-touching Phase 3 task already updated `.qa/test-plan.md` (Test-plan obligation), `qa-orchestrator`'s Phase 2 selector will see fresh `## UI Flows` and/or `## API Endpoints` matching exactly the surface area that just changed — no manual test-plan editing is needed between Phase 4 and Phase 5.
- The dispatch prompt **must explicitly request all available QA agents** so the run includes:
  - **`qa-happy-path`** — UI flow coverage via Playwright (when test plan has `## UI Flows`).
  - **`qa-chaos-monkey`** — adversarial / stress / boundary API testing (when test plan has `## API Endpoints`).
  - **All custom personalities** declared in `.qa/config.yml → personalities.custom`.
  - Do **not** narrow the agent set — only `qa-orchestrator`'s own gating (Playwright availability, test-plan section content) may exclude an agent. If a gate still excludes one despite the Phase 3 obligation, that means a code-touching Phase 3 task skipped its test-plan update — flag it as the troubleshooting case "Test-plan obligation skipped" and have the user re-run that slice or update the plan manually before QA.
- Pass scope as the argument:
  - **PR number** if `agent-pr-creator` succeeded in this run (use the PR it created — applies to both Mode 1 fan-outs that included `agent-pr-creator` **and** Mode 3 runs where Phase 4.5 delegated PR creation to it), or if a PR already exists on the current branch (`gh pr list --head $(git branch --show-current)`).
  - Otherwise pass a short scope blurb: original user goal + list of code-touching task summaries from Phase 4 so `qa-orchestrator` can scope its test plan.
- Inherit the parent session's interactive vs non-interactive mode — propagate `--non-interactive` if `$CI=true` or the flag was set on the parent.

**Announcement (in the same message that dispatches the QA agent):**

`Dispatching qa-orchestrator as an isolated agent (full workflow — happy path + chaos monkey + custom agents) to verify the run.`

**After QA completes:**

- Quote the qa-orchestrator verdict line (`Verdict: PASS / FAIL` plus the report path) **verbatim** to the user — do not paraphrase.
- If QA filed BLOCKER or HIGH issues, list their URLs underneath the verdict so the user can jump to them.
- Treat a QA FAIL as a follow-up signal, not a dev-orchestrator failure: the dev tasks already completed; QA simply found regressions to address next.

## Examples

### Positive Trigger

User: "Generate the test plan for payments, generate the test cases and create the PR"

Expected behavior: Identify **three** independent tasks mapped to **`test-plan-gen`** (payments test plan), **`test-case-gen`** ("generate … test cases"), and **`agent-pr-creator`** ("create the PR"). Run Phase 2 and show **`Detected 3 tasks:`** with those routes plus short descriptions, then **stop** until the user confirms (**yes** / remove / add / reorder). After confirmation, Phase 3 **dispatches three isolated agents in parallel** (one per task — each in its own session with a scoped tool list per [`references/dispatch-contract.md`](references/dispatch-contract.md)) and surfaces per-agent completion lines (`[wave 1] agent i of 3 — completed / — failed`) as each lands; Phase 4 posts the **`Orchestrator Results`** consolidation. Phase 5 fires because **`agent-pr-creator`** is code-touching: dispatch **`qa-orchestrator`** as a single isolated agent with the new PR number, requesting the **full QA workflow** (Mode A) with **all available agents — `qa-happy-path` + `qa-chaos-monkey` + any custom personalities** — then quote its verdict back to the user verbatim.

Case B — doc-only run, QA skipped:

User: "I need the bug report and the test plan for the auth module"

Expected behavior: Detect **two** tasks — **`bug-report-gen`** for the bug report scoped to auth, **`test-plan-gen`** for the auth test plan — then the same Phase 2 → Phase 3 → Phase 4 path with **`N=2`**. Phase 5 is **skipped** — both tasks are doc-only — and the user sees `QA verification skipped — no testable artifacts produced.`

Case C — mixed run, QA runs on the code-touching slice:

User: "Address the PR review comments and generate the matching test cases"

Expected behavior: Detect **two** tasks — **`pr-comments-address`** (code-touching) and **`test-case-gen`** (doc-only). After Phase 4, Phase 5 fires because at least one completed task touched code; pass the existing PR number (read from `gh pr list --head $(git branch --show-current)`) to **`qa-orchestrator`** so it scopes QA to the addressed comments.

Case D — soft-sequenced run (waves):

User: "Generate the test plan for the new checkout flow, then generate the test cases from it"

Expected behavior: Phase 1 detects **two** tasks but classifies them as **soft-sequenced** — `test-case-gen` benefits from reading `test-plan-gen`'s output (`.qa/test-plan.md`) but does not literally fail without it. Present **Layout B** in Phase 2: `Wave 1: test-plan-gen`, `Wave 2: test-case-gen`. User picks `staged`. Phase 3 runs in Mode 2: **dispatch wave 1's single isolated agent** (`test-plan-gen`), surface its `[wave 1] agent 1 of 1 — completed` line and the produced `.qa/test-plan.md` path, then **dispatch wave 2's isolated agent** (`test-case-gen`) whose prompt references the path so the test-case generator can consume it. Phase 4 consolidates results from both waves. Phase 5 is **skipped** — both tasks are doc-only.

Case E — worktree mode (integration branch + dependency-aware per-task worktrees): see [`references/worktree-mode.md`](references/worktree-mode.md) "End-to-end example (Case E)" for the full `/orchestrate --worktree generate the migration and the matching service refactor` walkthrough — the integration branch is provisioned off the resolved protected base, the two tasks fan out into two parallel per-task worktrees off the integration branch tip, each merges back into the integration branch sequentially, and Phase 4.5 hands the integration branch off to `agent-pr-creator` for the protected-base PR.

### Non-Trigger (negative triggers)

User: "create the PR"

Expected behavior: Exactly **one** actionable task routed to **`agent-pr-creator`**. **Do not** run multi-task orchestration (no **`Detected N tasks:`** plan, no parallel batch framing). Carry out **`agent-pr-creator`** norms **directly** in the foreground conversation.

Follow-up (**also** Non-Trigger):

User: "what does this file do?"

Expected behavior: Informational question — **not** actionable implementation work — so **exclude** **`dev-orchestrator`**. Answer from **`Read`/context** normally without skill routing or phased orchestration.

## Troubleshooting

### Agent cannot find mapped skill

- Error: Dispatched agent reports unknown skill / "skill not installed" while running a routed task.
- Cause: Marketplace drift, typo, Claude Code slash menu vs corvus installs, or a skill referenced in the routing table that is not packaged in this host.
- Solution: Retry that slice as a **free task** — dispatch a fresh isolated agent (same dispatch contract) with the concrete goal, files, constraints, and acceptance hints so it can fulfill the task without relying on skill discovery. Mention the unavailable skill id to the user; offer installing it or simplifying to one manual pass.
- Expected behavior: The task completes via the free-task fallback, the consolidated report flags it as `[free task]`, and the user is told which skill was missing and how to install it.

### Ambiguous single vs compound prompt

- Error: Prompt could be **one chained goal** ("do A then B as one workflow") versus **two separable deliveries**.
- Cause: Boundary words ("then", nested scope) obscure independence.
- Solution: Pause orchestration until resolved — ask **one** targeted question (e.g. "Separate deliverables?", "Must A finish before B?"). Prefer **merged single task** unless the user insists on splitting. Only reopen Phase 2 when **two-plus** mutually independent tasks survive.
- Expected behavior: No agents are dispatched until the user disambiguates; the run either continues as a single direct task or restarts Phase 2 with the corrected task list.

### Isolated-agent dispatch unavailable

- Error: The host cannot satisfy the four-part isolated-agent contract — typically because the Claude Code `Task` primitive's `run_in_background: true` is unsupported, the Cursor SDK is not loaded in the current session, or session-level policy forbids concurrent agent spawning.
- Cause: Older client, restrictive session, or sandboxed CI runner that disallows the dispatch primitive documented in [`references/dispatch-contract.md`](references/dispatch-contract.md).
- Solution: Announce the degradation verbatim — `Isolated-agent dispatch unavailable in this host; falling back to in-session sequential execution. Parallel waves will run serially and the four-part isolation contract is best-effort only.` Then dispatch each task synchronously, one at a time, even within a Layout A "single wave" — true parallelism is forfeited but correctness is preserved. Still emit the per-agent completion line format and the Phase 4 consolidation; Phase 4.5 and Phase 5 still run as documented.
- Expected behavior: All tasks still complete and the same Phase 4 report is produced; only the wall-clock time degrades. The user knows the orchestrator could not run agents in parallel and why.

### QA verification cannot run

- Error: Phase 5 hand-off to `qa-orchestrator` aborts (skill not installed, missing `.qa/config.yml`, missing `.qa/test-plan.md`, or `.env.qa` URLs absent).
- Cause: This repo has not been initialized for QA, or the `qa-orchestrator` skill is not packaged in the host marketplace.
- Solution: Do **not** retry the dev tasks — they already completed. Surface the qa-orchestrator setup error verbatim, point the user at `skills/qa/qa-orchestrator/SKILL.md` (template files in `references/`), and offer to skip QA for this run.
- Expected behavior: The Phase 4 report stays valid, the user is told exactly which QA prerequisite is missing, and dev-orchestrator exits cleanly without overwriting completed work.

### Misclassified dependency surfaces during execution

- Error: A task dispatched in parallel (Mode 1) or in an earlier wave (Mode 2) actually depends on output that doesn't exist yet — the agent reports a missing file, missing PR number, or empty input artifact.
- Cause: Phase 1 classified the task as Independent or Soft-sequenced when it was really **Hard-chained**, OR Phase 2's `parallel` collapse was used on a Layout B plan whose dependency was tighter than soft.
- Solution: Let the wave run to completion (per the dispatch contract — siblings are not auto-cancelled), mark the failing task as `failed` in Phase 4, and re-present the plan in Phase 2 with the dependency upgraded one level (Independent → Soft-sequenced, or two soft-sequenced tasks merged into a single Hard-chained task). Ask the user to confirm `staged` (or merged) before re-launching.
- Expected behavior: After the re-classification, the same prompt completes successfully because the dependency now executes in the correct order or as a unified task. Future runs of similar prompts should land in the corrected bucket from the start.

### Test-plan obligation skipped

- Error: A code-touching Phase 3 task completed but did not append or update `.qa/test-plan.md` for the surface area it changed; `qa-orchestrator`'s Phase 2 selector then excludes `qa-happy-path` or `qa-chaos-monkey` because the relevant `## UI Flows` / `## API Endpoints` section is empty or missing the new entry.
- Cause: The dispatch prompt for that task either omitted the Test-plan obligation clause, or the agent finished its primary work and stopped before the post-task update.
- Solution: Identify the offending task from the Phase 4 report (compare the diff to `.qa/test-plan.md`). Either (a) re-dispatch that single isolated agent with the obligation clause as the only remaining work, or (b) update `.qa/test-plan.md` manually with the changed UI flow / API endpoint, then re-run Phase 5. Do **not** mark the run "complete" until coverage is registered.
- Expected behavior: After the patch, `qa-orchestrator`'s Phase 2 picks up `qa-happy-path` and/or `qa-chaos-monkey` matching the new surface area, and the full QA workflow runs as designed.

### Worktree path collision

- Error: `scripts/setup-worktree.sh` aborts in Phase 3 Mode 3 with `path already exists: <path>` while provisioning one of the per-task worktrees.
- Cause: A previous worktree-mode run left a stale sibling worktree, or the auto-derived path collides with an unrelated directory next to the repo. With parallel per-task worktrees this is more visible — two same-named slugs (or a leftover from a crashed run) collide on the same sibling path.
- Solution: Run `git worktree list` to confirm whether the offending path is a tracked worktree. If yes, remove it with `git worktree remove "<path>"` (or `--force` if dirty) and retry the original prompt. If it is an unrelated directory, instruct the user to pass an explicit `--branch <unique name>` per task on the retry so the derived sibling path shifts to a fresh slug. Do **not** dispatch the failing wave's agents until the path is clear — the worktree flag stays armed for the retry. Sibling tasks in the same wave that already provisioned successfully keep their worktrees; only the colliding task is re-provisioned.
- Expected behavior: The retry creates a fresh per-task worktree on a unique sibling path, the wave's parallel agent dispatches fan out, and Phase 3 Mode 3 continues normally through Phase 4.5.

### Integration branch already exists

- Error: `scripts/setup-integration-branch.sh` aborts in Phase 3 Mode 3 with `integration branch already exists: <name>` before any per-task worktree is provisioned.
- Cause: A prior run left the integration branch behind (typically a `--keep-branch` finish or an aborted run), or the user explicitly named an integration branch that is already checked out somewhere.
- Solution: Inspect with `git branch --list <name>` and `git worktree list`. If the branch is leftover from an aborted run and has no unmerged commits worth keeping, delete it (`git branch -D <name>`) and retry. If it carries useful work and the user wants to extend that work, retry the orchestrator with `--integration-branch <name> --reuse-integration` so `setup-integration-branch.sh` adopts the existing branch instead of refusing. Do **not** silently overwrite — losing committed work on a named integration branch is irrecoverable from inside the orchestrator.
- Expected behavior: After the retry, the integration branch is either freshly created (delete path) or adopted at its current tip (`--reuse-integration` path); per-task worktrees branch off it normally.

### Worktree validation fails before PR handoff

- Error: `scripts/validate-worktree.sh` exits non-zero in Phase 4.5 against the integration branch; the PR handoff to `agent-pr-creator` is skipped and the integration-branch footer is rewritten to `preserved on failure`.
- Cause: One of the per-task merges introduced a cross-task regression — independent task A's diff compiles fine, independent task B's diff compiles fine, but the **combined** state on the integration branch breaks lint, typecheck, or tests. Less commonly, the integration worktree is missing setup the checks require (deps not installed).
- Solution: `cd` into the integration-branch worktree (the one `setup-integration-branch.sh` provisioned or the primary worktree currently checked out on the integration branch) and run the failing command manually. For a real cross-task regression, fix it inline (either by hand or via a fresh `/orchestrate --worktree --no-merge --integration-branch <same-name> --reuse-integration` pass that dispatches an isolated agent to address it), then resume Phase 4.5 by running the resume command the failure report emitted. For a setup gap, install deps in the worktree (`npm ci`, etc.) and rerun the resume command. Use `--no-validate` only when the gap is structural and unrelated to the integrated diff.
- Expected behavior: After the fix, validation passes, the PR handoff to `agent-pr-creator` runs cleanly, the integration-branch footer reaches `PR opened`, and Phase 5 (QA) fires with that PR number as the scope.

### Per-task merge conflict on the integration branch

- Error: One of the parallel task worktrees in a Mode 3 wave reports `MERGE_STATUS=conflict` (exit code 2) when `merge-worktree.sh --no-push` tries to fold its branch into the integration branch.
- Cause: Two tasks in the same wave edited overlapping lines, OR the wave ran on a stale integration-branch snapshot (the worktree was branched off the tip before a sibling wave landed). The integration branch ends up in an in-progress merge state with conflicted files printed on stdout.
- Solution: Stop the wave immediately — do **not** keep dispatching subsequent task merges on top of an in-progress merge. Inspect the conflicted files in the integration-branch worktree (`git -C <integration-worktree> status`). Resolve them by hand, commit (`git add -A && git commit --no-edit`), and continue the wave by re-running the remaining `merge-worktree.sh` invocations. If both tasks rewrote the same logic in incompatible ways and the resolution is ambiguous, surface the conflicted file list to the user and pause until they pick the intended outcome — never guess. Tasks that conflict reliably should be re-classified as **soft-sequenced** (different waves) on the next run.
- Expected behavior: After resolution, the integration branch carries both tasks' intended diffs, the remaining wave merges fold in cleanly, and Phase 4.5 hands the integration branch off to `agent-pr-creator` as usual.

### Integration-branch PR handoff failed

- Error: Phase 4.5 validation passed but the isolated `agent-pr-creator` agent returned non-zero (push refused, branch protection misconfigured, `gh` not authenticated, etc.). The integration-branch footer ends at `validated, awaiting PR` and Phase 5 is skipped because no PR number exists yet.
- Cause: Auth / network / permission issue local to the user's environment, not a defect in the integration branch itself. The work is already validated and ready to ship.
- Solution: Inspect the `agent-pr-creator` error verbatim (it is preserved in the Phase 4 report). Fix the root cause — typically `gh auth login`, push permission, or branch-protection rules. Then re-dispatch **only** `agent-pr-creator` against the integration branch (do not re-run the orchestrator — the per-task worktrees are already merged in). Once the PR is open, dispatch `qa-orchestrator` manually with that PR number using the same prompt shape Phase 5 would have emitted (see "QA after a manual PR from a `--no-merge` run" for the exact invocation template — it applies here too with the PR number replacing the scope blurb).
- Expected behavior: After the manual re-run, the PR is open, QA runs against it, and the run ends in the same state Phase 4.5 would have produced if the handoff had succeeded on the first try.

### QA after a manual PR from a `--no-merge` run

- Error: The user opted into `--no-merge`, the run ended at the Phase 4.5 closing block with the integration branch `preserved (--no-merge)`, the user later opened the PR themselves (either by pasting the emitted resume command, by running `agent-pr-creator` directly, or by clicking through the platform UI), and now wants `qa-orchestrator` to verify the diff — but the original dev-orchestrator run is long-since closed and never auto-fired Phase 5.
- Cause: `--no-merge` is an explicit opt-out from both Phase 4.5's PR handoff and Phase 5, so the orchestrator stops at the closing block with the integration branch preserved and never hands off to QA. After the manual PR there is no live orchestrator session to resume from — Phase 5 must be dispatched by hand against the open PR.
- Solution: Dispatch `qa-orchestrator` directly as an isolated agent with the same scope shape Phase 5 would have used (one agent, awaited synchronously, scoped tool list from the cheatsheet in [`references/dispatch-contract.md`](references/dispatch-contract.md)). The prompt opens with the literal phrase `Run a full QA session` (so `qa-orchestrator`'s positive trigger fires unambiguously) and explicitly requests all available agents — `qa-happy-path`, `qa-chaos-monkey`, and every custom personality declared in `.qa/config.yml → personalities.custom`. Pass scope in this priority order:

  1. **PR number, if a PR exists**. In the `--no-merge` + manual-PR flow this is almost always the case — `agent-pr-creator` (or the user via the platform) opened a PR from the integration branch into the protected base. Look it up with `gh pr list --head "<INTEGRATION_BRANCH>" --state all --json number,url`; `--head` filters by source branch, which for this flow is the integration branch.
  2. **Scope blurb (fallback)**: pass `goal: <original user prompt> | landed on integration branch: <comma-separated list of code-touching Phase 4 task summaries>`. Both halves are already in the user's preserved Phase 4 report, so no fresh inspection is needed.

  Inherit `--non-interactive` if `$CI=true`. The `.qa/test-plan.md` entries that the code-touching tasks registered (via the Test-plan obligation clause) during their Phase 3 Mode 3 runs are still on the integration branch, so `qa-orchestrator`'s Phase 2 selector will pick up the right agents without manual editing.
- Expected behavior: `qa-orchestrator` runs the full workflow (Mode A — happy path + chaos monkey + custom agents) against the PR exactly as it would have in the auto-handoff path, scoped to the same surface area registered during the original run. The verdict line plus any BLOCKER/HIGH issue URLs are returned to the user; nothing about the manual PR changes the QA contract.