# Ravn AI Toolkit

<p align="center">
  <img src="docs/assets/images/ravencito.png" alt="Ravencito" width="200" />
</p>

[![Skills Quality](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml/badge.svg)](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml)

Modular "skills" — portable rule packs that teach AI coding agents (Claude Code, Cursor, etc.) best practices for specific technologies — so every project gets consistent, expert-level guidance without copy-pasting prompts. **26 ready skills** across five layers.

## Quick Start

### Using ravencito CLI

Install the `ravencito` CLI for interactive skill management, auto-updates, and team sync:

```bash
# Install with curl (macOS/Linux)
curl -fsSL https://raw.githubusercontent.com/ravnhq/ai-toolkit/main/install.sh | bash

# Verify it's working
ravencito --version

# Uninstall
sudo rm /usr/local/bin/ravencito
```

<details>
<summary>Install from source (alternative)</summary>

```bash
cd cli-ts && npm install && npm run build && npm install -g .
```
</details>

<details>
<summary>How the binary is built</summary>

`bun build --compile` bundles the entire app — TypeScript source, all npm dependencies, and the Bun runtime — into a single self-contained executable. No Node.js, no npm, no `node_modules` needed on the target machine.

**Why not `npm install -g`?** That approach requires Node.js ≥18 to be installed, downloads dependencies at install time, and can break if Node.js is upgraded or `node_modules` are corrupted. The compiled binary has zero runtime dependencies.

**Same model as Claude Code.** Anthropic's official CLI (`@anthropic-ai/claude-code`) is also distributed as a pre-built native binary — `npm install -g` downloads it rather than compiling from source. ravencito follows the same pattern: `install.sh` downloads a pre-built binary from the `cli-latest` GitHub Release.

To build binaries locally: `cd cli-ts && npm run build:bin`
</details>

```bash
# Browse all skills interactively (TUI)
ravencito install

# Install skills directly
ravencito install tech-react tech-drizzle

# Install a full stack recipe in one command
ravencito install --recipe fullstack-ts

# Install with explicit target flags
ravencito install --claude tech-react              # project-level → .claude/rules
ravencito install --cursor tech-react              # project-level → .cursor/rules
ravencito install --codex tech-react               # project-level → .codex/rules
ravencito install --global-claude lang-typescript  # global → ~/.claude/rules
ravencito install --global-cursor lang-typescript  # global → ~/.cursor/rules
ravencito install --global-codex lang-typescript   # global → ~/.codex/rules

# Search, preview, and manage
ravencito search testing
ravencito list                    # browse available skills by category
ravencito info tech-vitest
ravencito status
ravencito update
ravencito remove tech-vitest
ravencito doctor                  # health check for orphaned skills, missing deps
ravencito shower-thought          # random shower thought from Dave

# Shell completions (zsh, bash, and fish supported)
ravencito completions --shell fish

# Run tests
npm test
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

### Skill Hierarchy

Skills are layered so you only install what you need. Framework skills inherit all rules from their parent platform skill.

```
core-coding-standards          ← universal baseline
├── lang-typescript
├── platform-frontend          ← framework-agnostic UI patterns
│   └── tech-react
├── platform-backend           ← framework-agnostic server patterns
│   └── tech-trpc
├── platform-database          ← framework-agnostic DB patterns
│   └── tech-drizzle
├── platform-testing           ← framework-agnostic test patterns
│   └── tech-vitest
└── platform-cli

platform-mobile (draft)        ← framework-agnostic mobile patterns
└── tech-android

