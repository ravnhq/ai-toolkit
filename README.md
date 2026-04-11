# Ravn AI Toolkit

<p align="center">
  <img src="docs/assets/images/corvus.png" alt="Corvus" width="200" />
</p>

[![Skills Quality](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml/badge.svg)](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml)

Rule packs that teach AI coding agents (Claude Code, Cursor, etc.) how to write React, TypeScript, tRPC, Drizzle, and more. Install once, reuse across projects. **30 skills** organized by role.

## Quick Start

### Using corvus CLI

#### Option 1 — curl installer (recommended, macOS/Linux)

No git, no Node.js required. Just run this in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/ravnhq/ai-toolkit/main/install.sh | bash
```

#### Option 2 — Install from source

Requirements: [git](https://git-scm.com/), [Node.js ≥18](https://nodejs.org/), and npm.

```bash
# 1. Clone the repo
git clone https://github.com/ravnhq/ai-toolkit.git

# 2. Go into the CLI folder, install deps, build, and link globally
cd ai-toolkit/cli-ts && npm install && npm run build && npm install -g .
```

#### Verify and uninstall

```bash
# Confirm it's working
corvus --version

# Uninstall
sudo rm /usr/local/bin/corvus
```

<details>
<summary>How the binary is built (click to read more)</summary>

`bun build --compile` bundles the entire app — TypeScript source, all npm dependencies, and the Bun runtime — into a single self-contained executable. No Node.js, no npm, no `node_modules` needed on the target machine.

**Why not `npm install -g`?** That approach requires Node.js ≥18 to be installed, downloads dependencies at install time, and can break if Node.js is upgraded or `node_modules` are corrupted. The compiled binary has zero runtime dependencies.

**Same model as Claude Code.** Anthropic's official CLI (`@anthropic-ai/claude-code`) is also distributed as a pre-built native binary — `npm install -g` downloads it rather than compiling from source. corvus follows the same pattern: `install.sh` downloads a pre-built binary from the `cli-latest` GitHub Release.

To build binaries locally: `cd cli-ts && npm run build:bin`
</details>

#### Available commands

```bash
# Browse all skills interactively (TUI)
corvus install

# Install skills directly
corvus install tech-react tech-drizzle

# Install a full stack recipe in one command
corvus install --recipe fullstack-ts

# Install with explicit target flags (ordered by user base)
corvus install --claude tech-react              # project-level → .claude/rules
corvus install --cursor tech-react              # project-level → .cursor/rules
corvus install --opencode tech-react            # project-level → .opencode/rules
corvus install --codex tech-react               # project-level → .codex/rules
corvus install --global-claude lang-typescript  # global → ~/.claude/rules
corvus install --global-cursor lang-typescript  # global → ~/.cursor/rules
corvus install --global-opencode lang-typescript # global → ~/.config/opencode/rules
corvus install --global-codex lang-typescript   # global → ~/.codex/rules

# Search, preview, and manage
corvus search testing
corvus list                    # browse available skills by category
corvus info tech-vitest
corvus status
corvus update
corvus remove tech-vitest
corvus gitignore               # add .corvusrc and skill paths to .gitignore
corvus doctor                  # health check for orphaned skills, missing deps
corvus shower-thought          # random shower thought from Dave

# Shell completions (zsh, bash, and fish supported)
corvus completions --shell fish
```

### Using npx

```bash
# Install a skill into your project
npx skills add ravnhq/ai-toolkit -s core-coding-standards

# See every skill available in the toolkit
npx skills add ravnhq/ai-toolkit -l

