# Worktree Mode — Deep Dive

Authoritative reference for `dev-orchestrator`'s opt-in **worktree execution mode**. Load this when SKILL.md routes the run through worktree mode (`--worktree` flag captured or explicit worktree language detected). It documents every detail SKILL.md only summarizes: the full flag table, the Layout C confirmation block, Mode 3's SHA verification sequence, the Phase 4 worktree footer, the Phase 4.5 merge pipeline (including the `--no-merge` closing block), and the Case E end-to-end example.

The five worktree-specific **troubleshooting** entries stay inline in `SKILL.md` so the standard troubleshooting search still surfaces them. For tutorial-style end-to-end walkthroughs of worktree mode in action (single task, multi-subtask, `--no-merge` opt-out) see [`workflow.md`](workflow.md) Scenarios 5, 6, and 7.

## When this mode is active

Worktree mode is detected in Phase 1 **before** classification:

- **Explicit flag**: prompt contains `--worktree` (alone or after `/orchestrate`).
- **Explicit language**: phrases like `in a worktree`, `isolated branch`, `auto-merge to main`, `spin up a worktree`, `use a worktree`.

When neither is present, the orchestrator skips this reference entirely. When active, the flag persists for the whole run and:

- **Forces a single shared feature branch** for all surviving tasks regardless of dependency bucket. Independent (Layout A) and soft-sequenced (Layout B) plans both collapse to **sequential execution inside one worktree**.
- Still respects hard-chained merging during classification — those merge into one task before worktree provisioning.
- Still applies when only one actionable task survives — provision the worktree and run the single task there.

## Worktree options captured in Phase 1

Scan the prompt once for the options below and record them into a worktree-options structure that persists for the rest of the run. Strip captured flags from the task text **before** classification so they do not leak into subtask descriptions.