swift-concurrency              ← standalone (no parent)
localize-ios                   ← standalone
design-frontend                ← standalone
design-accessibility           ← standalone
figma-to-react-components      ← standalone
liquid-glass-ios               ← standalone
```

### Stack Recipes

With ravencito, install entire stacks in one command. Dependencies are resolved automatically.

| Recipe                    | Skills                                                                             | Command                                   |
|---------------------------|------------------------------------------------------------------------------------|-------------------------------------------|
| **Full-stack TypeScript** | lang-typescript, tech-react, tech-trpc, tech-drizzle, tech-vitest, design-frontend | `ravencito install --recipe fullstack-ts` |
| **iOS / Swift**           | swift-concurrency, liquid-glass-ios                                                | `ravencito install --recipe ios-swift`    |
| **Backend API**           | lang-typescript, tech-trpc, tech-drizzle, platform-testing                         | `ravencito install --recipe backend-api`  |

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

| Skill                   | Description                                                                                                 | Extends                 |
|-------------------------|-------------------------------------------------------------------------------------------------------------|-------------------------|
| `core-coding-standards` | Universal code quality rules — KISS, DRY, clean code, code review. Base skill every project should include. | —                       |
| `lang-typescript`       | TypeScript language patterns and type safety rules — strict mode, no any, discriminated unions.             | `core-coding-standards` |

### Platform

| Skill               | Description                                                                              | Extends                 |
|---------------------|------------------------------------------------------------------------------------------|-------------------------|
| `platform-frontend` | Framework-agnostic frontend architecture — state management, components, data fetching.  | `core-coding-standards` |
| `platform-backend`  | Server-side architecture and security — API design, error handling, validation, logging. | `core-coding-standards` |
| `platform-database` | SQL database design, query optimization, and migration safety.                           | `core-coding-standards` |
| `platform-testing`  | Framework-agnostic testing principles — test philosophy, structure, mocking boundaries.  | `core-coding-standards` |
| `platform-cli`      | Design and implementation patterns for building command-line tools with modern UX.       | `core-coding-standards` |

### Framework

| Skill               | Description                                                                                       | Extends             |
|---------------------|---------------------------------------------------------------------------------------------------|---------------------|
| `tech-react`        | React-specific component, hook, and rendering patterns.                                           | `platform-frontend` |
| `tech-trpc`         | tRPC router architecture, procedure design, and Vertical Slice Architecture patterns.             | `platform-backend`  |
| `tech-drizzle`      | Drizzle ORM schema design, relational queries, and migration patterns.                            | `platform-database` |
| `tech-vitest`       | Vitest-specific testing utilities — vi.mock, vi.fn, fake timers, MSW.                             | `platform-testing`  |
| `swift-concurrency` | Swift Concurrency patterns — async/await, actors, tasks, Sendable conformance.                    | —                   |
| `localize-ios`      | Localizes UIKit and SwiftUI views — extracts text, generates keys, creates Localizable.xcstrings. | —                   |
| `tech-android`      | Android and Kotlin development patterns — Compose, architecture, coroutines, Room, Hilt.          | `platform-mobile`   |

### Design

| Skill                       | Description                                                                                                                  | Extends |
|-----------------------------|------------------------------------------------------------------------------------------------------------------------------|---------|
| `design-frontend`           | Visual design system patterns for web UIs — layout, responsive, Tailwind tokens.                                             | —       |
| `design-accessibility`      | WCAG AA and ARIA best practices — screen readers, keyboard navigation, focus management.                                     | —       |
| `figma-to-react-components` | Convert Figma component designs into production-ready React implementations with design token integration and accessibility. | —       |
| `liquid-glass-ios`          | Apple's Liquid Glass design system for iOS 26+ and iPadOS 26+.                                                               | —       |

### Assistant

| Skill                    | Description                                                                      | Extends |
|--------------------------|----------------------------------------------------------------------------------|---------|
| `promptify`              | Transform user requests into detailed, precise prompts for AI models.            | —       |
| `agent-add-rule`         | Add rules, conventions, or instructions to the project's agent configuration.    | —       |
| `agent-init-deep`        | Initialize or migrate to nested CLAUDE.md structure for progressive disclosure.  | —       |
| `agent-skill-creator`    | Guide for creating effective, portable skills that extend Claude's capabilities. | —       |
| `agent-pr-creator`       | Analyzes git diffs and commit history to create pull requests via gh CLI.        | —       |
| `pr-comments-address`    | Reads open PR review comments, triages them, applies fixes, and drafts replies.  | —       |
| `rewrite-commit-history` | Rewrite a feature branch's commit history into clean conventional commits.       | —       |
| `agent-skills-manager`   | Manage AI skills via ravencito CLI — install, update, search, and configure.     | —       |

## Team Sync

When using ravencito, skill choices are tracked in a `.ravencitorc` file you can commit to git:

```bash
# One dev installs skills
ravencito install tech-react tech-drizzle
git add .ravencitorc && git commit -m "add AI skills config"

# Teammates clone and sync
ravencito sync
```

Run `ravencito doctor` to check for orphaned skills, missing deps, or version mismatches.

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

Categories: `universal`, `platform`, `framework`, `design`, `assistant`. Work-in-progress skills live in `skills/_drafts/`.

### Local Validation

```bash
ruby scripts/skills_audit.rb      # Validate skill structure and marketplace sync
ruby scripts/skills_harness.rb    # Run the full test harness
```

### CI Pipeline

PRs trigger skill quality checks automatically. On merge to `main`:

1. CI validates all skills and syncs `marketplace.json`
2. Build numbers are bumped for changed skills
3. Release tags are created and GitHub Releases published

Changes to `cli-ts/**` also trigger a separate binary build workflow that compiles ravencito for all platforms (darwin-arm64, darwin-x64, linux-x64, linux-arm64) using Bun and publishes them to the `cli-latest` GitHub Release.

### Workflow

1. Create or edit a skill in `skills/<category>/<name>/`.
2. Run `ruby scripts/skills_audit.rb` to validate locally.
3. Run `ruby scripts/skills_harness.rb` to confirm tests pass.
4. Open a PR to `main` — CI handles the rest.
5. On merge, versions bump and releases publish automatically.

## Blog

Tips, guides, and deep dives on AI-assisted development — visit the [Ravn AI Toolkit Blog](https://ravnhq.github.io/ai-toolkit/).

- Top 10 Claude Code Tips for Newcomers
- Making Claude Code Yours
- Context Switching Done Right

## In Development

Eight draft skills are under active development in `skills/_drafts/`: `platform-mobile`, `tech-ios`, `tech-react-native`, `tech-prisma`, `tech-tanstack-router`, `tech-tanstack-form`, `design`, and `design-mobile`. These are scaffolds and not yet production-ready.