# Upgrade all installed skills to their latest versions
npx skills update
```

## How Skills Work

### Skill Organization

Skills are grouped by role. Everything for a domain lives in one directory. Install what you need.

```
skills/
├── universal/     # Global standards, apply to all code
├── frontend/      # Web UI: architecture, components, design, accessibility
├── backend/       # Server-side: APIs, services, architecture
├── database/      # Data layer: ORMs, schemas, queries
├── mobile/        # iOS, Android, React Native
├── testing/       # Test patterns and frameworks
├── cli/           # Command-line tool patterns
└── assistant/     # Agent workflow tools
```

### Stack Recipes

With corvus, install entire stacks in one command. Dependencies are resolved automatically.

| Recipe                    | Skills                                                                             | Command                                   |
|---------------------------|------------------------------------------------------------------------------------|-------------------------------------------|
| **Full-stack TypeScript** | lang-typescript, tech-react, tech-trpc, tech-drizzle, tech-vitest, design-frontend | `corvus install --recipe fullstack-ts` |
| **iOS / Swift**           | swift-concurrency, liquid-glass-ios                                                | `corvus install --recipe ios-swift`    |
| **Backend API**           | lang-typescript, tech-trpc, tech-drizzle, platform-testing                         | `corvus install --recipe backend-api`  |

<details>
<summary>Using npx instead</summary>

**Full-stack TypeScript (React + tRPC + Drizzle)**
```bash
npx skills add ravnhq/ai-toolkit -s lang-typescript
npx skills add ravnhq/ai-toolkit -s tech-react
npx skills add ravnhq/ai-toolkit -s tech-trpc
npx skills add ravnhq/ai-toolkit -s tech-drizzle
npx skills add ravnhq/ai-toolkit -s tech-vitest
npx skills add ravnhq/ai-toolkit -s design-frontend
```

**iOS / Swift**
```bash
npx skills add ravnhq/ai-toolkit -s swift-concurrency
npx skills add ravnhq/ai-toolkit -s liquid-glass-ios
```

**Backend API only**
```bash
npx skills add ravnhq/ai-toolkit -s lang-typescript
npx skills add ravnhq/ai-toolkit -s tech-trpc
npx skills add ravnhq/ai-toolkit -s tech-drizzle
npx skills add ravnhq/ai-toolkit -s platform-testing
```
</details>

## Available Skills

### Universal

| Skill | Description |
|-------|-------------|
| `core-coding-standards` | Code quality rules: KISS, DRY, clean code, code review. Install this first. |
| `lang-typescript` | Strict TypeScript: no `any`, discriminated unions, type narrowing. |
| `ts-linter` | Set up strict ESLint for TypeScript projects. |

### Frontend

| Skill | Description |
|-------|-------------|
| `platform-frontend` | Frontend architecture: state, components, data fetching. Framework-agnostic. |
| `tech-react` | React components, hooks, and rendering. |
| `design-frontend` | Visual design: layout, responsive, Tailwind tokens. |
| `design-accessibility` | WCAG AA compliance: ARIA, keyboard nav, focus management. |
| `figma-to-react-components` | Turn Figma designs into React components with design tokens and a11y. |

### Backend

| Skill | Description |
|-------|-------------|
| `platform-backend` | Server architecture: API design, error handling, validation, logging. |
| `tech-trpc` | tRPC routers, procedures, and Vertical Slice Architecture. |

### Database

| Skill | Description |
|-------|-------------|
| `platform-database` | SQL design, query optimization, migration safety. |
| `tech-drizzle` | Drizzle ORM: schemas, relations, migrations. |

### Mobile

| Skill | Description |
|-------|-------------|
| `tech-android` | Android: Kotlin, Jetpack Compose, architecture components. |
| `swift-concurrency` | Swift async/await, actors, tasks, Sendable. |
| `localize-ios` | iOS localization: strings, plurals, formatters. |
| `liquid-glass-ios` | Apple's Liquid Glass design system for iOS 26+. |

### Testing

| Skill | Description |
|-------|-------------|
| `platform-testing` | Testing principles: structure, mocking boundaries, test doubles. |
| `tech-vitest` | Vitest: vi.mock, vi.fn, fake timers, MSW. |

### CLI

| Skill | Description |
|-------|-------------|
| `platform-cli` | CLI design: commands, flags, output formatting, help text. |

### Assistant

| Skill | Description |
|-------|-------------|
| `promptify` | Transform user requests into precise prompts for AI models. |
| `agent-add-rule` | Add rules or conventions to project agent config. |
| `agent-init-deep` | Set up nested CLAUDE.md for progressive disclosure. |
| `agent-skill-creator` | Create new skills for this toolkit. |
| `agent-pr-creator` | Create PRs from git diffs via gh CLI. |
| `rewrite-commit-history` | Rewrite branch history into clean conventional commits. |
| `eval-agent-md` | Behavioral compliance testing for CLAUDE.md files. |
| `parallel` | Run a task in a background sub-agent. |
| `grill-me` | Interview you about a plan until reaching shared understanding. |
| `pr-comments-address` | Triage and fix PR review comments. |
| `transcript-notes` | Turn meeting transcripts into structured notes with action items. |
| `type-system-audit` | Find type-system weaknesses using bug-fix commits as evidence. |
| `agent-skills-manager` | Manage skills via corvus CLI: install, update, search, configure. |

## Team Sync

When using corvus, skill choices are tracked in a `.corvusrc` file you can commit to git:

```bash
# One dev installs skills
corvus install tech-react tech-drizzle

