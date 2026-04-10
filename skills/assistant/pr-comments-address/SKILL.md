---
name: pr-comments-address
description: 'Reads open review comments from a GitHub PR, triages them by severity,
  applies code fixes, and drafts replies. Use when: addressing PR comments, fixing
  review feedback, responding to code review. Triggers on: address review comments,
  fix PR feedback, handle PR comments, respond to review.'
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
  - code-review
  - workflow
  - automation
  - gh-cli
  status: ready
  version: 6
---

# PR Comments Address

Read open review comments from a GitHub PR, intelligently triage them by severity and type, apply code fixes, and draft professional replies. This skill ensures no feedback is missed and all changes are intentional.

## Workflow

### Phase 1: Detect PR and Fetch Comments

Identify the PR from arguments or auto-detect from current branch:

```bash
# If PR number/URL provided as argument, use it
# Otherwise detect from current branch
gh pr view --json number,url,title,body,author
```

If no PR is found, stop and ask the user for a PR number or URL.

Fetch all review comments from the PR:

```bash
gh pr view <PR> --json reviews,comments,reviewThreads
```

Parse the JSON output to extract:
- Comment author and timestamp
- File and line number
- Comment body
- Whether the comment thread is resolved
- Whether the comment is a review or standalone comment

Read any project-specific rules from `CLAUDE.md` or `.claude/rules/` if they exist (e.g., code style, testing requirements, review conventions). Apply those rules when triaging comments.

### Phase 2: Triage Comments by Category

Categorize every unresolved comment into exactly one category:

| Category | Definition | Action | Example |
|----------|-----------|--------|---------|
| **Must-fix** | Required change, unambiguous, blocking merge | Apply code change | "Add error handling for null case" |
| **Should-fix** | Recommended improvement, clear intent, improves quality | Apply code change after confirmation | "Extract this to a separate function for readability" |
| **Clarification needed** | The intent is unclear or the solution depends on context | Ask user for decision | "Why does this use setTimeout instead of Promise?" |
| **Discussion / Question** | No code change needed, just needs a reply | Draft reply only | "What's the performance impact of this change?" |
| **Praise / Acknowledgement** | Positive feedback or agreement | Brief acknowledgement | "Nice implementation!" |

**Triage decision tree:**
1. Is the change clearly defined? → Must-fix or Should-fix
2. Is there any ambiguity about the solution? → Clarification needed
3. Does it require a code change? → Must-fix or Should-fix; if no: Discussion/Question
4. Is it subjective feedback? → Discussion/Question

Output a triage table showing every comment, its category, and the required action.

### Phase 3: Resolve Ambiguities

Present all "clarification needed" comments to the user with full context (file, line number, comment text). For each one, explicitly ask: "What should be changed?"

**Do not proceed until the user has answered every ambiguous comment.**

### Phase 4: Present the Change Plan

Show the full plan for every code change:

**For must-fix and should-fix comments:**
- File path and line numbers
- Current code (1-2 lines context)
- Proposed change
- Rationale (from the comment or context)

**For discussion/question comments:**
- The question or feedback
- Proposed reply

Ask the user: "Should I proceed with these changes?"

**Wait for explicit user confirmation before making any edits.**

### Phase 5: Apply Code Fixes

For each approved code change:

1. **Read the full file first** — never patch blindly from the comment
2. **Make the minimal change** that addresses the comment — no scope creep
3. **Keep edits independent** — apply changes one at a time to avoid conflicts
4. **Do not refactor or reformat** outside the scope of the comment
5. **Verify the change is applied** by reading the relevant lines after the edit

Example workflow for a single change:

```bash
cat src/auth.ts          # read file
                         # make the change (using Edit tool)
git diff src/auth.ts     # then verify
```

### Phase 6: Verify Changes

After all code changes are applied, verify:

1. File syntax is valid (no broken imports, missing brackets, etc.)
2. Changes align with the comment intent
3. No unintended side effects (test imports, unused variables, etc.)

Use `git diff` to review all changes at once:

```bash
git diff
```

### Phase 7: Draft Replies