When Phase 0 also resolved a ticket (see [`ticket-resolution.md`](ticket-resolution.md)), the resolved ticket id is woven into the auto-derived branch name (`agent/<ticket-id>-<task-slug>-<unix>`) so commit history, PR titles, and tracker-integration autodetection (e.g., Linear's branch-link) stay traceable to the source ticket without changing the `setup-worktree.sh` signature.

| Option | Default | Effect |
| --- | --- | --- |
| `--branch <name>` | auto-derived from task slug | Explicit feature branch name passed to `setup-worktree.sh --branch <name>`. |
| `--base <branch>` | `main`, falls back to `develop` | Base branch passed to `setup-worktree.sh --base <branch>`. |
| `--no-validate` | validation runs | Skips Phase 4.5 step 1 (the `validate-worktree.sh` gate). |
| `--no-merge` | merge runs | Stops after Phase 4 — Phase 4.5 runs only its `--no-merge` closing block. |
| `--keep-branch` | branch deleted on clean merge | Passes `--keep-branch` to `merge-worktree.sh` so the feature branch survives cleanup. |

Echo the captured record back to the user as a single line at the end of the Phase 2 plan, e.g. `Worktree options: branch=auto, base=main, validate=on, merge=on, keep-branch=off`. This makes the user's intent visible before they confirm.

## Phase 2: Layout C (worktree mode confirmation)

Used regardless of dependency classification when the worktree flag is on.

```text
Detected N tasks (worktree mode — sequential execution on one isolated branch):
  1. [skill or "free task"] → [short task description]
  2. ...

Will auto-merge to <base> when green, with a reconciler sub-agent on conflicts.
Proceed? (yes / remove N / add something / reorder / cancel-worktree)
```

- `cancel-worktree` drops worktree mode and re-presents the plan in Layout A or B based on the original classification (then resumes the normal confirmation rules).
- `reorder` is meaningful here — task N+1 sees N's commits, so order changes what each sub-agent observes when it starts.
- All other options (`yes`, `remove N`, `add something`) behave the same as in Layout A.

## Phase 3: Mode 3 (worktree-isolated sequential execution)

1. Run `bash skills/assistant/dev-orchestrator/scripts/setup-worktree.sh --task "<original prompt summary>"`. Append `--branch <name>` and `--base <branch>` only when the user passed them. The script provisions a sibling worktree on a fresh `agent/<slug>-<unix>` branch from the resolved base. Capture two machine-readable lines from stdout:

   ```text
   WORKTREE_PATH=<absolute path>
   WORKTREE_BRANCH=<branch name>
   ```

   On non-zero exit, surface stderr verbatim and stop — do not launch any sub-agent.

2. **Snapshot the branch tip** before launching the first sub-agent: `BRANCH_SHA_0=$(git -C "<WORKTREE_PATH>" rev-parse "<WORKTREE_BRANCH>")`. Persist this as `BRANCH_SHA_PREV` and update it after each verified task so subsequent comparisons happen against the previous task's tip, not the original base.

3. For each task in plan order, issue a **synchronous** `invoke_agent` call (`run_in_background: false`):
   - Prompt opens with: `Work inside <WORKTREE_PATH>. cd into it before any file or shell operation.`
   - Body: skill invocation (`Use the Skill tool with skill '<name>' and args '<args>'`) or free-task description, plus the Test-plan obligation clause for code-touching tasks (same verbatim contract as Mode 1 and Mode 2).
   - Prompt closes with: `When done, run "git add -A && git commit -m '<imperative subject>'" inside the worktree. Do not push, do not switch branches, do not merge. Do not use --amend or --allow-empty.`

4. After every task returns, **verify the commit landed using SHA comparison plus diff inspection** — never a log count:

   ```bash
   BRANCH_SHA_NEW=$(git -C "<WORKTREE_PATH>" rev-parse "<WORKTREE_BRANCH>")
   if [ "$BRANCH_SHA_NEW" = "$BRANCH_SHA_PREV" ]; then
     FAIL "task N produced no commit"
   fi
   if [ -z "$(git -C "<WORKTREE_PATH>" diff --stat "$BRANCH_SHA_PREV" "$BRANCH_SHA_NEW")" ]; then
     FAIL "task N committed but produced no diff"
   fi
   BRANCH_SHA_PREV="$BRANCH_SHA_NEW"
   ```

   The pair of checks catches three failure modes a log-count check missed: `git commit --amend` (SHA changes but the new commit replaces the old one), `git commit --allow-empty` (new SHA, identical tree), and a sub-agent that ran without changing files. On either failure, mark the task as **failed**, stop the chain — later tasks must not run against a no-op base — and report the SHA pair so the user can `git show` to investigate.

5. After the last task succeeds (or any task fails) proceed to Phase 4, then Phase 4.5 (worktree merge), then Phase 5 (QA).

**Phase 3 announcement (Mode 3 only)** — emit exactly once in the same message that issues the first sub-agent call:

`Launching N agents sequentially inside worktree <path> on branch <branch>. I'll report back when the chain finishes.`

## Phase 4: worktree footer and retry menu

Append these two lines to the Phase 4 consolidated report, immediately above the `<successes>/<total>` line, whenever Mode 3 was used:

```text
  Worktree:   <path>     [pending merge | merged & cleaned | preserved (--no-merge) | preserved on failure]
  Branch:     <branch>   [pending merge | merged & deleted | merged & kept | preserved (--no-merge) | preserved on failure]
```

The four terminal states are mutually exclusive:

| Status | Trigger |
| --- | --- |
| `pending merge` | Transient only — visible if the orchestrator is currently between Phase 4 and Phase 4.5. Never a final state. |
| `merged & cleaned` | Phase 4.5 ran cleanly, branch was deleted (`--keep-branch` absent). |
| `merged & kept` | Phase 4.5 ran cleanly, branch was retained (`--keep-branch` present). |
| `preserved (--no-merge)` | `--no-merge` was captured in Phase 1; the merge block deliberately did not run. |
| `preserved on failure` | A Phase 3 task failed, validation failed, or the reconciler aborted. |

When the run ends at `preserved on failure`, replace the worktree-mode retry prompt with this menu so the user has an explicit resume path:

```text
Worktree run did not complete:
  - retry-failed   → re-run only the failed task(s) in-place on <branch>, then auto-resume Phase 4.5
  - resume-merge   → skip retries and run Phase 4.5 now against the current branch tip
  - keep           → leave worktree + branch as-is for manual work; print the resume command and exit
  - discard        → remove the worktree and delete the branch (destructive)
```

For both `keep` (from this menu) and the `--no-merge` closing block, emit the **exact** resume command verbatim so the user can paste it later:

```bash
bash skills/assistant/dev-orchestrator/scripts/validate-worktree.sh "<WORKTREE_PATH>" \
  && bash skills/assistant/dev-orchestrator/scripts/merge-worktree.sh "<WORKTREE_PATH>" "<WORKTREE_BRANCH>" "<BASE>" \
       --summary "<one-line task summary>"
```

Strip `validate-worktree.sh` from the chain when `--no-validate` was captured in Phase 1; append `--keep-branch` when that flag was captured. This guarantees the user can return to Phase 4.5 days later without rereading the SKILL — the command is in their consolidated report.

The retry menu fires **only** on failure; the `--no-merge` opt-out follows its dedicated closing block below instead.

## Phase 4.5: worktree merge pipeline

Skip entirely when Mode 1 or Mode 2 was used. When Mode 3 was used **and** Phase 1 captured `--no-merge`, run the dedicated closing block below instead of steps 1–4. Otherwise run steps 1–4 only when Phase 4 shows `<total>/<total>` tasks completed; if any task failed, defer to the worktree retry menu instead.

This phase reads the worktree-options record from Phase 1 to decide which scripts run and which flags they receive:

| Captured option | Phase 4.5 behavior |
| --- | --- |
| `--no-validate` | Skip step 1 entirely; jump straight to step 2. |
| `--no-merge` | Phase 4.5 runs only the `--no-merge` closing block. |
| `--keep-branch` | Append `--keep-branch` to the `merge-worktree.sh` invocation. |

### Step 1: Validate

When `--no-validate` is **not** in the captured options, run:

```bash
bash skills/assistant/dev-orchestrator/scripts/validate-worktree.sh "<WORKTREE_PATH>"
```

The script auto-detects per-ecosystem checks (JS/TS lint + typecheck + tests; Python `ruff` + `mypy` + `pytest`; Ruby `rubocop` + `rspec`). Absent checks count as PASS. On any failure: surface the failing command and the tail of its output, rewrite the worktree footer to `preserved on failure`, emit the resume command (see Phase 4 retry menu), and skip Phase 5.

### Step 2: Merge

```bash
bash skills/assistant/dev-orchestrator/scripts/merge-worktree.sh \
  "<WORKTREE_PATH>" "<WORKTREE_BRANCH>" "<BASE>" \
  --summary "<one-line task summary>"
```

Append `--keep-branch` **only** when the captured options include it. The script:

- Refuses to run if the primary worktree is dirty.
- Fast-forwards the base branch from `origin` (best-effort).
- Runs `git merge --no-ff` with a generated message.
- On clean merge: pushes (when a remote exists), removes the worktree, and deletes the feature branch unless `--keep-branch` was passed. Exits `0`.
- On conflict: exits with code `2` and prints conflicted file paths on stdout. The merge stays in progress for the reconciler.

### Step 3: Reconciler sub-agent (only on merge exit code 2)

Issue one synchronous `invoke_agent` call (`run_in_background: false`):

> You are resolving a git merge conflict in `<primary worktree path>`. The conflicted files are: `<list>`. Read each file, resolve every conflict block so the final code preserves the intent of both sides — do not silently drop logic from either branch. When every conflict is resolved, run `git add -A && git commit --no-edit` to finalize the merge. If a conflict is semantically ambiguous (both sides rewrote the same logic in incompatible ways), do NOT guess — abort the merge with `git merge --abort` and report which file caused the ambiguity.

After the reconciler returns, check `git rev-parse -q --verify MERGE_HEAD`. If absent, the merge completed → finish cleanup (worktree removed, branch deleted unless `--keep-branch`). If present, the reconciler aborted — surface the flagged file and leave the worktree intact.

### Step 4: Footer rewrite

Update the Phase 4 worktree footer lines to their terminal status (`merged & cleaned`, `merged & kept`, or `preserved on failure`) before proceeding to Phase 5.

### no-merge closing block (replaces steps 1 to 4)

Applies when `--no-merge` was captured in Phase 1 and tasks succeeded — single-task or multi-task alike. Tasks completed; the user explicitly opted out of merge. Do **not** show the failure retry menu — nothing failed.

1. Rewrite both worktree footer lines to `preserved (--no-merge)` so the closing status is unambiguous.
2. Emit the same resume command the `keep` retry option emits (built dynamically — strip `validate-worktree.sh` when `--no-validate` was captured; append `--keep-branch` when that flag was captured) prefixed with a one-line opt-out confirmation, e.g. `Worktree preserved per --no-merge. Run this when ready to merge:`.
3. Skip Phase 5 — nothing has reached the base branch yet to verify. QA can be invoked manually after the user finishes the merge themselves (see the "QA after a manual merge from a `--no-merge` run" troubleshooting entry in SKILL.md for the exact invocation).

## Phase 5 interaction (worktree mode)

When Mode 3 was used and Phase 4.5 completed cleanly, the changes are already on the base branch in the primary worktree, so QA runs unchanged — the handoff scope (PR number or task summary) is identical to Mode 1 / Mode 2.

**Skip Phase 5 entirely** when the worktree footer ended at either `preserved on failure` or `preserved (--no-merge)` — nothing has reached the base branch in either case, so there is nothing merged to verify.

## End-to-end example (Case E)

**User prompt:**

> `/orchestrate --worktree generate the migration and the matching service refactor and auto-merge to main when green`

**Expected behavior:**

Phase 1 detects the `--worktree` opt-in **before** classification and sets the worktree flag, captures `branch=auto, base=main, validate=on, merge=on, keep-branch=off`. Two tasks survive (`free task` for the migration + `free task` for the service refactor — both code-touching); classification would normally route them as soft-sequenced, but worktree mode forces **single-branch sequential execution** regardless.

Phase 2 presents Layout C; user confirms with `yes`.

Phase 3 Mode 3 runs `setup-worktree.sh`, captures `WORKTREE_PATH` and `WORKTREE_BRANCH`, snapshots `BRANCH_SHA_PREV`, then issues two sequential `invoke_agent` calls inside the worktree (migration first, refactor second). After each call, SHA comparison + diff inspection verifies the commit landed; `BRANCH_SHA_PREV` advances to the new tip.

Phase 4 consolidates with the worktree footer at `pending merge`.

Phase 4.5 runs `validate-worktree.sh` (passes), runs `merge-worktree.sh` (clean), pushes to `origin/main`, removes the worktree, deletes the feature branch, and rewrites the footer to `merged & cleaned`.

Phase 5 hands off to `qa-orchestrator` because both tasks were code-touching — the merged diff is already on `main`, so QA scopes by task summary as usual.

## Script invocation cheatsheet

| Script | Required positional args | Optional flags |
| --- | --- | --- |
| `setup-worktree.sh` | `--task "<text>"` (or `--branch <name>`) | `--branch <name>`, `--base <branch>` |
| `validate-worktree.sh` | `<worktree_path>` | none |
| `merge-worktree.sh` | `<worktree_path> <feature_branch> <base_branch>` | `--keep-branch`, `--summary "<text>"` |

All three live under `skills/assistant/dev-orchestrator/scripts/` and run on `bash` (works under git-bash on Windows and any POSIX shell on Linux/macOS).
