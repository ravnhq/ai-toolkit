---
name: agent-pr-creator
description: 'Analyzes git diffs and commit history to intelligently fill PR templates
  and create pull requests via gh CLI. Use when: creating a PR, needing PR description
  help, saying ''create a pull request'', ''fill PR template'', ''make a PR'', ''open
  a pull request''. Triggers on: create PR, open pull request, make a PR, fill template.'
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
  version: 4
---

# Agent PR Creator

Analyze git diffs and commit history to intelligently fill PR templates and create pull requests via `gh` CLI. This skill walks through detecting the base branch, analyzing changes, reading the project's PR template, filling it with context from commits and diffs, and creating the PR.

## Workflow

### Phase 1: Detect Base Branch and Check for Existing PR

Determine what base branch this PR will target:

```bash
# Check if develop exists; fall back to main
git rev-parse --verify develop 2>/dev/null && echo "develop" || echo "main"

# Current branch
git branch --show-current
```

Check if a PR already exists for the current branch:

```bash
gh pr list --head $(git branch --show-current) --json number,url,title
```

If a PR exists, stop and inform the user. Ask if they want to update the description with `gh pr edit` instead.

**Gate:** If there are uncommitted changes or the branch is behind remote, warn the user and stop:

```bash
# Check for uncommitted changes
git status --porcelain

# Check if branch is behind remote
git rev-parse @{u} 2>/dev/null && git log --oneline @..@{u}
```

If the branch has no remote tracking, push with `-u` before creating the PR:

```bash
git push -u origin $(git branch --show-current)
```

### Phase 2: Analyze Changes

Gather the full context of changes since the base branch:

```bash
# Get the base branch
BASE=$(git rev-parse --verify develop 2>/dev/null && echo "develop" || echo "main")

# Changed files
git diff ${BASE}...HEAD --name-only

# Commit log with oneline format
git log --oneline ${BASE}..HEAD

# Diff stats (file-level changes)
git diff ${BASE}...HEAD --stat

# Full diff for review (optional, context-dependent)
git diff ${BASE}...HEAD
```

Analyze the changes to understand:
- What files were modified and in what areas (frontend, backend, tests, docs, config)
- How many commits were made
- What conventional commit types are present (feat, fix, refactor, test, docs, chore)
- Any breaking changes (API changes, schema migrations, config format changes)
- Whether this is a refactor, new feature, bug fix, or combination

### Phase 3: Read the PR Template

Locate and read the project's PR template:

```bash
# Standard locations
ls -la .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md PULL_REQUEST_TEMPLATE.md pull_request_template.md 2>/dev/null | head -1
```

If found, read the entire template to understand:
- All required sections (Description, Type of Change, Breaking Changes, Screenshots, Notes, Checklist)
- Exact checkbox labels and options
- Any specific instructions or conventions the project uses

If no template is found, create a minimal PR with just title and description.

### Phase 4: Fill the PR Template

Fill each section of the template based on the changes:

**Title:** Use conventional commit format

- Prefix: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:` based on the majority of commits
- Format: `<type>: <short description>`
- Keep under 70 characters
- Use imperative mood ("add", "fix", "update", not "added", "fixed", "updates")
- Example: `feat: add authentication service integration`

**Description:**

- Analyze the diff and commits to write 2-3 sentence summary of **what** changed and **why**
- Focus on business value, not implementation details
- Group logically if multiple areas were modified (e.g., "Database layer changes to improve query performance. Frontend changes to display new metrics. New monitoring queries added to dashboard.")
- Reference Linear/issue IDs if present in branch name or commits (e.g., `PUL3-34`, `#123`)
- Example: "Adds OAuth 2.0 authentication flow for third-party integrations. Uses standard OIDC provider patterns to support multiple identity services. Closes PUL3-42."

**Type of Change:**

- Analyze commit prefixes: `feat` → New Feature, `fix` → Bug Fix, `refactor` → Code Refactoring, `test` → Tests, `docs` → Documentation, `chore`/`build` → Build/Config
- Check boxes that match: `[x]` for selected, `[ ]` for unselected
- Use **exact checkbox labels** from the template — do not rewrite or paraphrase
- Multiple boxes can be checked (e.g., a feature PR might also include tests)

**Breaking Changes:**

- Analyze if any of these were modified:
  - Public API contracts (function signatures, endpoints, exported types)
  - Database schemas (new required fields, removed columns, type changes)
  - Environment variables (new required vars, removed vars, changed format)
  - Config file formats (structure, required keys, deprecated options)
  - Removed exports or public methods
- If yes: check "Yes" and explain what breaks and required migration steps
- If no: check "No"
- Example: "Yes — `POST /api/auth/login` now requires `oauth_provider` field. Existing calls without this field will return 400. Migrate by updating client-side auth code to specify the provider."

