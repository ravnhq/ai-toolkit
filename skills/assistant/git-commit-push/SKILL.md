---
name: git-commit-push
description: 'Stage changes, write a clean conventional commit message, and push to
  remote — without ever adding Co-authored-by attribution for any LLM (Claude, Copilot,
  GPT, Cursor, Gemini, Bard). Use when committing and pushing code: "commit and push",
  "push my changes", "make a commit", "save my work to git", "ship this", "commit
  everything", "stage and commit". Triggers on: commit, push, git commit, save changes,
  ship code. Does NOT trigger for: PR creation, history rewrite, branch management,
  or squashing commits.'
allowed-tools:
- Bash
- Read
metadata:
  category: assistant
  tags:
  - git
  - commit
  - push
  - workflow
  - conventional-commits
  status: ready
  version: 1
---

# git-commit-push

Stage changes, compose a clean conventional commit message, and push to remote in one smooth workflow — with a hard rule: no Co-authored-by attribution for any LLM, ever.

## Workflow

### Phase 1 — Guard

Check the current branch and remote state before touching anything:

```bash
git branch --show-current
git status --porcelain
git remote -v
```

If `git status --porcelain` returns nothing (no changes): stop and inform the user there is nothing to commit.

Check if the branch has an upstream:

```bash
git rev-parse --abbrev-ref @{u} 2>/dev/null || echo "no-upstream"
```

Note whether a `-u` flag will be needed during push. Do not push yet.

### Phase 2 — Stage

Show the full working tree status so the user can see exactly what is modified, added, and untracked:

```bash
git status
```

Ask the user which files to stage — unless they said "commit everything" or "commit all", in which case stage all tracked changes:

```bash
# Stage all tracked + untracked changes
git add -A

# OR stage specific files (when user specifies)
git add <file1> <file2> ...
```

After staging, confirm what is now in the index:

```bash
git diff --cached --stat
```

If the staged set is empty after the add: stop and ask the user what they want to stage.

### Phase 3 — Compose

Read the staged diff to understand the changes:

```bash
git diff --cached
```

Write a conventional commit message based on what was staged. Follow these rules exactly:

**Conventional commit format:** `type(scope): subject`

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

- Subject is **imperative mood**, lowercase, no trailing period
- Scope is optional but recommended when changes are scoped to one module/area
- Breaking changes: append `!` after type/scope, e.g. `feat(api)!: rename endpoint`
- Keep the subject line under 72 characters

**Body and footer rules:**
- Body is optional — include only when the *why* is non-obvious from the subject
- Separate body from subject with a blank line
- If a footer is needed (e.g. `Closes #123`), include it after another blank line

## No-LLM Co-author Rule

This is a hard constraint. **Never generate, suggest, or allow any of the following trailer lines** in a commit message:

```
Co-authored-by: Claude <...>
Co-authored-by: GitHub Copilot <...>
Co-authored-by: GPT-4 <...>
Co-authored-by: Cursor <...>
Co-authored-by: Gemini <...>
Co-authored-by: Bard <...>
Co-authored-by: ChatGPT <...>
Co-authored-by: Tabnine <...>
Co-authored-by: Codeium <...>
```

Also forbidden: any trailer containing `@claude.ai`, `@githubcopilot`, `noreply+copilot@github.com`, or any other LLM bot email pattern.

If the user's environment (`.gitconfig`, `prepare-commit-msg` hook, editor template) would inject such a line: strip it from the composed message before presenting to the user. Do not warn about it unless the user asks — just silently omit it.

The commit is authored solely by the human developer. The AI assistant is a tool, not a co-author.

### Phase 4 — Confirm

Present the complete commit that will be created:

```
Branch:  <branch-name>
Staged:  <N files, +X -Y lines>

Commit message:
──────────────────────────────────────────
<type>(scope): subject line here

Optional body paragraph if included.

Closes #123  ← footer if applicable
──────────────────────────────────────────
```

Wait for the user to:
- Approve as-is
- Edit the message
- Change the scope or type
- Cancel

Do not proceed until the user confirms.

### Phase 5 — Commit

Execute the commit with the approved message:

```bash
git commit -m "<subject line>"
# OR with body:
git commit -m "<subject line>" -m "<body paragraph>"
```

Verify exit code is 0. If the commit fails (e.g. pre-commit hook rejection): report the full hook output and stop. Do not retry automatically.

### Phase 6 — Push

Push to the remote:

```bash
# If upstream exists
git push

# If no upstream (first push for this branch)
git push -u origin $(git branch --show-current)
```

After a successful push, report:
- The remote URL and branch (e.g. `origin/feature/my-branch`)
- The commit SHA (short): `git rev-parse --short HEAD`
- The commit subject line

Example output:

```
Pushed to origin/feature/add-auth (abc1234)
feat(auth): add JWT token generation
```

## Examples

### Positive Trigger

User: "commit and push my changes"

Expected behavior: Use this skill. Start Phase 1 (guard), show status, stage changes, compose conventional commit, confirm with user, commit, push.

---

User: "ship this — commit everything and push"

Expected behavior: Use this skill. Stage all changes with `git add -A`, compose a commit message from the full staged diff, confirm, commit, push.

---

User: "make a commit for the new login component"

Expected behavior: Use this skill. Show current status, help stage relevant files, compose a `feat` commit scoped to the component, confirm, commit. Ask if the user wants to push after committing.

### Non-Trigger

User: "create a pull request for my branch"

Expected behavior: Do not use this skill. Use the `agent-pr-creator` skill instead.

---

User: "rewrite my commit history into conventional commits"

Expected behavior: Do not use this skill. Use the `rewrite-commit-history` skill instead.

---

User: "squash my last 3 commits"

Expected behavior: Do not use this skill. Run `git reset --soft HEAD~3` directly and explain.

## Troubleshooting

### Nothing to Commit

- Error: `git status --porcelain` returns empty output.
- Cause: Working tree is clean — no modified, staged, or untracked files exist.
- Solution: Inform the user there is nothing to commit. Suggest `git status` to verify, or check if they are on the correct branch.

### Pre-commit Hook Rejects the Commit

- Error: `git commit` exits non-zero due to a pre-commit or commit-msg hook failure.
- Cause: The project has lint, format, or test hooks that failed.
- Solution: Report the full hook output to the user. Do not bypass hooks with `--no-verify`. Ask the user to fix the reported issues and retry.

### No Remote Configured

- Error: `git remote -v` returns empty output.
- Cause: The repository has no remote configured.
- Solution: Stop before the push phase. Inform the user no remote is set. Suggest `git remote add origin <url>` and retry.

### Branch Has No Upstream and Push Fails

- Error: `git push` exits with "The current branch has no upstream branch".
- Cause: The branch was never pushed to the remote before.
- Solution: Re-run push as `git push -u origin $(git branch --show-current)` to set tracking and push simultaneously.

### Diverged From Remote

- Error: `git push` exits with "Updates were rejected because the tip of your current branch is behind its remote counterpart".
- Cause: Remote has commits that the local branch does not have.
- Solution: Stop. Do not force-push. Ask the user to run `git pull --rebase` to reconcile, then retry the push.

### LLM Co-author Line Detected in Hook Output

- Error: A `prepare-commit-msg` hook inserts a `Co-authored-by: <LLM>` line that appears in the commit after the fact.
- Cause: The repo or user's global git config has a hook that appends LLM attribution.
- Solution: After commit, check the final message with `git log -1 --format=%B`. If an LLM co-author trailer is present, amend immediately: `git commit --amend -m "<original message without the trailer>"`. Then push.
