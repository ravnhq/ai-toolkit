# Ravn AI Toolkit

<p align="center">
  <img src="docs/assets/images/corvus.png" alt="Corvus" width="200" />
</p>

[![Skills Quality](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml/badge.svg)](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml)

Rule packs for React, TypeScript, tRPC, Drizzle, iOS, and more. Works with Claude Code, Cursor, Codex, and OpenCode. **36 skills** organized by role.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/ravnhq/ai-toolkit/main/install.sh | bash
```

No git or Node.js required. Downloads a self-contained binary.

<details>
<summary>Build from source</summary>

Requires [git](https://git-scm.com/), [Node.js ≥18](https://nodejs.org/), npm.

```bash
git clone https://github.com/ravnhq/ai-toolkit.git
cd ai-toolkit/cli-ts && npm install && npm run build && npm install -g .
```

</details>

<details>
<summary>Use npx instead of corvus</summary>

```bash
npx skills add ravnhq/ai-toolkit -s core-coding-standards
npx skills add ravnhq/ai-toolkit -l   # list all skills
npx skills update                      # upgrade installed skills
```

</details>

### Claude Code Native

Install skills directly in Claude Code without corvus:

```bash
/plugin marketplace add ravnhq/ai-toolkit
/plugin install tech-react
/plugin install tech-drizzle design-frontend
```

<details>
<summary>Local development</summary>

```bash
# Add local repo as marketplace
/plugin marketplace add .

# Install skills from local
/plugin install core-coding-standards
```

</details>

### Corvus CLI Commands

```bash
corvus install                         # interactive skill browser
corvus install tech-react tech-drizzle # install specific skills
corvus install --recipe fullstack-ts   # install stack recipe

corvus search testing                  # find skills by keyword
corvus status                          # show installed skills
corvus update                          # upgrade all skills
corvus remove tech-vitest              # uninstall a skill
corvus doctor                          # health check
```

### Target Flags

```bash
# Project-level (default: Claude Code)
corvus install --claude tech-react     # .claude/rules
corvus install --cursor tech-react     # .cursor/rules
corvus install --opencode tech-react   # .opencode/rules
corvus install --codex tech-react      # .codex/rules

