---
name: eval-agent-md
description: 'Behavioral compliance testing for any CLAUDE.md or agent definition
  file. Auto-generates test scenarios from your rules, runs them via LLM-as-judge
  scoring, and reports a compliance score with per-rule pass/fail breakdown. Optionally
  improves failing rules via automated mutation loop. Use when: (1) testing whether
  your CLAUDE.md rules are actually followed, (2) evaluating an agent definition for
  role-boundary compliance, (3) dogfooding a skill''s own SKILL.md. Triggers on: "eval",
  "compliance test", "test my CLAUDE.md", "check rules", "behavioral test", "/eval-agent-md".'
metadata:
  category: assistant
  tags:
  - testing
  - compliance
  - agent-md
  - behavioral
  - meta
  - quality
  status: experimental
  version: 4
---

# eval-agent-md — Behavioral Compliance Testing

## What This Does

1. Reads a CLAUDE.md (or agent .md file)
2. Auto-generates behavioral test scenarios for each rule it finds
3. Runs each scenario via `claude -p` with LLM-as-judge scoring
4. Reports a compliance score with per-rule pass/fail breakdown
5. Optionally runs an automated mutation loop to improve failing rules

## Workflow

### Script Execution

**Always run scripts with `uv run --script`** — never invoke them directly with `python` or `python3`. The scripts declare their own dependencies via inline `# /// script` metadata, and `uv run --script` handles dependency resolution automatically with no pip install needed.

### Progress Reporting

This skill runs long operations (30s-5min per step). **Always keep the user informed:**
- Before each step, tell the user what is about to happen and roughly how long it takes
- Run all scripts via the Bash tool (never capture output) so per-scenario progress streams to the user in real time
- After each step completes, give a brief transition summary before starting the next step
- Script timeouts are computed dynamically from workload size (scenario count, runs, file length) — no manual timeout tuning needed on Bash calls

### Step 1: Locate the target file

Find the target file to test. Priority order:
0. If user passed `--self`, target is `[SKILL_DIR]/SKILL.md` — skip to confirmation below
1. If user provided a path argument (e.g., `/eval-agent-md ./CLAUDE.md`), use that
2. If a project-level CLAUDE.md exists in the current working directory, use that
3. Fall back to `~/.claude/CLAUDE.md` (user global)
4. If none found, ask the user

Read the file and confirm with the user: "I found [filename] at [path] ([N] lines). Testing this file."

### Step 2: Generate test scenarios

Tell the user: "Generating test scenarios from [filename]... this calls `claude -p --model sonnet` and typically takes 30-60 seconds."

Before running, mention whether this is a warm or cold generation run:
- Warm cache: "Scenario cache is warm, so generation may return almost immediately."
- Cold cache: "Scenario cache is cold, so this will make a fresh model call."

Run the scenario generator script bundled with this skill. **IMPORTANT: Do NOT capture output — run via the Bash tool so the user sees progress lines in real time:**

```bash
uv run --script [SKILL_DIR]/scripts/generate-scenarios.py [TARGET_FILE]
# For SKILL.md files, add --skill for workflow-aware scenarios:
# uv run --script [SKILL_DIR]/scripts/generate-scenarios.py --skill [TARGET_FILE]
# For self-testing (implies --skill):
# uv run --script [SKILL_DIR]/scripts/generate-scenarios.py --self
```

The script auto-detects the repository name from git and saves to `/tmp/eval-agent-md-<repo>-scenarios.yaml` (e.g., `/tmp/eval-agent-md-my-project-scenarios.yaml`). Override with `--repo-name NAME` or `-o PATH`.
It also reuses an exact-input scenario cache by default; pass `--no-scenario-cache` to force fresh generation. `--no-cache` remains as a compatibility alias.

After generation, read the output file and show the user a summary:
- How many scenarios were generated
- Which rules each scenario tests
- A brief preview of each scenario's prompt

Ask the user: "Generated [N] test scenarios. Ready to run? (Or edit/skip any?)"

### Step 3: Run behavioral tests

Tell the user: "Running [N] scenarios x [runs] run(s) against [model]... each scenario calls `claude -p` twice (subject + judge), so this takes a few minutes. You'll see per-scenario results as they complete."

Also summarize the work budget before starting:
- active workers (auto defaults to a laptop-safe cap)
- estimated subject calls
- estimated judge calls
- whether subject-response cache is warm or cold

