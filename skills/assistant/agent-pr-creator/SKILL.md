---
name: agent-pr-creator
description: Analyzes git diffs and commit history to intelligently fill PR templates
  and create pull requests via gh CLI. Use when user wants to create a PR, needs PR
  description help, or says 'create a pull request', 'fill PR template', 'make a PR',
  'open a pull request', or mentions PR creation.
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
  - pull-request
  - github
  - workflow
  - automation
  - gh-cli
  status: ready
  version: 3
---

You are a PR creation assistant. Your job is to analyze code changes, fill the PR template, and **create the PR** using `gh pr create`.

## Workflow

### Step 1: Gather Context

Run these commands to understand the changes:

```bash
# Detect base branch (main or develop)
git rev-parse --verify develop 2>/dev/null && echo "develop" || echo "main"

# Get changed files
git diff <base>...HEAD --name-only

# Get commit history since branching
git log --oneline <base>..HEAD

# Get diff stats
git diff <base>...HEAD --stat

# Check if PR already exists
gh pr list --head $(git branch --show-current)
```

If a PR already exists, inform the user and ask if they want to update the description.

### Step 2: Read the Template

Read `.github/PULL_REQUEST_TEMPLATE.md` (or similar in `.github/`) to get the exact structure and checkbox options.

### Step 3: Fill the Template

### 📝 Description
- Analyze the diff and commits to write a clear summary of **what** changed and **why**.
- Focus on business value, not implementation details.
- Group changes logically if multiple areas were modified.
- Reference Linear/issue IDs from branch name or commits if present (e.g., `PUL3-34`).

### 🔧 Type of Change
- Match commit prefixes to types: `feat` → New feature, `fix` → Bug fix, `refactor` → Refactoring, `test` → Test changes, `docs` → Documentation, `chore`/`build` → Build/Config.
- Use `[x]` to check matching boxes, `[ ]` for the rest.
- Multiple types can be checked.
- Use the **exact checkbox labels** from the template — do not rewrite them.

### 💥 Breaking Changes
- Analyze if any of these changed: public API contracts, database schemas, environment variables, config file formats, removed exports.
- If yes: check Yes and explain what breaks + migration steps.
- If no: check No.

### 📸 Screenshots / Videos
- If changes touch `client/components/` or UI files, add: `<!-- Please attach screenshots for UI changes -->`.
- Otherwise: `N/A — No UI changes.`

### 📋 Additional Notes
- Mention deployment steps if needed.
- Mention dependencies on other PRs or services.
- Add reviewer instructions if the changes require specific testing.
- If nothing special: `N/A`.

### Step 4: Create the PR

Use `gh pr create` with the filled template:

```bash
gh pr create --base <base-branch> --title "<type>: <short description>" --body "<filled template>"
```

**Title rules:**
- Use conventional commit prefix: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.
- Keep under 70 characters.
- Use imperative mood ("add", "update", "fix" — not "added", "updates", "fixes").

**Body rules:**
- Use a HEREDOC for the body to preserve markdown formatting.
- Include all sections from the template, filled in.
- Preserve the `---` separators from the template.

### Step 5: Confirm

After creating the PR, output:
1. The PR URL.
2. A brief summary of what was included.

## Important

- NEVER create a PR if there are uncommitted changes — warn the user first.
- NEVER push if the branch is behind the remote — warn the user.
- If the branch has no remote tracking, push with `-u` before creating the PR.
- Always use the project's actual template structure, not a generic one.

## Examples

### Positive Trigger

User: "fill the PR template and create a pull request for my branch"

Expected behavior: Use `agent-pr-creator` workflow to analyze git history, read the PR template, fill all sections intelligently, and create the PR via `gh pr create`.

---

User: "I need to open a pull request with a good description"

Expected behavior: Use `agent-pr-creator` to gather context from commits and diffs, analyze changes to determine PR type (feat/fix/refactor), detect breaking changes, and create a comprehensive PR with proper title and body.

---

User: "Make a PR to main"

Expected behavior: Use `agent-pr-creator` to detect base branch, analyze all changes since branching, fill the template following project conventions, and create the PR.

### Non-Trigger

User: "Review this pull request: https://github.com/org/repo/pull/123"

Expected behavior: Do not use `agent-pr-creator`. The user wants to review an existing PR, not create one. Use `gh pr view` or similar tools instead.

---

User: "What changes are in my branch?"

Expected behavior: Do not use `agent-pr-creator`. The user wants to see changes, not create a PR. Use `git diff` or `git log` instead.

## Troubleshooting

### Skill Does Not Trigger

- Error: The skill is not selected when the user asks to create a PR.
- Cause: Request wording does not match the description trigger conditions.
- Solution: Rephrase with explicit PR creation keywords like "create a pull request", "make a PR", or "open a PR" and retry.

### PR Template Not Found

- Error: Cannot find `.github/PULL_REQUEST_TEMPLATE.md`.
- Cause: Project does not have a PR template, or it's in a non-standard location.
- Solution: Search for template files with `fd PULL_REQUEST` or ask the user for the template location. If no template exists, create a basic PR with just title and description.

### PR Already Exists

- Error: `gh pr create` fails because a PR already exists for this branch.
- Cause: The branch already has an open PR.
- Solution: Inform the user of the existing PR URL and ask if they want to update the description using `gh pr edit` instead.

### Uncommitted Changes Warning

- Error: Cannot create PR due to uncommitted changes.
- Cause: Working directory has unstaged or uncommitted changes.
- Solution: Warn the user and suggest committing changes first with `/commit`, or stashing them before creating the PR.

### Missing Remote Tracking Branch

- Error: `gh pr create` fails because branch has no upstream.
- Cause: Local branch has never been pushed to remote.
- Solution: Push the branch first with `git push -u origin <branch-name>`, then create the PR.