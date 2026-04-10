# QA Agent Personalities & Workflow

Spawn specialized QA agents that test your application in parallel — happy path UI flows, adversarial edge cases, and custom integration tests — then automatically triage bugs and generate reports.

## How it works

```
PR Ready → /qa-orchestrator spawns agents in parallel
  ├── Happy Path Agent    → Playwright browser flows    → Bug Report
  ├── Chaos Monkey Agent  → Adversarial API testing     → Bug Report
  └── Custom Agent(s)     → Project-specific tests      → Bug Report

Bug Reports:
  ├── Bugs found → Bug Fixer Agent (isolated branch) → Verify fix → Merge
  └── No bugs    → Merge
```

The **orchestrator** (`/qa-orchestrator`) coordinates everything: reads your test plan, selects the right agents, spawns them in parallel, collects results, offers to auto-fix bugs, and writes a structured QA report.

## Quick start

### 1. Install the skills

**From the registry (once published):**

```bash
npx skills add ravnhq/ai-toolkit -s qa-orchestrator
npx skills add ravnhq/ai-toolkit -s qa-happy-path
npx skills add ravnhq/ai-toolkit -s qa-chaos-monkey
npx skills add ravnhq/ai-toolkit -s qa-bug-fixer
npx skills add ravnhq/ai-toolkit -s qa-personality-builder
```

**Local development (from a cloned ai-toolkit repo):**

```bash
mkdir -p .claude/skills
cp -r path/to/ai-toolkit/skills/qa/qa-orchestrator   .claude/skills/
cp -r path/to/ai-toolkit/skills/qa/qa-happy-path     .claude/skills/
cp -r path/to/ai-toolkit/skills/qa/qa-chaos-monkey   .claude/skills/
cp -r path/to/ai-toolkit/skills/qa/qa-bug-fixer      .claude/skills/
cp -r path/to/ai-toolkit/skills/qa/qa-personality-builder .claude/skills/
```

### 2. Set up your project

Run the setup script to generate config files:

```bash
bash .claude/skills/qa-orchestrator/assets/install.sh
```

This creates:

| File | Purpose | Commit? |
|------|---------|---------|
| `.qa/config.yml` | Agent config, issue tracker, personality registry | Yes |
| `.qa/test-plan.md` | Test scenarios for agents to execute | Yes |
| `.env.qa` | App URLs, test credentials, secrets | No (gitignored) |
| `.qa/reports/` | Generated QA run reports | Yes |

### 3. Configure

**`.env.qa`** — fill in your app URLs and test credentials:

```bash
QA_PORTAL_URL=https://staging.example.com
QA_API_URL=https://staging-api.example.com/api/v1
QA_TEST_USER_EMAIL=test@example.com
QA_TEST_USER_PASSWORD=testpass123
QA_AUTH_METHOD=bearer
```

**`.qa/test-plan.md`** — define what to test:

```markdown
## UI Flows (for qa-happy-path)

### Flow 1 — User Registration
- **Type**: ui
- **Steps**:
  1. Navigate to /register
  2. Fill form with valid data
  3. Click "Create Account"
- **Expected**: Redirect to dashboard, welcome message shown
- **Verify**: User appears in admin panel

## API Endpoints (for qa-chaos-monkey)

### Endpoint 1 — POST /api/users
- **Auth**: required
- **Required fields**: name, email, password
- **Constraints**: email must be unique, password min 8 chars
- **Expected success**: 201 Created
```

### 4. Run QA

In Claude Code:

```
/qa-orchestrator
```

Or with a PR scope:

```
/qa-orchestrator PR #42
```

## Skills overview

### qa-orchestrator

The conductor. Reads your test plan, selects agents, spawns them in parallel, collects results, and generates reports. Invoked via `/qa-orchestrator`.

**Modes:**
- **A — Full Run**: spawn all agents, collect results, triage, report
- **B — View Reports**: list and display previous QA reports
- **C — Re-test Failures**: re-run only failing scenarios from a previous report

**Parallelism**: agents run concurrently by default using parallel Agent tool calls (native Claude Code capability). If Forge MCP is available, agents get dedicated terminals with live monitoring.

### qa-happy-path

Drives the app UI through positive user journeys using Playwright browser automation. Navigates pages, fills forms, clicks buttons, takes snapshots after every action, and verifies network requests.

