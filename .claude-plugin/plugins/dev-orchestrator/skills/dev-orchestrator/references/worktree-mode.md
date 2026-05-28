# Worktree Mode — Deep Dive

Authoritative reference for `dev-orchestrator`'s opt-in **worktree execution mode**. Load this when SKILL.md routes the run through worktree mode (`--worktree` flag captured or explicit worktree language detected). It documents every detail SKILL.md only summarizes: the full flag table, the protected-base resolution rules, the integration-branch contract, the Layout C confirmation block, Mode 3's per-task worktree dispatch (parallel for independent, waves for soft-sequenced) plus the SHA-verification step, the Phase 4 worktree footer, the Phase 4.5 PR-handoff pipeline (including the `--no-merge` closing block), and the Case E end-to-end example.

The worktree-specific **troubleshooting** entries stay inline in `SKILL.md` so the standard troubleshooting search still surfaces them. For tutorial-style end-to-end walkthroughs of worktree mode in action (single task, multi-subtask, `--no-merge` opt-out) see [`workflow.md`](workflow.md) Scenarios 5, 6, and 7.

## When this mode is active

Worktree mode is detected in Phase 1 **before** classification:

- **Explicit flag**: prompt contains `--worktree` (alone or after `/orchestrate`).
- **Explicit language**: phrases like `in a worktree`, `isolated branch`, `auto-merge to main`, `spin up a worktree`, `use a worktree`.

When neither is present, the orchestrator skips this reference entirely. When active, the flag persists for the whole run and:

- **Provisions a single integration branch** off the resolved protected base. Every per-task worktree created in Phase 3 is forked off that integration branch.
- **Respects dependency classification** for dispatch:
  - Independent (Layout A) → all tasks fan out into per-task worktrees and run in **parallel** via concurrent isolated-agent dispatches (see [`dispatch-contract.md`](dispatch-contract.md)).
  - Soft-sequenced (Layout B) → each wave runs the same parallel pattern internally; waves run **sequentially** so wave N+1 sees wave N's merges on the integration branch.
  - Hard-chained → still merged into a single combined task during Phase 1; that combined task runs in one worktree.
- **Still applies for a single surviving task** — provision the integration branch and a single per-task worktree off it.

## Protected base resolution

Every worktree-mode run resolves the **protected base** before anything else. The orchestrator passes the resolution to `setup-integration-branch.sh` (and the same rules apply in `setup-worktree.sh` when `--base` is omitted), which:

1. Honors `--base <branch>` when the user supplied it.
2. Otherwise prefers **`develop`**, then **`dev`** — whichever exists first (locally or as `origin/develop` / `origin/dev` after a fetch). These are the integration branches off which feature work is expected to branch.
3. If **neither** `develop` nor `dev` exists, resolves to **`main`** or **`master`**: if only one exists, use it; if **both** exist, pick the branch whose **tip commit has the newer committer timestamp** (tie → `main`).
4. Runs `git fetch origin` during resolution so remote tips are visible before choosing `main` vs `master`. When a corresponding `origin/<base>` exists, the integration branch is created off `origin/<base>` (not a stale local-only tip), so the run starts from the latest pushed state.

If none of `develop`, `dev`, `main`, or `master` exist locally **and** on `origin`, **and** no `--base` was supplied, the script exits non-zero and the orchestrator stops before any worktree is provisioned.

## Integration branch contract

Every worktree-mode run creates exactly one integration branch. It is the **only** merge target inside the orchestrator — per-task worktrees merge into it, not into the protected base. At the end of the run, Phase 4.5 hands the integration branch off to `agent-pr-creator`, which opens a PR from `<integration-branch>` → `<protected-base>` so the human reviewer (and CI) can verify the diff before it lands.

Naming priority:

