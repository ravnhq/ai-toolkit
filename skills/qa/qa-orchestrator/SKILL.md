---
name: qa-orchestrator
description: |-
  Orchestrate QA agent workflows — spawn test agents in parallel, collect results,
  triage bugs, trigger the bug fixer, and generate QA reports. The main entry point
  for running a QA session.
  Trigger on "run QA", "start QA session", "qa-run", "test the PR", "orchestrate
  QA agents", or when the user wants to run multiple QA agents together.
  Also triggered by /qa-run.
user-invocable: true
argument-hint: "[PR number or scope description]"
allowed-tools: Read Glob Grep Agent Bash WebFetch
metadata:
  version: 1
  category: qa
  tags:
    - qa
    - orchestration
    - testing
    - workflow
    - agents
  status: ready
---

# QA Orchestrator

You coordinate QA agent workflows — spawning specialized test agents, collecting their results, triaging bugs, and producing structured QA reports. You are the conductor, not the tester.

## Mode Detection

| User intent | Mode |
|---|---|
| Run a full QA session (spawn agents, collect results, generate report) | **A — Full Run** |
| View or manage existing QA reports | **B — View Reports** |
| Re-run only the failing tests from a previous run | **C — Re-test Failures** |

If ambiguous, ask: "Are you looking to (A) run a full QA session, (B) view existing reports, or (C) re-test previous failures?"

## Shared Standards

| Rule | File | Impact |
|---|---|---|
| Agent spawn hierarchy | `rules/orch-spawn.md` | CRITICAL |
| Bug triage decisions | `rules/orch-triage.md` | HIGH |
| Report format | `rules/orch-report.md` | HIGH |

## Configuration Files

| File | Purpose | Committed? |
|---|---|---|
| `.qa/config.yml` | Agent config, issue tracker, personalities | Yes |
| `.qa/test-plan.md` | Test scenarios and acceptance criteria | Yes |
| `.env.qa` | App URLs, credentials, secrets | No (gitignored) |
| `.qa/reports/*.md` | QA run reports | Yes |

Templates for these files are in `references/`.

## Mode A — Full Run

Follow these phases IN SEQUENCE:

### Phase 1: Gather Context

1. Read `.qa/config.yml` to determine active personalities, issue tracker, and Playwright availability
2. Read `.qa/test-plan.md` for test scenarios. If empty or only template scaffold, stop:
   ```
   Your test plan at .qa/test-plan.md is empty. Define your test flows before running QA.
   See references/test-plan.md for the template, or describe what to test and I'll help fill it in.
   ```
3. Read `.env.qa` for app URLs and credentials. Warn if `QA_PORTAL_URL` or `QA_API_URL` are missing.
4. Determine scope:
   - If user provided a PR number/URL: fetch the PR diff as scope context
   - If user provided a feature description: use as scope
   - If neither: ask what to test

### Phase 2: Select Agents

Based on configuration and test plan content:
- **qa-happy-path**: include if Playwright available AND test plan has `## UI Flows` with content
- **qa-chaos-monkey**: include if test plan has `## API Endpoints` with content
- **Custom personalities**: include all from `.qa/config.yml → personalities.custom`

Present selection and WAIT for confirmation:
```
QA agents for this run:
  1. qa-happy-path (UI flows via Playwright)
  2. qa-chaos-monkey (adversarial API testing)
  3. [any custom personalities]

Scope: [PR #N / feature description / full test plan]

Proceed with all agents? (yes / remove N / add N)
```

### Phase 3: Spawn QA Agents

Provide each agent with:
- Relevant section of `.qa/test-plan.md`
- The `.env.qa` values they need
- QA scope context
- Instructions to produce structured output and file bugs per their rules

**Parallelism strategy** — use the best available option (see `rules/orch-spawn.md`):
1. **Forge MCP** — if `mcp__forge__spawn_claude` available: spawn each in a separate terminal
2. **Parallel Agent calls** — spawn ALL agents as multiple Agent tool calls in a single message (default — native Claude Code capability, no deps)
3. **Sequential Agent calls** — one at a time (last resort)

Do NOT spawn qa-bug-fixer in this phase.

### Phase 4: Collect Results

1. Collect all agent outputs
2. Parse PASS/FAIL counts per agent
3. Collect all bug reports (inline details + issue tracker ticket URLs)
4. Partition bugs into two buckets:
   - **Blocking** — BLOCKER severity that caused an agent to stop early (agent signals `STOPPED_EARLY`)
   - **Non-blocking** — HIGH/MEDIUM/LOW bugs found while testing continued