**IMPORTANT: Do NOT capture output — run via the Bash tool so the user sees per-scenario progress (`[1/N] scenario_id... PASS/FAIL (Xs)`) in real time:**

```bash
uv run --script [SKILL_DIR]/scripts/eval-behavioral.py \
  --scenarios-file /tmp/eval-agent-md-<repo>-scenarios.yaml \
  --claude-md [TARGET_FILE] \
  --runs 1 \
  --model sonnet
```

Options the user can control:
- `--runs N` — runs per scenario for majority vote (default: 1, recommend 3 for reliability)
- `--model MODEL` — model for test subject (default: sonnet)
- `--compare-models` — run across haiku/sonnet/opus and show comparison matrix
- `--workers N` — opt into higher concurrency than the safe default
- `--no-judge-cache` — force fresh judge verdicts instead of reusing exact-input cache entries
- `--no-subject-cache` — force fresh subject responses instead of exact-input cache reuse

### Step 4: Report results

Print a compliance report:

```
## Compliance Report — [filename]

Score: 8/10 (80%)

| Scenario | Rule | Verdict | Evidence |
|----------|------|---------|----------|
| gate1_think | GATE-1 | PASS | Lists assumptions before code |
| ... | ... | ... | ... |

### Failing Rules
- [rule]: [what went wrong] — suggested fix: [brief suggestion]
```

### Step 5: Improve (optional)

If the user says "improve", "fix", or passed `--improve`:

Tell the user: "Starting mutation loop (dry-run) — this iteratively generates wording fixes for failing rules and A/B tests them. Each iteration takes 1-2 minutes."

For performance, explain that scoped mutation checks now reuse the baseline already computed for the current content and only re-evaluate the mutated candidate for the targeted scenario before any full-suite validation.

**IMPORTANT: Do NOT capture output — run via the Bash tool so the user sees iteration progress in real time:**

```bash
uv run --script [SKILL_DIR]/scripts/mutate-loop.py \
  --target [TARGET_FILE] \
  --scenarios-file /tmp/eval-agent-md-<repo>-scenarios.yaml \
  --max-iterations 3 \
  --runs 3 \
  --model sonnet
```

This is always dry-run by default. Show the user each suggested mutation and ask before applying.

## Arguments

Parse the user's `/eval-agent-md` invocation for these common options:

- `[path]` — target file (positional, e.g., `/eval-agent-md ./CLAUDE.md`)
- `--improve` — run mutation loop after testing
- `--runs N` — runs per scenario (default: 1, recommend 3 for reliability)
- `--model MODEL` — model for test subject (default: sonnet)
- `--self` — test this skill's own SKILL.md (implies `--skill`)
- `--skill` / `--agent` — hint the target type for better scenario generation

See `references/script-reference.md` for the full flag reference (caching, workers, compare-models, timeouts).

## Examples

### Positive Trigger

User: "Run compliance tests against my CLAUDE.md to check if all rules are being followed."

Expected behavior: Use `eval-agent-md` workflow — locate the CLAUDE.md, generate test scenarios, run behavioral tests, and report compliance results.

### Non-Trigger

User: "Add a new linting rule to our ESLint config."

Expected behavior: Do not use this skill. Choose a more relevant skill or proceed directly.

## Troubleshooting

### Scenario Generation Fails

- Error: `generate-scenarios.py` exits with non-zero status or produces empty output.
- Cause: The target CLAUDE.md has no detectable rules or structured sections for the generator to parse.
- Solution: Ensure the target file contains clearly structured rules (headings, numbered items, or labeled sections). Try a simpler file first to confirm the script works.

### Low Compliance Score Despite Correct Rules

- Error: Multiple scenarios report FAIL even though the CLAUDE.md rules look correct.
- Cause: Single-run mode (`--runs 1`) is susceptible to LLM variance. The model may not follow rules consistently in a single sample.
- Solution: Re-run with `--runs 3` for majority-vote scoring to reduce noise.

### Scripts Not Found

- Error: `No such file or directory` when running skill scripts.
- Cause: The skill directory path is not resolving correctly, or scripts lack execute permissions.
- Solution: Verify the skill is installed at the expected path and run `chmod +x` on the scripts in the `scripts/` directory.

## Reference Guides

- **Full script reference**: `references/script-reference.md` — all flags, caching strategy, performance notes