1. **`--integration-branch <name>`** explicit override — takes precedence over everything.
2. **Ticket id from Phase 0** — when Phase 0 resolved a ticket, the default name is `ticket/<TICKET-ID>` (e.g. `ticket/ABC-42`). A `--prefix <p>` or `--slug <s>` flag captured in Phase 1 customizes the name (`<prefix>/<ticket-id>-<slug>`).
3. **Auto-derived from the prompt** — `feature/<task-slug>-<unix-seconds>` when neither override nor ticket is present.

Lifecycle:

- Created at start of Phase 3 by `setup-integration-branch.sh` as a floating ref pointing at the resolved protected base tip (no checkout — the primary worktree keeps the user's original HEAD).
- Each per-task worktree branches off the integration branch tip at the moment its wave dispatches.
- After each per-task agent returns, the task's worktree merges back into the integration branch via `merge-worktree.sh --no-push` (the integration branch is **never** pushed to origin during Phase 3 — that happens once in Phase 4.5). The merge runs inside a **dedicated integration worktree** that `merge-worktree.sh` provisions on first use — the user's primary worktree and HEAD are never touched. The script emits `INTEGRATION_WORKTREE=<path>` on stdout; capture it (it is stable across the run) and reuse it as the validate/push target in Phase 4.5.
- Phase 4.5 validates the integration branch **in the integration worktree** (`$INTEGRATION_WORKTREE`), then `agent-pr-creator` pushes it and opens the PR.
- On clean PR handoff, the integration branch survives on the remote (until the PR merges and the platform's branch-delete-on-merge policy runs). Locally, the orchestrator leaves the branch ref in place so the user can pull more commits onto it if needed.

## Worktree options captured in Phase 1

Scan the prompt once for the options below and record them into a worktree-options structure that persists for the rest of the run. Strip captured flags from the task text **before** classification so they do not leak into subtask descriptions.

When Phase 0 also resolved a ticket (see [`ticket-resolution.md`](ticket-resolution.md)), the ticket id becomes the default integration-branch name as documented above.

| Option | Default | Effect |
| --- | --- | --- |
| `--integration-branch <name>` | derived from ticket or auto | Explicit integration branch name passed to `setup-integration-branch.sh --name <name>`. |
| `--reuse-integration` | off (existing branch is a hard error) | Adopt an existing integration branch instead of failing. Useful for resuming a run that crashed mid-flight. |
| `--base <branch>` | auto (`develop`/`dev` preferred; else newer `main`/`master`) | Protected base passed to `setup-integration-branch.sh --base <branch>` and used as the merge target when `agent-pr-creator` opens the PR. |
| `--no-validate` | validation runs | Skips Phase 4.5 step 1 (the `validate-worktree.sh` gate). |
| `--no-merge` | PR handoff runs | Stops after Phase 4 — Phase 4.5 runs only its `--no-merge` closing block. The integration branch and all per-task worktrees stay on disk for manual follow-up. |
| `--keep-branch` | task branches deleted on clean merge | Passes `--keep-branch` to each `merge-worktree.sh` invocation so the **per-task** feature branches survive their merges into the integration branch. Does not affect the integration branch itself (which always survives). |

Echo the captured record back to the user as a single line at the end of the Phase 2 plan, e.g. `Worktree options: integration=ticket/ABC-42, base=develop (auto: develop/dev preferred; else newer of main/master), validate=on, merge=on, keep-branch=off`. This makes the user's intent visible before they confirm.

## Phase 2: Layout C (worktree mode confirmation)

Used regardless of dependency classification when the worktree flag is on. Layout C makes the per-wave fan-out visible so the user can see which tasks will run in parallel and which waves merge before the next provisions.

**Layout C — single wave (independent tasks):**

```text
Detected N tasks (worktree mode — single wave, parallel per-task worktrees):
  Integration branch: <integration-branch>  (off <base>, auto: develop/dev preferred; else newer of main/master)
  Wave 1 (parallel, N worktrees off <integration-branch>):
    1. [skill or "free task"] → [short task description]
    2. ...

After all tasks merge cleanly into <integration-branch>, agent-pr-creator will
open a PR from <integration-branch> into <base>.
Worktree options: integration=<name>, base=<base>, validate=on, merge=on, keep-branch=off
Proceed? (yes / remove N / add something / reorder / cancel-worktree)
```

**Layout C — multiple waves (soft-sequenced tasks):**

```text
Detected N tasks across W waves (worktree mode — waves sequential, tasks within a wave parallel):
  Integration branch: <integration-branch>  (off <base>, auto: develop/dev preferred; else newer of main/master)
  Wave 1 (parallel, M1 worktrees off <integration-branch>):
    1. [skill or "free task"] → [short task description]
    2. ...
  Wave 2 (parallel, M2 worktrees off <integration-branch> at wave-1-merged tip):
    3. ...

After all waves merge cleanly into <integration-branch>, agent-pr-creator will
open a PR from <integration-branch> into <base>.
Worktree options: integration=<name>, base=<base>, validate=on, merge=on, keep-branch=off
Proceed staged? (staged / remove N / add something / reorder / cancel-worktree)
```

- `cancel-worktree` drops worktree mode and re-presents the plan in Layout A or B based on the original classification (then resumes the normal confirmation rules).
- `reorder` is meaningful: within a wave it is cosmetic (the parallel dispatch is order-insensitive), but moving a task between waves changes which wave's tip its worktree branches from.
- `remove N` rebuilds the numbered list and collapses empty waves.
- All other options (`yes`, `add something`) behave the same as in Layout A / B.
- Layout C also accepts `staged` and `parallel` semantics from Layout B for multi-wave plans — `parallel` collapses all waves into a single wave with a warning that soft-sequencing benefits are forfeited.

## Phase 3: Mode 3 (per-task worktrees off an integration branch)

1. Run `bash skills/assistant/dev-orchestrator/scripts/setup-integration-branch.sh` with the appropriate args (`--ticket <id>` when Phase 0 resolved one, `--name <override>` when `--integration-branch` was captured, `--task "<original prompt summary>"` otherwise). Append `--base <branch>` only when the user passed it explicitly; append `--reuse` only when `--reuse-integration` was captured. Capture two machine-readable lines from stdout:

   ```text
   INTEGRATION_BRANCH=<branch>
   BASE_BRANCH=<branch>
   ```

   On non-zero exit, surface stderr verbatim and stop — do not dispatch any agent.

2. **Snapshot the integration branch tip** before launching wave 1: `INTEGRATION_SHA_PREV=$(git rev-parse "$INTEGRATION_BRANCH")`. After each task merges into the integration branch, update this so subsequent verifications compare against the latest tip, not the original base.

3. For each wave (single wave for Layout A, multiple sequential waves for Layout B), follow the dispatch steps below. Wave N+1 only begins after every task in wave N has finished merging (or has been recorded as failed) and `INTEGRATION_SHA_PREV` has been refreshed to the new integration-branch tip.

4. **Wave step 1 — Provision per-task worktrees.** For every task in the wave, run:

   ```bash
   bash skills/assistant/dev-orchestrator/scripts/setup-worktree.sh \
     --task "<task body>" \
     --base "$INTEGRATION_BRANCH"
   ```

   Capture `WORKTREE_PATH_<i>` and `WORKTREE_BRANCH_<i>` from each invocation. If `setup-worktree.sh` fails for any task, stop that task — but if other tasks in the wave already provisioned successfully, their worktrees remain and run normally; only the failing task is skipped (and recorded as a Phase 4 failure).

5. **Wave step 2 — Dispatch one isolated agent per task.** Dispatch **all N agents** in the wave back-to-back (per [`dispatch-contract.md`](dispatch-contract.md) — host-detected primitive, scoped tool list, awaited individually). Each agent's prompt pins its cwd to its own `WORKTREE_PATH_i` (the four-part contract requires it), so the wave's agents cannot collide on a shared working directory. The prompt opens with `Work inside <WORKTREE_PATH_i>. cd into it before any file or shell operation.`; the body is the skill invocation (`Use the Skill tool with skill '<name>' and args '<args>'`) or a free-task description, plus the Test-plan obligation clause for code-touching tasks (same verbatim contract documented in SKILL.md Phase 3); and the prompt closes with `When done, run "git add -A && git commit -m '<imperative subject>'" inside the worktree. Do not push, do not switch branches, do not merge. Do not use --amend or --allow-empty.` Poll each agent individually and emit its `[wave K] agent i of N — completed / — failed: <reason>` line as it lands.

6. **Wave step 3 — Verify each commit.** Wait for **every** agent in the wave to return (success or failure). A failure does not auto-cancel siblings — let the wave run to completion. For each successful return, verify the commit landed with SHA comparison plus diff inspection — never a log count:

   ```bash
   BRANCH_SHA_NEW=$(git -C "<WORKTREE_PATH_i>" rev-parse "<WORKTREE_BRANCH_i>")
   BRANCH_SHA_BASE=$(git -C "<WORKTREE_PATH_i>" rev-parse "$INTEGRATION_BRANCH")
   if [ "$BRANCH_SHA_NEW" = "$BRANCH_SHA_BASE" ]; then
     FAIL "task i produced no commit"
   fi
   if [ -z "$(git -C "<WORKTREE_PATH_i>" diff --stat "$BRANCH_SHA_BASE" "$BRANCH_SHA_NEW")" ]; then
     FAIL "task i committed but produced no diff"
   fi
   ```

   This pair catches three failure modes a log-count check missed: `git commit --amend` (SHA changes but the new commit replaces the old one), `git commit --allow-empty` (new SHA, identical tree), and an agent that ran without changing files. On either failure, mark that task as **failed** — the rest of the wave is unaffected, but the task's worktree is **not** merged into the integration branch.

7. **Wave step 4 — Merge into the integration branch.** Merge each successful task's worktree into the integration branch **sequentially** (git merges serialize):

   ```bash
   bash skills/assistant/dev-orchestrator/scripts/merge-worktree.sh \
     "<WORKTREE_PATH_i>" "<WORKTREE_BRANCH_i>" "$INTEGRATION_BRANCH" \
     --no-push \
     --summary "<one-line task summary>"
   ```

   Append `--keep-branch` to each call **only** when `--keep-branch` was captured in Phase 1 (so per-task branches survive their merges). `--no-push` is always passed during Phase 3 merges — the integration branch is not pushed to origin until Phase 4.5.

   If a merge returns exit code `2` (conflict), stop the wave and follow the "Per-task merge conflict on the integration branch" troubleshooting entry in SKILL.md. Do not continue dispatching merges on top of an in-progress merge.

8. After the last wave finishes (success or first wave-blocking failure) proceed to Phase 4, then Phase 4.5 (PR handoff), then Phase 5 (QA).

**Phase 3 announcement (Mode 3 only)** — emit exactly once per wave, in the same message that issues the wave's parallel agent dispatches:

`Dispatching wave K of W: N isolated agents in parallel, each pinned to its own worktree off <integration-branch>. I'll surface each agent's completion as it lands; wave K+1 starts after the slowest wave-K agent returns and its worktree merges in.`

For a single-wave plan (Layout A in worktree mode), `K = W = 1`.

## Phase 4: worktree footer and retry menu

Append these three lines to the Phase 4 consolidated report, immediately above the `<successes>/<total>` line, whenever Mode 3 was used:

```text
  Integration:  <integration-branch>  [pending PR | PR opened | validated, awaiting PR | preserved (--no-merge) | preserved on failure]
  Worktrees:    <count merged & cleaned> merged & cleaned, <count kept> kept, <count preserved> preserved
  Base:         <protected-base>
```

The integration-branch footer terminal states are mutually exclusive:

| Status | Trigger |
| --- | --- |
| `pending PR` | Transient only — visible if the orchestrator is currently between Phase 4 and Phase 4.5. Never a final state. |
| `PR opened` | Phase 4.5 ran cleanly, `agent-pr-creator` opened the integration → base PR. |
| `validated, awaiting PR` | Phase 4.5 validation passed but the PR handoff to `agent-pr-creator` returned non-zero — see SKILL.md troubleshooting "Integration-branch PR handoff failed". |
| `preserved (--no-merge)` | `--no-merge` was captured in Phase 1; Phase 4.5 deliberately did not validate or open a PR. |
| `preserved on failure` | A Phase 3 task failed, a per-task merge conflicted, or validation failed. |

When the run ends at `preserved on failure`, replace the worktree-mode retry prompt with this menu so the user has an explicit resume path:

```text
Worktree run did not complete:
  - retry-failed   → re-run only the failed task(s) on <integration-branch>, then auto-resume Phase 4.5
  - resume-pr      → skip retries and run Phase 4.5 now (validate + agent-pr-creator handoff)
  - keep           → leave the integration branch and any preserved worktrees as-is; print the resume command and exit
  - discard        → remove all worktrees and delete the integration branch + per-task branches (destructive)
```

For both `keep` (from this menu) and the `--no-merge` closing block, emit the **exact** resume command verbatim so the user can paste it later. The command validates the integration branch (skipped when `--no-validate` was captured) and then re-invokes `dev-orchestrator` to finish the PR handoff via `agent-pr-creator`:

```bash
bash skills/assistant/dev-orchestrator/scripts/validate-worktree.sh "<integration-worktree-path>" \
  && /orchestrate --resume-pr --integration-branch "<INTEGRATION_BRANCH>" --base "<BASE_BRANCH>"
```

Strip `validate-worktree.sh` from the chain when `--no-validate` was captured in Phase 1. The `--resume-pr` flag tells the orchestrator to skip Phase 1–4 entirely and go straight to Phase 4.5's PR handoff against the named integration branch. This guarantees the user can return to Phase 4.5 days later without rereading the SKILL — the command is in their consolidated report.

The retry menu fires **only** on failure; the `--no-merge` opt-out follows its dedicated closing block below instead.

## Phase 4.5: integration-branch PR handoff

Skip entirely when Mode 1 or Mode 2 was used. When Mode 3 was used **and** Phase 1 captured `--no-merge`, run the dedicated closing block below instead of steps 1–3. Otherwise run steps 1–3 only when Phase 4 shows `<total>/<total>` tasks completed; if any task failed, defer to the worktree retry menu instead.

This phase reads the worktree-options record from Phase 1 to decide which steps run:

| Captured option | Phase 4.5 behavior |
| --- | --- |
| `--no-validate` | Skip step 1 entirely; jump straight to step 2. |
| `--no-merge` | Phase 4.5 runs only the `--no-merge` closing block. |
| `--keep-branch` | Does **not** affect Phase 4.5 (it only changed per-task merges back in Phase 3). The integration branch always survives the PR handoff. |

### Step 1: Validate the integration branch

When `--no-validate` is **not** in the captured options, run validation against the integration branch's worktree. `merge-worktree.sh` checked the integration branch out in a **dedicated integration worktree** (not the primary worktree) and emitted its path as `INTEGRATION_WORKTREE=<path>` — validate against that captured path:

```bash
bash skills/assistant/dev-orchestrator/scripts/validate-worktree.sh "$INTEGRATION_WORKTREE"
```

If no merges ran (e.g. a single-task run where the merge was skipped), fall back to provisioning the integration worktree with `git worktree add "<repo>-integration-<base-leaf>" "$INTEGRATION_BRANCH"` and validate there.

The script auto-detects per-ecosystem checks (JS/TS lint + typecheck + tests; Python `ruff` + `mypy` + `pytest`; Ruby `rubocop` + `rspec`). Absent checks count as PASS. On any failure: surface the failing command and the tail of its output, rewrite the integration footer to `preserved on failure`, emit the resume command (see Phase 4 retry menu), and skip steps 2–3.

### Step 2: Push the integration branch

```bash
git -C "$INTEGRATION_WORKTREE" push -u origin "<INTEGRATION_BRANCH>"
```

Push by integration-worktree path (the integration branch is checked out there, not in the primary worktree). This is the first (and only) time the integration branch reaches the remote during the orchestrator's lifetime. On push failure, rewrite the footer to `validated, awaiting PR` and surface the failure verbatim — see "Integration-branch PR handoff failed" in SKILL.md troubleshooting.

### Step 3: Dispatch agent-pr-creator as an isolated agent

Dispatch **one isolated agent** carrying the `agent-pr-creator` skill, awaited synchronously (only one agent in this wave). Follow the four-part contract in [`dispatch-contract.md`](dispatch-contract.md): the agent runs in its own session at `$INTEGRATION_WORKTREE` (where the integration branch is checked out — **not** the primary worktree) with the PR-creation tool scope from the cheatsheet (`Bash` for `git` + `gh`, `Read`, MCP issue-tracker tools when ticket linking is needed — explicitly **no** `Edit` / `Write` / `StrReplace`, so it cannot modify the integration branch). Use this prompt:

> Use the `agent-pr-creator` skill to open a pull request.
>
> - **Source branch**: `<INTEGRATION_BRANCH>`
> - **Target branch**: `<BASE_BRANCH>`
> - **Context**: this branch contains `<count>` merged commit(s) from `<count>` per-task worktrees, integrated by dev-orchestrator. The original user prompt was: `<original prompt>`. Code-touching task summaries: `<comma-separated Phase 4 task summaries that touched code>`.
> - **Ticket reference (when Phase 0 resolved one)**: `<ticket URL>` — include the ticket reference in the PR body so the tracker's GitHub integration auto-links the PR to the ticket.
> - Do not modify the integration branch; only open the PR.

When the agent returns the new PR number / URL, rewrite the integration footer to `PR opened` and pass the PR number into Phase 5 as the QA scope. Surface the agent's exit line in the standard format (`[phase 4.5] agent 1 of 1 — completed Summary: PR #<n> opened` or `— failed Reason: <error>`). On non-zero return, rewrite the footer to `validated, awaiting PR` and surface the error (see the troubleshooting entry).

### no-merge closing block (replaces steps 1 to 3)

Applies when `--no-merge` was captured in Phase 1 and tasks succeeded — single-task or multi-task alike. Tasks completed; the user explicitly opted out of the PR handoff. Do **not** show the failure retry menu — nothing failed.

1. Rewrite the integration footer to `preserved (--no-merge)` so the closing status is unambiguous.
2. Emit the same resume command the `keep` retry option emits (built dynamically — strip `validate-worktree.sh` when `--no-validate` was captured) prefixed with a one-line opt-out confirmation, e.g. `Integration branch preserved per --no-merge. Run this when ready to open the PR:`.
3. Skip Phase 5 — no PR exists yet to verify. QA can be invoked manually after the user opens the PR themselves (see the "QA after a manual PR from a `--no-merge` run" troubleshooting entry in SKILL.md for the exact invocation).

## Phase 5 interaction (worktree mode)

When Mode 3 was used and Phase 4.5 completed cleanly, `agent-pr-creator` already opened the integration → base PR. Pass that PR number into `qa-orchestrator` as the scope so QA runs against the same diff the human reviewer will see.

**Skip Phase 5 entirely** when the integration footer ended at any non-`PR opened` terminal state — there is no PR yet to verify in `preserved (--no-merge)`, `preserved on failure`, or `validated, awaiting PR`.

## End-to-end example (Case E)

**User prompt:**

> `/orchestrate --worktree generate the migration and the matching service refactor`

**Expected behavior:**

Phase 1 detects the `--worktree` opt-in **before** classification and sets the worktree flag, captures `integration=auto, base=resolved, validate=on, merge=on, keep-branch=off`. Two tasks survive (`free task` for the migration + `free task` for the service refactor — both code-touching); classification routes them as **independent** (the migration and the service refactor touch separate files), so the run is a single-wave Layout C.

Phase 2 presents Layout C — single wave, two parallel worktrees. User confirms with `yes`.

Phase 3 Mode 3:

1. Runs `setup-integration-branch.sh --task "generate the migration and the matching service refactor"`. The script prefers `develop`, then `dev`; `develop` exists in this example, so it resolves `develop`, fetches origin, creates `feature/generate-the-migration-and-the-matching-service-refactor-<unix>` off `origin/develop`. Captures `INTEGRATION_BRANCH` and `BASE_BRANCH=develop`.
2. Provisions two per-task worktrees in parallel via `setup-worktree.sh --base "<INTEGRATION_BRANCH>"` — one for the migration, one for the service refactor. Captures `WORKTREE_PATH_1/_BRANCH_1` and `WORKTREE_PATH_2/_BRANCH_2`.
3. Announces `Dispatching wave 1 of 1: 2 isolated agents in parallel, each pinned to its own worktree off <INTEGRATION_BRANCH>. I'll surface each agent's completion as it lands; wave K+1 starts after the slowest wave-K agent returns and its worktree merges in.` and dispatches both agents (per the dispatch contract — own sessions, scoped tools, awaited individually).
4. As each agent returns, the orchestrator surfaces `[wave 1] agent 1 of 2 — completed Summary: ...` / `[wave 1] agent 2 of 2 — completed Summary: ...` in real time. SHA + diff verification confirms both commits landed.
5. Merges worktree 1 into the integration branch via `merge-worktree.sh --no-push`, then worktree 2. Both merges fold cleanly because the files don't overlap.

Phase 4 consolidates with the integration footer at `pending PR`, two worktrees `merged & cleaned`.

Phase 4.5:

1. `validate-worktree.sh` runs against `$INTEGRATION_WORKTREE` (the dedicated integration worktree where the merges landed; the primary worktree keeps the user's original HEAD) — passes.
2. `git push -u origin <INTEGRATION_BRANCH>` succeeds.
3. `agent-pr-creator` dispatched as an isolated agent (scoped to `Bash` + `Read` + MCP, no edit tools), opens PR #842 from `<INTEGRATION_BRANCH>` → `develop`. Footer rewritten to `PR opened`.

Phase 5 dispatches `qa-orchestrator` as a single isolated agent with `--pr 842`, requesting the full QA workflow (Mode A — happy path + chaos monkey + custom agents).

## Script invocation cheatsheet

| Script | Required positional args | Optional flags |
| --- | --- | --- |
| `setup-integration-branch.sh` | One of `--name <branch>`, `--ticket <id>`, `--task "<text>"` | `--prefix <p>`, `--slug <s>`, `--base <branch>`, `--reuse` |
| `setup-worktree.sh` | `--task "<text>"` (or `--branch <name>`) | `--branch <name>`, `--base <branch>` |
| `validate-worktree.sh` | `<worktree_path>` | none |
| `merge-worktree.sh` | `<worktree_path> <feature_branch> <base_branch>` | `--keep-branch`, `--no-push`, `--summary "<text>"` |

All four live under `skills/assistant/dev-orchestrator/scripts/` and run on `bash` (works under git-bash on Windows and any POSIX shell on Linux/macOS).

## See also

- [`../SKILL.md`](../SKILL.md) — the authoritative phase contract; this file is its worktree-mode appendix.
- [`dispatch-contract.md`](dispatch-contract.md) — the four-part isolated-agent contract used by every Mode 3 agent dispatch (per-task agents in Phase 3, the PR-handoff agent in Phase 4.5 step 3).
- [`ticket-resolution.md`](ticket-resolution.md) — Phase 0 ticket parsing and the ticket-id → integration-branch naming integration.
- [`workflow.md`](workflow.md) — end-to-end scenarios that show worktree mode in context (scenarios 5, 6, 6b, 7).