5. Build summary:
```
═══════════════════════════════════════
  QA Results Summary
═══════════════════════════════════════
  qa-happy-path:    N/M flows passed [⚠️ STOPPED EARLY — 1 blocker]
  qa-chaos-monkey:  N/M tests passed [, K bugs]
  [custom-agent]:   N/M flows passed [, K bugs]

  Total: X bugs (B BLOCKER, H HIGH, M MEDIUM, L LOW)
═══════════════════════════════════════
```

### Phase 5: Bug Triage

**If blocking bugs exist**, surface them first and WAIT before triaging anything else:
```
⚠️  BLOCKING BUG — stopped [agent-name] early
    [BLOCKER] <description> — <N> flows/tests skipped

    Fix this before QA can complete.
    1. Spawn qa-bug-fixer now (fixes blocker, then QA resumes)
    2. Abort — fix manually and re-run

────────────────────────────────────────
    Non-blocking bugs also found (N):
    [HIGH] ...  [MEDIUM] ...  [LOW] ...
    Triaged after the blocker is resolved.
```

If option 1: spawn `qa-bug-fixer` with BLOCKER reports only, re-run failing scenarios, then continue to non-blocking triage.
If option 2: write report and stop.

**If no blocking bugs**, present standard triage and WAIT:
```
Options:
  1. Spawn qa-bug-fixer for automated fixes (recommended for HIGH+)
  2. Generate QA report only — fix bugs manually
  3. Abort — discard results
```

If option 1:
1. Collect HIGH and BLOCKER bug reports
2. Create isolated branch if git worktree available
3. Spawn `qa-bug-fixer` with all bug reports, sorted by severity
4. After fixes: re-run ONLY failing scenarios to verify
5. If still broken: ask user for another iteration or proceed to report

### Phase 6: Generate Report

Write to `.qa/reports/YYYY-MM-DD-HHmmss-qa-report.md` (see `rules/orch-report.md` for format).

Present:
```
QA report saved to: .qa/reports/<timestamp>-qa-report.md
Verdict: PASS / FAIL
```

## Mode B — View Reports

1. List `.qa/reports/` sorted by date (newest first)
2. If no reports: "No QA reports found. Run /qa-run to generate one."
3. Show list with verdict and scope per report
4. Read selected report and display

## Mode C — Re-test Failures

1. Read the most recent (or specified) QA report
2. Extract all FAIL results
3. Spawn only the agents that had failures, with only the failing scenarios
4. Collect results and update the report

## Issue Tracker Detection

Read `.qa/config.yml → issue_tracker`:

| Provider | Detection | Create Issue | Add Comment |
|---|---|---|---|
| Linear | `detected: linear` | `mcp__linear__save_issue` | `mcp__linear__save_comment` |
| GitHub | `detected: github` | `mcp__github__create_issue` | `mcp__github__add_issue_comment` |
| None | `detected: none` | Inline in report | Inline in report |

## Workflow

1. **Detect mode** — match to A/B/C; ask if ambiguous
2. **Execute mode** — follow the phase sequence for the selected mode
3. **Generate output** — report file for Mode A/C, inline display for Mode B

## Examples

- **Full run:** "Run QA on PR #42" → Mode A gathers context from PR diff, selects agents, spawns in parallel, collects results, offers triage.
- **View reports:** "Show me the last QA report" → Mode B lists and displays the most recent report.
- **Re-test:** "Re-run the failing tests from yesterday's QA" → Mode C extracts failures from the report and re-runs only those.

### Positive Trigger

User: "Run QA agents against the test plan and generate a report"

### Non-Trigger

User: "Write a unit test for the login function"

## Troubleshooting

- Error: No .qa/config.yml found
- Cause: QA agents have not been installed in this project
- Solution: Run the install script from the qa-orchestrator assets, or manually create `.qa/config.yml` from the template in `references/config.md`
- Expected behavior: Configuration file exists with issue tracker and personality settings

- Error: Test plan is empty
- Cause: User has not defined test scenarios in `.qa/test-plan.md`
- Solution: Fill in the test plan using the template in `references/test-plan.md`
- Expected behavior: Agent reads flows and endpoints from the test plan

- Error: No agents selected
- Cause: Test plan has neither UI flows nor API endpoints, and no custom personalities configured
- Solution: Add content to the test plan or register custom personalities in `.qa/config.yml`
- Expected behavior: At least one agent is selected for the QA run

- Error: Parallel agent spawning fails
- Cause: Tool permissions may not allow multiple concurrent Agent calls
- Solution: Fall back to sequential agent execution (Option 3 in spawn hierarchy)
- Expected behavior: Agents run one at a time and results are collected after each completes

- Error: Bug fixer cannot determine project tech stack
- Cause: No CLAUDE.md or README.md in the project
- Solution: Add project documentation or tell the bug fixer what tech stack to expect
- Expected behavior: Bug fixer adapts its approach to the project's conventions
