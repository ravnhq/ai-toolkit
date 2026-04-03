---
name: pr-comments-address
description: Reads open review comments from a GitHub PR, triages them, applies code
  fixes, and drafts reply messages. Use when user wants to address PR comments, says
  'address review comments', 'fix PR feedback', 'handle PR comments', 'respond to
  review', or mentions addressing code review feedback on a pull request.
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
  version: 4
---

Address review comments on the following PR: $ARGUMENTS

## Workflow

### Step 1: Resolve the PR

If `$ARGUMENTS` is provided, use it directly as the PR number or URL. Otherwise, detect the PR from the current branch:

```bash
gh pr view --json number,url,title
```

If no PR is found for the current branch, stop and ask the user to provide a PR number or URL.

If `CLAUDE.md` or `.claude/rules/` exist in the repo, read and follow them. If they are absent, skip silently and apply general best practices.

### Step 2: Fetch PR Comments

Fetch the PR comments using the GitHub CLI:

```bash
gh pr view <PR> --comments --json reviews,comments,reviewThreads
```

Read the output carefully. Identify every unresolved review comment — inline code comments and top-level review comments.

### Step 3: Triage Comments

Enter plan mode. Do NOT make any changes yet. Categorize every comment into one of:

- **Clear fix** — the required change is unambiguous
- **Ambiguous** — the intent or correct solution is unclear
- **Discussion only** — no code change needed, just a reply (e.g. questions, praise, acknowledgements)

### Step 4: Present Triage and Resolve Ambiguity

Present the comment triage to the user and stop. Show the full table, then surface every ambiguous comment with its file location and ask explicitly what change should be made. Do not proceed until the user has answered every ambiguous comment.

### Step 5: Present the Confirmed Plan

Show what you are about to change for every clear-fix and now-clarified comment. Ask the user to confirm before touching any file. Wait for explicit user confirmation. Do not apply any changes until the user says yes.

### Step 6: Apply Code Fixes

Apply code fixes for all clear-fix and clarified comments:

- Read the full file before editing — never patch blindly from the comment alone
- Make the minimal change that addresses the comment
- Do not refactor, reformat, or improve code outside the scope of the comment
- Do not fix multiple comments in a single edit if they touch the same file — apply them one at a time to avoid conflicts

### Step 7: Draft Replies

Draft a reply for every comment (clear fix, ambiguous, and discussion-only):

- For fixed comments: confirm what was changed, briefly
- For discussion-only comments: write a natural, concise acknowledgement or answer
- Keep replies short and professional — no filler phrases like "Great point!" or "Thanks for the feedback!"
- Write in first person as the PR author

### Step 8: Present Reply Drafts

Present the reply drafts to the user for review. Wait for confirmation or edits from the user before posting anything.

### Step 9: Post Replies

Post the replies using the GitHub CLI once the user approves:

```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -f body="<reply text>"
```

Post each reply to its corresponding comment thread.

## Important

- Never guess at the intent of an unclear comment — always surface it with full context and ask explicitly
- Confirm changes factually: "Done — extracted into a separate hook."
- Answer questions directly without over-explaining
- For subjective comments where you disagree: draft a reply that opens a dialogue rather than blindly accepting
- Never use filler phrases: "Great catch!", "Thanks for the feedback!", "Absolutely!"
- Do not resolve comment threads — let the reviewer do that
- Do not push commits or open new PRs
- Do not change files unrelated to a review comment

## Examples

### Positive Trigger

User: "address the review comments and fix the code feedback on PR #42"

Expected behavior: Use `pr-comments-address` to fetch comments from PR #42, triage them into clear fix / ambiguous / discussion-only, present the triage table, and wait for user input before making changes.

---

User: "fix the PR feedback on my current branch"

Expected behavior: Use `pr-comments-address` to detect the PR from the current branch via `gh pr view`, fetch all unresolved review comments, and present the triage for user confirmation.

---

User: "respond to the code review on https://github.com/org/repo/pull/99"

Expected behavior: Use `pr-comments-address` with the provided PR URL, fetch comments, triage, apply fixes after confirmation, and draft replies for user approval before posting.

### Non-Trigger

User: "review this pull request #123"

Expected behavior: Do not use `pr-comments-address`. The user wants to review a PR, not address existing comments. Use a PR review workflow instead.

---

User: "create a pull request for my branch"

Expected behavior: Do not use `pr-comments-address`. The user wants to create a new PR, not address review comments on an existing one.

## Troubleshooting

### Skill Does Not Trigger

- Error: The skill is not selected when the user asks to address PR comments.
- Cause: Request wording does not match the description trigger conditions.
- Solution: Rephrase with explicit keywords like "address review comments", "fix PR feedback", or "handle PR comments" and retry.

### No PR Found for Current Branch

- Error: `gh pr view` returns no PR for the current branch.
- Cause: The current branch does not have an open PR, or the branch has not been pushed.
- Solution: Provide the PR number or URL explicitly as an argument, or push the branch and create a PR first.

### No Unresolved Comments

- Error: The PR has no unresolved review comments to address.
- Cause: All comments have already been resolved, or the PR has no review comments.
- Solution: Inform the user that there are no pending comments. If they expect comments, suggest checking that the correct PR was targeted.

### GitHub CLI Not Authenticated

- Error: `gh` commands fail with authentication errors.
- Cause: The GitHub CLI is not logged in or the token has expired.
- Solution: Run `gh auth login` to authenticate, then retry the skill.