For every comment (must-fix, should-fix, clarification, discussion, praise), draft a reply:

**For applied changes (must-fix, should-fix):**
- Confirm what was changed, factually and briefly
- Example: "Done — extracted into a separate function `validateUser()` in `auth.ts:45-60`."

**For clarifications now resolved:**
- Brief explanation of the decision
- Example: "Using setTimeout here to avoid race conditions with pending state updates."

**For questions/discussion:**
- Answer directly without over-explaining
- Keep it professional and concise
- Example: "Good catch — I'll verify the performance impact in the staging environment."

**For praise/acknowledgements:**
- Brief, genuine acknowledgement
- Example: "Thanks for the review!"

**Important:** Do not use filler phrases like "Great point!", "Thanks for catching that!", "Absolutely!", "Looking forward to your feedback!" These add noise without substance.

### Phase 8: Present Reply Drafts

Show all draft replies to the user for review. Ask: "Should I post these replies?"

**Wait for user approval before posting anything.**

### Phase 9: Post Replies

Once approved, post each reply to its corresponding comment thread:

```bash
gh pr comment <PR> --in-reply-to <COMMENT_ID> --body "<reply text>"
```

Or use the GitHub API directly if the command-line interface differs:

```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -f body="<reply text>"
```

Confirm which replies were posted successfully.

## Important Principles

- **Never guess ambiguity resolution** — always ask the user explicitly
- **Confirm changes factually** — "Done — added null check at line 42" not "Fixed the issue"
- **One file at a time** — apply changes sequentially to avoid merge conflicts
- **No scope creep** — fix the comment, nothing more
- **Professional tone** — direct, factual, no corporate pleasantries
- **Do not resolve threads** — let the reviewer do that after they read your replies
- **Do not push or open PRs** — only apply code and draft replies

## Examples

### Positive Trigger

User: "address the review comments and fix the code feedback on PR #42"

Expected behavior: Fetch comments from PR #42, triage into must-fix / should-fix / clarification / discussion, present triage table, wait for user input, apply fixes after confirmation, draft replies.

---

User: "fix the PR feedback on my current branch"

Expected behavior: Detect PR from current branch, fetch comments, triage, present plan, apply approved changes, draft replies.

---

User: "respond to the code review on https://github.com/org/repo/pull/99"

Expected behavior: Fetch comments from PR #99, triage, resolve any ambiguities with user input, apply fixes and draft replies after confirmation.

### Non-Trigger

User: "review this pull request #123"

Expected behavior: Do not use pr-comments-address. The user wants to review a PR, not address existing feedback. Use a PR review workflow instead.

---

User: "create a pull request for my branch"

Expected behavior: Do not use pr-comments-address. The user wants to create a new PR, not address comments on an existing one.

## Troubleshooting

### Skill Does Not Trigger

- Error: The skill is not selected when user asks to address PR comments.
- Cause: Request wording does not match trigger phrases (used "review PR" or "commit changes" instead of "address review", "fix feedback", "handle comments").
- Solution: Rephrase with explicit keywords: "address review comments", "fix PR feedback", "respond to review feedback" and retry.

### No PR Found for Current Branch

- Error: `gh pr view` returns no PR for the current branch.
- Cause: Current branch does not have an open PR, or branch has not been pushed.
- Solution: Provide PR number or URL explicitly, or push the branch and create a PR first using agent-pr-creator.

### No Unresolved Comments Found

- Error: The PR has no open review comments.
- Cause: All comments have already been resolved, or the PR has no reviews.
- Solution: Inform the user that there are no pending comments. If they expected comments, verify they specified the correct PR.

### GitHub CLI Not Authenticated

- Error: `gh` commands fail with "not authenticated" or token errors.
- Cause: GitHub CLI is not logged in or auth token has expired.
- Solution: Run `gh auth login` to authenticate, then retry the skill.

### Ambiguous Comment Intent

- Error: Cannot determine what the reviewer wants changed.
- Cause: Comment is vague, subjective, or depends on context not visible in the comment thread.
- Solution: Present the comment to the user with full context (file, line, code snippet) and ask explicitly what change they want to make. Do not assume intent.
