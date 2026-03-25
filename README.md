# Ravn AI Toolkit

[![Skills Quality](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml/badge.svg)](https://github.com/ravnhq/ai-toolkit/actions/workflows/skills-quality.yml)

Modular "skills" — portable rule packs that teach AI coding agents (Claude Code, Cursor, etc.) best practices for specific technologies — so every project gets consistent, expert-level guidance without copy-pasting prompts. **28 ready skills** organized by role.

## Quick Start

```bash
# Install a skill into your project (grabs the latest version by default)
npx skills add ravnhq/ai-toolkit -s core-coding-standards

# See every skill available in the toolkit
npx skills add ravnhq/ai-toolkit -l

# Upgrade all installed skills to their latest versions
npx skills update
```

## How Skills Work

### Skill Organization

Skills are grouped by role — everything for a domain lives in one directory. Install what you need.

```
skills/
├── universal/     # Global standards — apply to all code
├── frontend/      # Web UI: architecture, components, design, accessibility
├── backend/       # Server-side: APIs, services, architecture
├── database/      # Data layer: ORMs, schemas, queries
├── mobile/        # iOS, Android, React Native
├── testing/       # Test patterns and frameworks
├── cli/           # Command-line tool patterns
└── assistant/     # Agent workflow tools
```

### Stack Recipes

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

## Available Skills

### Universal

| Skill | Description |
|-------|-------------|
| `core-coding-standards` | Universal code quality rules — KISS, DRY, clean code, code review. Base skill every project should include. |
| `lang-typescript` | TypeScript language patterns and type safety rules — strict mode, no any, discriminated unions. |

### Frontend

| Skill | Description |
|-------|-------------|
| `platform-frontend` | Framework-agnostic frontend architecture — state management, components, data fetching. |
| `tech-react` | React-specific component, hook, and rendering patterns. |
| `design-frontend` | Visual design system patterns for web UIs — layout, responsive, Tailwind tokens. |
| `design-accessibility` | WCAG AA and ARIA best practices — screen readers, keyboard navigation, focus management. |
| `figma-to-react-components` | Convert Figma component designs into production-ready React implementations with design token integration and accessibility. |

### Backend

| Skill | Description |
|-------|-------------|
| `platform-backend` | Server-side architecture and security — API design, error handling, validation, logging. |
| `tech-trpc` | tRPC router architecture, procedure design, and Vertical Slice Architecture patterns. |

### Database

| Skill | Description |
|-------|-------------|
| `platform-database` | SQL database design, query optimization, and migration safety. |
| `tech-drizzle` | Drizzle ORM schema design, relational queries, and migration patterns. |

### Mobile

| Skill | Description |
|-------|-------------|
| `tech-android` | Android development patterns and best practices. |
| `swift-concurrency` | Swift Concurrency patterns — async/await, actors, tasks, Sendable conformance. |
| `localize-ios` | iOS localization patterns and best practices. |
| `liquid-glass-ios` | Apple's Liquid Glass design system for iOS 26+ and iPadOS 26+. |

### Testing

| Skill | Description |
|-------|-------------|
| `platform-testing` | Framework-agnostic testing principles — test philosophy, structure, mocking boundaries. |
| `tech-vitest` | Vitest-specific testing utilities — vi.mock, vi.fn, fake timers, MSW. |

### CLI

| Skill | Description |
|-------|-------------|
| `platform-cli` | Design and implementation patterns for building command-line tools with modern UX. |

### Assistant

| Skill | Description |
|-------|-------------|
| `promptify` | Transform user requests into detailed, precise prompts for AI models. |
| `agent-add-rule` | Add rules, conventions, or instructions to the project's agent configuration. |
| `agent-init-deep` | Initialize or migrate to nested CLAUDE.md structure for progressive disclosure. |
| `agent-skill-creator` | Guide for creating effective, portable skills that extend Claude's capabilities. |
| `agent-pr-creator` | Analyzes git diffs and commit history to create pull requests via gh CLI. |
| `rewrite-commit-history` | Rewrite a feature branch's commit history into clean conventional commits. |
| `eval-agent-md` | Behavioral compliance testing for CLAUDE.md or agent definition files. |

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

Categories: `universal`, `frontend`, `backend`, `database`, `mobile`, `testing`, `cli`, `assistant`. Scaffold skills live alongside ready skills, distinguished by `metadata.status: scaffold`.

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

Several scaffold skills are under active development: `platform-mobile`, `tech-ios`, `tech-react-native`, `tech-prisma`, `tech-tanstack-router`, `tech-tanstack-form`, and `design-mobile`. These live in their role directory with `metadata.status: scaffold` and are not yet production-ready.