# Global (applies to all projects)
corvus install --global-claude lang-typescript   # ~/.claude/rules
corvus install --global-cursor lang-typescript   # ~/.cursor/rules
```

## Skills

```
skills/
├── universal/     # Global standards
├── frontend/      # Web UI, components, accessibility
├── backend/       # APIs, services, architecture
├── database/      # ORMs, schemas, queries
├── mobile/        # iOS, Android
├── testing/       # Test patterns
├── qa/            # Test automation, bug reports
├── cli/           # Command-line tools
└── assistant/     # Agent workflows
```

### Universal

| Skill | Description |
|-------|-------------|
| `core-coding-standards` | KISS, DRY, clean code, code review |
| `lang-typescript` | Strict TypeScript: no `any`, discriminated unions |
| `ts-linter` | Strict ESLint setup for TypeScript |

### Frontend

| Skill | Description |
|-------|-------------|
| `platform-frontend` | State, components, data fetching (framework-agnostic) |
| `tech-react` | React components, hooks, rendering |
| `design-frontend` | Layout, responsive, Tailwind tokens |
| `design-accessibility` | WCAG AA, ARIA, keyboard nav |
| `figma-to-react-components` | Figma → React with design tokens |

### Backend

| Skill | Description |
|-------|-------------|
| `platform-backend` | API design, error handling, validation |
| `tech-trpc` | tRPC routers, procedures, VSA |

### Database

| Skill | Description |
|-------|-------------|
| `platform-database` | SQL design, query optimization, migrations |
| `tech-drizzle` | Drizzle ORM: schemas, relations |

### Mobile

| Skill | Description |
|-------|-------------|
| `tech-android` | Kotlin, Jetpack Compose, architecture |
| `swift-concurrency` | Swift async/await, actors, Sendable |
| `localize-ios` | iOS localization: strings, plurals |
| `liquid-glass-ios` | Apple Liquid Glass (iOS 26+) |

### Testing

| Skill | Description |
|-------|-------------|
| `platform-testing` | Test structure, mocking boundaries |
| `tech-vitest` | vi.mock, vi.fn, fake timers, MSW |

### QA

| Skill | Description |
|-------|-------------|
| `bug-report-gen` | Draft and normalize bug reports |
| `test-case-gen` | Generate and audit test cases |
| `test-plan-gen` | Test plan documents from interviews |
| `locators-scanner` | Extract page locators for Playwright/Cypress |

### CLI

| Skill | Description |
|-------|-------------|
| `platform-cli` | Commands, flags, output formatting |

### Assistant

| Skill | Description |
|-------|-------------|
| `promptify` | Transform requests into precise prompts |
| `agent-add-rule` | Add rules to project agent config |
| `agent-init-deep` | Nested CLAUDE.md for progressive disclosure |
| `agent-skill-creator` | Create new skills |
| `agent-pr-creator` | Create PRs from git diffs |
| `rewrite-commit-history` | Clean conventional commits |
| `eval-agent-md` | Behavioral compliance testing for CLAUDE.md |
| `parallel` | Run tasks in background sub-agents |
| `grill-me` | Interview you about a plan |
| `pr-comments-address` | Triage and fix PR review comments |
| `transcript-notes` | Meeting transcripts → structured notes |
| `type-system-audit` | Find type-system weaknesses |
| `agent-skills-manager` | Manage skills via corvus CLI |

## Stack Recipes

| Recipe | Skills | Command |
|--------|--------|---------|
| Full-stack TypeScript | lang-typescript, tech-react, tech-trpc, tech-drizzle, tech-vitest, design-frontend | `corvus install --recipe fullstack-ts` |
| iOS / Swift | swift-concurrency, liquid-glass-ios | `corvus install --recipe ios-swift` |
| Backend API | lang-typescript, tech-trpc, tech-drizzle, platform-testing | `corvus install --recipe backend-api` |

## Team Sync

corvus tracks skill choices in `.corvusrc`:

```bash
corvus install tech-react tech-drizzle
corvus gitignore                       # add skill paths to .gitignore
git add .corvusrc && git commit -m "add AI skills config"

# Teammates clone and sync
corvus sync
```

**Project vs global:** `.corvusrc` is only for project-level installs. Global installs (`--global-*`) are stored in `~/.corvus/config` and don't touch your repo.

## Versioning

Each skill is versioned independently with a build number. No single toolkit version.

```bash
# Latest build (default)
npx skills add ravnhq/ai-toolkit -s core-coding-standards

# Pin to specific build
npx skills add https://github.com/ravnhq/ai-toolkit/tree/skill-core-coding-standards-b12 -s core-coding-standards
```

`npx skills update` upgrades all skills unless pinned. See `docs/skill-versioning.md`.

## Contributing

### Skill Structure

```
skills/[category]/[name]/
├── SKILL.md              # Manifest with YAML frontmatter
├── rules/                # Rule files (optional)
│   ├── _sections.md      # Section definitions + impact levels
│   └── [prefix]-*.md     # Individual rules (kebab-case)
├── references/           # Reference docs (optional)
├── scripts/              # Executable helpers (optional)
└── assets/               # Templates, images, fonts (optional)
```

Categories: `universal`, `frontend`, `backend`, `database`, `mobile`, `testing`, `qa`, `cli`, `assistant`.

### Validation

```bash
ruby scripts/skills_audit.rb      # validate structure and marketplace sync
ruby scripts/skills_harness.rb    # run test harness
```

### Workflow

1. Create or edit a skill in `skills/<category>/<name>/`
2. Run `ruby scripts/skills_audit.rb` locally
3. Open PR to `main`
4. CI validates, bumps versions, publishes releases on merge

## Blog

[Ravn AI Toolkit Blog](https://ravnhq.github.io/ai-toolkit/) — tips, guides, and deep dives on AI-assisted development.