**Screenshots / Videos:**

- If changes touch UI files (`src/components/`, `pages/`, `app/`, or file extensions like `.jsx`, `.tsx`, `.vue`): add placeholder `<!-- Please attach screenshots/videos of UI changes -->`
- Otherwise: write `N/A — No UI changes`

**Additional Notes / Checklist:**

- Mention deployment steps if non-standard (database migrations, environment setup, service restarts)
- Mention dependencies on other PRs or services
- Add reviewer instructions if changes require specific testing paths or edge cases
- If nothing special: `N/A` or leave empty per template style

### Phase 5: Create the PR

Use `gh pr create` with the filled template and title:

```bash
gh pr create \
  --base ${BASE} \
  --title "<type>: <short description>" \
  --body "<filled template body as HEREDOC or string>"
```

Example:

```bash
gh pr create --base develop \
  --title "feat: add authentication service integration" \
  --body $'## Description\nAdds OAuth 2.0 support for third-party integrations.\n\n## Type of Change\n- [x] New Feature\n- [ ] Bug Fix\n\n## Breaking Changes\n- [ ] Yes\n- [x] No\n\n## Screenshots\nN/A'
```

**Important:** Preserve markdown formatting from the template. Use shell HEREDOC (`$'...'`) or multi-line strings to maintain section separators and formatting.

### Phase 6: Confirm and Report

After `gh pr create` succeeds, output:

1. The PR URL (e.g., `https://github.com/owner/repo/pull/456`)
2. PR number
3. A brief summary of what was included (types of changes, key areas affected)
4. Mention if any reviewers were auto-assigned or any special status (draft, ready for review)

Example output:

```
PR created: https://github.com/ravn/ai-toolkit/pull/123
Type: feat (New Feature)
Changes: 3 files, 156 additions
Affected areas: Authentication service, OAuth integration tests
Ready for review.
```

## Examples

### Positive Trigger

User: "fill the PR template and create a pull request for my branch"

Expected behavior: Use agent-pr-creator workflow to analyze git history, read the PR template, fill all sections intelligently based on the changes, and create the PR via `gh pr create`.

---

User: "I need to open a pull request with a good description"

Expected behavior: Use agent-pr-creator to gather context from commits and diffs, analyze the change type (feat/fix/refactor), detect breaking changes, and create a comprehensive PR with proper title and body following conventions.

---

User: "Make a PR to main"

Expected behavior: Use agent-pr-creator to detect the base branch, analyze all changes since branching, fill the template following project conventions, and create the PR.

### Non-Trigger

User: "Review this pull request: https://github.com/org/repo/pull/123"

Expected behavior: Do not use agent-pr-creator. The user wants to review an existing PR, not create one. Use `gh pr view` or a review skill instead.

---

User: "What changes are in my branch?"

Expected behavior: Do not use agent-pr-creator. The user wants to see changes, not create a PR. Use `git diff` or `git log` directly.

## Troubleshooting

### Skill Does Not Trigger

- Error: The skill is not selected when the user asks to create a PR.
- Cause: Request wording does not match trigger phrases. Request used generic words like "review" or "commit" instead of "create PR", "open PR", or "make PR".
- Solution: Rephrase with explicit PR creation keywords like "create a pull request", "make a PR", or "open a PR" and retry.

### PR Template Not Found

- Error: Cannot find `.github/PULL_REQUEST_TEMPLATE.md` or similar.
- Cause: Project does not have a PR template, or it's in a non-standard location.
- Solution: Search for template files in `.github/` and common root locations. If none exist, create a minimal PR with just title and description using the conventional commit format.

### PR Already Exists for This Branch

- Error: `gh pr create` fails because a PR already exists for this branch.
- Cause: The branch already has an open PR.
- Solution: Inform the user of the existing PR URL and ask if they want to update the description using `gh pr edit <PR>` instead of creating a new one.

### Uncommitted Changes or Branch Behind Remote

- Error: Cannot create PR due to uncommitted changes or branch being behind remote.
- Cause: Working directory has unstaged/uncommitted changes or local branch is behind upstream.
- Solution: For uncommitted changes: warn the user and suggest committing with `/commit` or stashing first. For branch behind: pull and rebase before creating the PR.

### Missing Remote Tracking Branch

- Error: `gh pr create` fails because branch has no upstream tracking.
- Cause: Local branch has never been pushed to the remote.
- Solution: Push the branch first with `git push -u origin <branch-name>`, then create the PR.

### gh CLI Authentication Failed

- Error: `gh` commands fail with "not authenticated" or "token expired" error.
- Cause: GitHub CLI is not logged in or the auth token has expired.
- Solution: Run `gh auth login` to re-authenticate, then retry the skill.