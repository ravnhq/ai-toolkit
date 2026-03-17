# Ravn AI Toolkit

[![Skills Quality](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml/badge.svg)](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml)

Modular "skills" — portable rule packs that teach AI coding agents (Claude Code, Cursor, etc.) best practices for specific technologies — so every project gets consistent, expert-level guidance without copy-pasting prompts. **26 ready skills** across five layers.

## Quick Start

### Using ravencito (recommended)

Install the `ravencito` CLI for interactive skill management, auto-updates, and team sync:

```bash
# Install ravencito
curl -fsSL https://raw.githubusercontent.com/ravnhq/ai-toolkit/main/cli/install.sh | bash

# Browse all skills interactively
ravencito install

# Install skills directly
ravencito install tech-react tech-drizzle

# Install a full stack recipe in one command
ravencito install --recipe fullstack-ts

# Set global defaults (apply to all projects)
ravencito install --global core-coding-standards lang-typescript

# Search, preview, and manage
ravencito search testing
ravencito info tech-vitest
ravencito status
ravencito update
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

swift-concurrency              ← standalone (no parent)
design-frontend                ← standalone
design-accessibility           ← standalone
figma-to-react-components      ← standalone
liquid-glass-ios               ← standalone
```

### Stack Recipes

With ravencito, install entire stacks in one command. Dependencies are resolved automatically.

| Recipe | Skills | Command |
|--------|--------|---------|
| **Full-stack TypeScript** | lang-typescript, tech-react, tech-trpc, tech-drizzle, tech-vitest, design-frontend | `ravencito install --recipe fullstack-ts` |
| **iOS / Swift** | swift-concurrency, liquid-glass-ios | `ravencito install --recipe ios-swift` |
| **Backend API** | lang-typescript, tech-trpc, tech-drizzle, platform-testing | `ravencito install --recipe backend-api` |

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

| Skill | Description | Extends |
|-------|-------------|---------|
| `core-coding-standards` | Universal code quality rules — KISS, DRY, clean code, code review. Base skill every project should include. | — |
| `lang-typescript` | TypeScript language patterns and type safety rules — strict mode, no any, discriminated unions. | `core-coding-standards` |

### Platform

| Skill | Description | Extends |
|-------|-------------|---------|
| `platform-frontend` | Framework-agnostic frontend architecture — state management, components, data fetching. | `core-coding-standards` |
| `platform-backend` | Server-side architecture and security — API design, error handling, validation, logging. | `core-coding-standards` |
| `platform-database` | SQL database design, query optimization, and migration safety. | `core-coding-standards` |
| `platform-testing` | Framework-agnostic testing principles — test philosophy, structure, mocking boundaries. | `core-coding-standards` |
| `platform-cli` | Design and implementation patterns for building command-line tools with modern UX. | `core-coding-standards` |

### Framework

| Skill | Description | Extends |
|-------|-------------|---------|
| `tech-react` | React-specific component, hook, and rendering patterns. | `platform-frontend` |
| `tech-trpc` | tRPC router architecture, procedure design, and Vertical Slice Architecture patterns. | `platform-backend` |
| `tech-drizzle` | Drizzle ORM schema design, relational queries, and migration patterns. | `platform-database` |
| `tech-vitest` | Vitest-specific testing utilities — vi.mock, vi.fn, fake timers, MSW. | `platform-testing` |
| `swift-concurrency` | Swift Concurrency patterns — async/await, actors, tasks, Sendable conformance. | — |
| `localize-ios` | Localizes UIKit and SwiftUI views — extracts text, generates keys, creates Localizable.xcstrings. | — |
| `tech-android` | Android and Kotlin development patterns — Compose, architecture, coroutines, Room, Hilt. | `platform-mobile` |

### Design

| Skill | Description | Extends |
|-------|-------------|---------|
| `design-frontend` | Visual design system patterns for web UIs — layout, responsive, Tailwind tokens. | — |
| `design-accessibility` | WCAG AA and ARIA best practices — screen readers, keyboard navigation, focus management. | — |
| `figma-to-react-components` | Convert Figma component designs into production-ready React implementations with design token integration and accessibility. | — |
| `liquid-glass-ios` | Apple's Liquid Glass design system for iOS 26+ and iPadOS 26+. | — |

### Assistant

| Skill | Description | Extends |
|-------|-------------|---------|
| `promptify` | Transform user requests into detailed, precise prompts for AI models. | — |
| `agent-add-rule` | Add rules, conventions, or instructions to the project's agent configuration. | — |
| `agent-init-deep` | Initialize or migrate to nested CLAUDE.md structure for progressive disclosure. | — |
| `agent-skill-creator` | Guide for creating effective, portable skills that extend Claude's capabilities. | — |
| `agent-pr-creator` | Analyzes git diffs and commit history to create pull requests via gh CLI. | — |
| `pr-comments-address` | Reads open PR review comments, triages them, applies fixes, and drafts replies. | — |
| `rewrite-commit-history` | Rewrite a feature branch's commit history into clean conventional commits. | — |
| `agent-skills-manager` | Manage AI skills via ravencito CLI — install, update, search, and configure. | — |

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

Nine draft skills are under active development in `skills/_drafts/`: `platform-mobile`, `tech-ios`, `tech-android`, `tech-react-native`, `tech-prisma`, `tech-tanstack-router`, `tech-tanstack-form`, `design`, and `design-mobile`. These are scaffolds and not yet production-ready.
