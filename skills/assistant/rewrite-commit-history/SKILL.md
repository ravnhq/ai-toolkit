---
name: rewrite-commit-history
description: 'Rewrite a feature branch''s commit history into clean conventional commits
  that tell a progressive, linear story. Handles backup, soft reset, and atomic recommit.
  Use when: (1) Cleaning up messy WIP commits before PR, (2) Reorganizing commits
  into logical units, (3) Converting commits to conventional commit format. Triggers
  on: "rewrite history", "clean up commits", "rewrite commits", "conventional commits",
  "squash and rewrite", "reorganize commits".

  '
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: assistant
  tags:
  - git
  - commits
  - history
  - conventional-commits
  - rewrite
  status: ready
  version: 3
---

# Rewrite Commit History

Rewrite a feature branch's messy commit history into clean, conventional commits that tell a progressive, linear story — safe to read, review, and bisect.

## Workflow

### Step 1 — Guard

Abort if the working tree is dirty. A clean rewrite requires a clean state.

```bash
git status --porcelain
```

If output is non-empty: stop. Tell the user to stash or commit pending changes first.

Then detect the parent branch. The entire rewrite depends on using the correct base — a wrong base means wrong diffs and wrong commits.

```bash
git log --oneline --decorate --graph --all | head -20
```

Check if the branch has commits relative to `main`:

```bash
git log --oneline main..HEAD 2>/dev/null | wc -l
```

If the count is 0 or the command fails, the branch was likely forked from something other than `main`. Ask the user to confirm the target branch before proceeding. Do not assume `main`.

Common alternatives: `master`, `develop`, `staging`, `origin/main`.

Once confirmed, set the base branch for all subsequent steps:

```bash
BASE=<confirmed-branch>  # e.g. BASE=main or BASE=develop
```

### Step 2 — Backup

Create a timestamped backup branch at the current HEAD before touching anything.

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
EPOCH=$(date +%s)
git branch backup/${BRANCH}-${EPOCH}
```

Confirm backup was created. This is the restore point if anything goes wrong.

### Step 3 — Analyze

Read the full diff and log between the base branch and HEAD.

```bash
git log --oneline ${BASE}..HEAD
git diff --stat ${BASE}...HEAD
```

For large branches (many files), start with `--stat` to see the scope before reading the full diff. Then read individual files as needed to understand the changes in depth.

```bash
git diff ${BASE}...HEAD
```

Identify the logical units of work. Look for:
- Feature additions (new files, new functions)
- Bug fixes (targeted changes to existing code)
- Refactors (structural changes with no behavioral difference)
- Config/tooling changes
- Tests added or updated
- Docs updated

Group related changes together. A good commit is one logical unit, not one file.

### Step 4 — Plan

Present the proposed commit sequence to the user. Each entry must include:
- The conventional commit message (type + scope + subject)
- A brief summary of which files/changes are included

Order commits so each builds on the previous — the branch should compile and make sense at every point.

Example plan format:
```
1. feat(auth): add JWT token generation
   Files: src/auth/token.ts, src/auth/types.ts

2. feat(auth): add login endpoint with token issuance
   Files: src/routes/auth.ts, src/routes/auth.test.ts

3. chore: update env example with JWT secret
   Files: .env.example
```

Before confirming, verify every file that appears in `git diff --stat ${BASE}...HEAD` is assigned to at least one commit in the plan. Unassigned files will cause the tree parity check to fail in Step 6.

### Step 5 — Confirm

Wait for user approval before executing. Accept:
- Approval as-is
- Edits to commit messages
- Reordering of commits
- Splitting one commit into two
- Merging two commits into one

Do not proceed until the user confirms the plan.

### Step 6 — Execute

Soft-reset to the merge base, then create each commit one at a time with selective staging.

```bash
git reset --soft $(git merge-base ${BASE} HEAD)
```

For each planned commit:
```bash
git add <specific files for this commit>
git commit -m "<conventional commit message>"
```

Use selective `git add` — never `git add -A` for a batch. Each commit must contain only its planned files.

After all commits, verify tree parity against the backup:

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
# Find the backup branch (most recent for this branch).
# sort works correctly here because the epoch timestamp is always 10 digits (valid until 2286).
BACKUP=$(git branch --list "backup/${BRANCH}-*" | sort | tail -1 | tr -d ' ')
git diff HEAD ${BACKUP}
```

If diff is non-empty: something was lost or corrupted. Restore immediately:
```bash
git reset --hard ${BACKUP}
```
Report the failure and stop.

### Step 7 — Verify

Confirm success:
- `git log --oneline ${BASE}..HEAD` shows the new clean history
- `git diff HEAD ${BACKUP}` is empty (tree parity confirmed)
- Report the backup branch name so the user can delete it when satisfied

## Conventional Commit Types

| Type | Use for |
|------|---------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code change with no behavior change |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Build, tooling, config, deps |
| `perf` | Performance improvement |
| `ci` | CI/CD changes |
| `style` | Formatting, whitespace (no logic change) |
| `revert` | Reverts a previous commit |

**Format**: `type(scope): subject` — subject is imperative, lowercase, no period.

**Breaking changes**: Append `!` after type/scope, e.g. `feat(api)!: rename endpoint`.

## Base Branch Override

Default base is `main`. Override with `BASE=<branch>` before running, or ask the user if uncertain.

Common alternatives: `master`, `develop`, `staging`, `origin/main`.

## Examples

### Positive Trigger

User: "Can you clean up my commits before I open this PR? It's a bunch of WIP saves."

Expected behavior: Use this skill. Start with Step 1 (guard check), then proceed through all steps.

### Positive Trigger

User: "Rewrite my commit history into conventional commits."

Expected behavior: Use this skill. Follow the full 7-step workflow.

### Non-Trigger

User: "Write a commit message for my current changes."

Expected behavior: Do not use this skill. Write a single commit message directly.

### Non-Trigger

User: "Squash my last 3 commits into one."

Expected behavior: Do not use this skill. Use `git reset --soft HEAD~3` directly and commit.

## Troubleshooting

### Working Tree Is Not Clean

- Error: `git status --porcelain` returns output before the rewrite starts.
- Cause: Unstaged or staged changes exist in the working directory.
- Solution: Ask the user to stash (`git stash`) or commit pending changes, then retry.

### Merge Base Cannot Be Found

- Error: `git merge-base ${BASE} HEAD` fails or returns unexpected output.
- Cause: The base branch name is wrong, or the branch has no common ancestor with the specified base.
- Solution: Ask the user to confirm the base branch. Try `git log --oneline` to see branch history.

### Tree Parity Check Fails After Rewrite

- Error: `git diff HEAD ${BACKUP}` is non-empty after all commits are created.
- Cause: One or more files were missed during selective staging, or a file was double-staged.
- Solution: Immediately restore with `git reset --hard ${BACKUP}`. Report which files diverged. Re-plan and retry.

### Backup Branch Not Found During Verify

- Error: `git branch --list "backup/${BRANCH}-*"` returns empty.
- Cause: Branch was deleted or the shell variable substitution failed.
- Solution: Run `git branch --list "backup/*"` to locate any backup branches. Do not proceed with verification until the backup is confirmed.
