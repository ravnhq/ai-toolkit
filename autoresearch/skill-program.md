# autoresearch: skill optimization

Autonomous research loop for improving AI skill effectiveness. Adapted from Karpathy's autoresearch pattern (trevin-creator/autoresearch-mlx). The agent iteratively edits a skill's files, scores them, and keeps or reverts each change via git.

## Setup

Work with the user to:

1. **Agree on a target skill and run tag**: e.g., skill `transcript-notes`, tag `mar21`.
2. **Create the branch**: `git checkout -b autoresearch/<tag>` from current HEAD.
3. **Read the target skill**: Read every file in the skill directory — `SKILL.md`, `rules/*.md`, `references/*`, etc.
4. **Read the scoring harness**: `scripts/skill_score.rb` — understand how the composite 0-100 score works (trigger 30, functional 40, performance 20, audit 10).
5. **Establish baseline**: Run `ruby scripts/skill_score.rb <path-to-SKILL.md>` and record the score.
6. **Initialize results.tsv**: Create `autoresearch/results.tsv` with header and baseline:
   ```
   commit	score	status	description
   <hash>	<score>	baseline	initial state
   ```
7. **Confirm and go**: Show the baseline score and begin.

## Experimentation

Each experiment is one atomic improvement to the target skill.

**What you CAN edit:**
- The target skill's `SKILL.md` (description, workflow, examples, troubleshooting sections)
- The target skill's `rules/*.md` files (clarity, examples, impact levels)
- The target skill's `rules/_sections.md` (section organization)

**What you CANNOT edit:**
- `scripts/skill_score.rb` — the evaluation harness is read-only
- `scripts/skills_harness.rb` — the underlying harness is read-only
- `scripts/skills_audit.rb` — the audit script is read-only
- `marketplace.json` — registry is read-only during experiments
- Any file outside the target skill directory and `autoresearch/`

**The goal: get the highest skill score (max 100).** When the score is already 100, shift to qualitative improvements — better examples, clearer rules, more precise trigger language — and verify the score stays at 100 (no regressions).

## The Loop

```
LOOP:
  1. THINK: Review current skill state. Identify one specific improvement.
     Ideas: sharpen trigger examples, add missing sections, improve rule
     clarity, fix formatting, tighten description keywords, add
     troubleshooting entries, improve code examples.

  2. EDIT: Make the change. Keep each experiment focused on ONE idea.

  3. COMMIT: Stage only the target skill files.
     git add skills/<category>/<name>/
     git commit -m "experiment: <short description>"

  4. MEASURE: Run the scoring harness.
     ruby scripts/skill_score.rb skills/<category>/<name>/SKILL.md

  5. REGRESSION CHECK: Run the full harness + audit to ensure no breakage.
     ruby scripts/skills_harness.rb
     ruby scripts/skills_audit.rb

  6. DECIDE:
     - If score improved (or stayed at 100 with qualitative improvement)
       AND no regressions → KEEP
     - If score dropped OR regressions introduced → REVERT

  7. RECORD: Append to autoresearch/results.tsv:
     <commit_hash>\t<score>\t<keep|revert>\t<description>

  8. APPLY DECISION:
     - KEEP: git add autoresearch/results.tsv && git commit --amend --no-edit
     - REVERT: git reset --hard HEAD~1
       (then still log the revert in results.tsv on the current HEAD)

  9. CONTINUE: Go to step 1. Never stop, never ask. Run until interrupted.
```

## Improvement Strategies

When score is below 100, prioritize by weight:

1. **Functional (40pts)**: Add missing sections — Workflow, Examples, Troubleshooting. Use exact `- Error:` / `- Cause:` / `- Solution:` / `Expected behavior:` format.
2. **Trigger (30pts)**: Ensure positive trigger prompt has strong keyword overlap with description. Non-trigger prompt should have weak overlap.
3. **Performance (20pts)**: Keep body under 500 lines, 5000 words, description under 1024 chars.
4. **Audit (10pts)**: Fix structural issues — kebab-case name, name-folder match, metadata version.

When score is 100, improve quality without regression:

- Sharpen rule examples (more realistic code, clearer incorrect/correct contrast)
- Improve trigger discrimination (wider gap between positive and negative prompts)
- Tighten description (fewer words, stronger signal)
- Add edge cases to troubleshooting
- Improve rule `Why it matters` explanations

## Constraints

- **Scope**: Only edit files within the target skill directory.
- **No new dependencies**: Work with existing tooling only.
- **Simplicity**: All else being equal, simpler is better. Remove unnecessary complexity.
- **Format compliance**: Follow the exact format from `CLAUDE.md` guardrails — YAML frontmatter, impact levels, kebab-case filenames, correct/incorrect examples in rules.
- **One idea per experiment**: Do not bundle multiple changes. Atomic experiments make keep/revert decisions clean.

## Results Format

`autoresearch/results.tsv` — tab-separated, append-only:

```
commit	score	status	description
a1b2c3d	47.1	baseline	initial state
e4f5g6h	67.1	keep	added Workflow section
i7j8k9l	67.1	revert	tried removing troubleshooting — score unchanged but lost content
m0n1o2p	87.1	keep	added missing Error/Cause/Solution format
```