# Keep .corvusrc and skill folders out of git
corvus gitignore

# Or commit .corvusrc so teammates can sync your exact setup
git add .corvusrc && git commit -m "add AI skills config"

# Teammates clone and sync
corvus sync
```

**Project vs global:** `.corvusrc` is only created for project-level installs. Global installs (`--global`, `--global-claude`, etc.) are tracked in `~/.corvus/config` and apply to every project on your machine without touching your repo.

Run `corvus doctor` to check for orphaned skills, missing deps, or version mismatches.

## Versioning

Each skill is versioned independently with a build number (e.g. build 12). There is no single toolkit version.

```bash
# Install the latest build (default)
npx skills add ravnhq/ai-toolkit -s core-coding-standards

# Pin to a specific build when you need a reproducible setup
npx skills add https://github.com/ravnhq/ai-toolkit/tree/skill-core-coding-standards-b12 -s core-coding-standards
```

Running `npx skills update` upgrades every installed skill to its latest build unless you pinned it to a specific one. See `docs/skill-versioning.md` for details.

## Contributing

### Skill Structure

```
skills/[category]/[name]/
├── SKILL.md              # Manifest with YAML frontmatter
├── rules/                # Rule files (optional)
│   ├── _sections.md      # Section definitions + impact levels
│   └── [prefix]-*.md     # Individual rules (kebab-case)
├── references/           # Reference docs loaded on demand (optional)
├── scripts/              # Executable helpers (optional)
└── assets/               # Templates, images, fonts (optional)
```

Categories: `universal`, `frontend`, `backend`, `database`, `mobile`, `testing`, `cli`, `assistant`.

### Local Validation

```bash
ruby scripts/skills_audit.rb      # Validate skill structure and marketplace sync
ruby scripts/skills_harness.rb    # Run the full test harness
```

### CI Pipeline

PRs trigger skill quality checks automatically. On merge to `main`:

1. CI validates all skills and syncs `marketplace.json`
2. CI bumps build numbers for changed skills
3. CI creates release tags and publishes GitHub Releases

Changes to `cli-ts/**` also trigger a separate binary build workflow that compiles corvus for all platforms (darwin-arm64, darwin-x64, linux-x64, linux-arm64) using Bun and publishes them to the `cli-latest` GitHub Release.

### Workflow

1. Create or edit a skill in `skills/<category>/<name>/`.
2. Run `ruby scripts/skills_audit.rb` to validate locally.
3. Run `ruby scripts/skills_harness.rb` to confirm tests pass.
4. Open a PR to `main`. CI handles the rest.
5. On merge, CI bumps versions and publishes releases.

## Blog

Tips, guides, and deep dives on AI-assisted development. Visit the [Ravn AI Toolkit Blog](https://ravnhq.github.io/ai-toolkit/).

- Top 10 Claude Code Tips for Newcomers
- Making Claude Code Yours
- Context Switching Done Right