**Requires**: [Playwright MCP](https://github.com/anthropics/mcp-playwright)

```bash
claude mcp add playwright -- npx @anthropic-ai/mcp-playwright
```

**Rules enforced:**
- Read test plan before testing (`std-test-plan`)
- Snapshot after every action (`ui-snapshot`)
- Verify network requests after submits (`ui-network`)
- Report bugs to configured tracker (`rpt-bug`)

### qa-chaos-monkey

Adversarial tester that systematically tries to break your API. For every endpoint in the test plan, it runs through:

| Category | What it tests |
|----------|---------------|
| Security boundaries | Missing auth, expired tokens, cross-user access |
| Input validation | SQL injection, XSS, boundary values, missing fields |
| Deduplication | Same request twice, same ID different body |
| Graceful degradation | Non-existent resources, invalid states |
| Race conditions | Conflicting operations within 1 second |
| Malformed requests | Bad JSON, missing Content-Type, empty body |

Every 500 error on bad input is flagged as a bug. Auth failures are always HIGH or BLOCKER.

### qa-bug-fixer

Receives bug reports and implements surgical fixes. Reads the codebase first, understands the root cause, and applies the smallest possible change. Works with any tech stack — adapts to your project's conventions.

**Constraints:**
- Fix only what's broken, nothing else
- Never refactor surrounding code
- Never add dependencies without approval
- Report which tests to run, don't run them

### qa-personality-builder

Guided builder for creating custom QA agents. Invoked via `/qa-create-personality`. Walks through:

1. **Specialty** — what kind of testing (webhook simulation, load testing, accessibility...)
2. **Tools** — Playwright, WebFetch, Bash, Read
3. **Test scenarios** — 3-5 specific scenarios
4. **Name** — saved as a skill in your project

Includes reference examples: Slack webhook impersonator, Stripe webhook tester.

## Issue tracker integration

The setup script auto-detects your issue tracking MCP:

| Provider | Detection | What happens |
|----------|-----------|--------------|
| Linear | `mcp__linear__save_issue` in settings | Bugs filed as Linear tickets with `[QA-AgentName]` prefix |
| GitHub Issues | `mcp__github__create_issue` in settings | Bugs filed as GitHub issues with labels |
| None | fallback | Full bug details included inline in the QA report |

Severity maps to priority: BLOCKER=1, HIGH=2, MEDIUM=3, LOW=4.

Override in `.qa/config.yml`:

```yaml
issue_tracker:
  provider: github  # or: linear, none
  github:
    repo: "your-org/your-repo"
    labels: ["bug", "qa"]
```

## QA report format

Reports are saved to `.qa/reports/YYYY-MM-DD-HHmmss-qa-report.md` with:

- **Summary** — scope, agents run, result
- **Agent Results** — full structured output per agent
- **Bugs Found** — table with severity, description, ticket URL, status
- **Bug Details** — full reproduction details (when no issue tracker)
- **Fixes Applied** — bug-fixer output if it ran
- **Verdict** — PASS or FAIL

## CI integration

Use the orchestrator in CI to gate PRs on QA results. A ready-to-use workflow is included at `skills/qa/qa-orchestrator/assets/qa-gate.yml`.

**Setup:**

1. Copy it to your project:
   ```bash
   cp .claude/skills/qa-orchestrator/assets/qa-gate.yml .github/workflows/qa-gate.yml
   ```
2. Add these secrets to your GitHub repo (`Settings → Secrets → Actions`):
   - `ANTHROPIC_API_KEY`
   - `QA_PORTAL_URL`, `QA_API_URL`
   - `QA_ADMIN_EMAIL`, `QA_ADMIN_PASSWORD`
   - `QA_TEST_USER_EMAIL`, `QA_TEST_USER_PASSWORD`

The workflow runs `/qa-orchestrator` in non-interactive mode on every PR, uploads the report as an artifact, and fails the check if the verdict is `FAIL`.

## Custom personalities

Beyond the built-in agents, you can create project-specific QA personalities for things like:

- **Webhook simulation** — Slack, Stripe, GitHub, SendGrid
- **Email verification** — check that notification emails are sent
- **File upload/download** — test binary handling and storage
- **Multi-user interactions** — test collaboration flows between users
- **Accessibility** — WCAG compliance via Playwright

Run `/qa-create-personality` or use the examples in `qa-personality-builder/references/` as starting points.

## Architecture

```
skills/qa/
├── qa-orchestrator/           # /qa-orchestrator — spawns agents, collects results, reports
│   ├── SKILL.md
│   ├── rules/                 # Spawn hierarchy, triage, report format
│   ├── references/            # Config templates (env.qa, test-plan, config.yml)
│   └── assets/                # install.sh setup script
├── qa-happy-path/             # UI flow tester (Playwright)
│   ├── SKILL.md
│   └── rules/                 # Test plan, snapshots, network, bug reporting
├── qa-chaos-monkey/           # Adversarial API tester
│   ├── SKILL.md
│   └── rules/                 # Security, input, dedup, race conditions, reporting
├── qa-bug-fixer/              # Surgical fix agent
│   ├── SKILL.md
│   └── rules/                 # Minimal change, read first, fix report
├── qa-personality-builder/    # Custom agent builder
│   ├── SKILL.md
│   ├── rules/                 # Skill structure requirements
│   └── references/            # Example personalities (Slack, Stripe)
├── bug-report-gen/            # Bug report drafting/evaluation (pre-existing)
├── test-case-gen/             # Test case generation (pre-existing)
├── test-plan-gen/             # Test plan document generation (pre-existing)
└── locators-scanner/          # Playwright locator extraction (pre-existing)
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (CLI, desktop app, or IDE extension)
- [Playwright MCP](https://github.com/anthropics/mcp-playwright) for UI testing (optional — chaos monkey and bug fixer work without it)
- An issue tracker MCP (optional — Linear, GitHub, or inline fallback)
