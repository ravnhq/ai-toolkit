# Ravn AI Toolkit

Modular "skills" — portable rule packs that teach AI coding agents (Claude Code, Cursor, etc.) best practices for specific technologies — so every project gets consistent, expert-level guidance without copy-pasting prompts.

## Quick Start

```bash
# Install a skill into your project (grabs the latest version by default)
npx skills add ravnhq/ai-toolkit -s core-coding-standards

# See every skill available in the toolkit
npx skills add ravnhq/ai-toolkit -l

# Upgrade all installed skills to their latest versions
npx skills update
```

## Available Skills

The toolkit covers five layers, from general to specific:

| Layer | Examples | What it covers |
|-------|----------|----------------|
| **Universal** | `core-coding-standards`, `lang-typescript` | Rules that apply to all code |
| **Platform** | `platform-frontend`, `platform-backend`, `platform-database` | Patterns for a development domain |
| **Framework** | `tech-react`, `tech-trpc`, `tech-drizzle`, `tech-vitest` | API-specific guidance for a library |
| **Design** | `design-frontend`, `design-accessibility` | Visual and UX patterns |
| **Agent** | `agent-skill-creator`, `promptify` | Workflows for AI agents themselves |

The full list lives in `marketplace.json`. Work-in-progress skills are in `skills/_drafts/`.

## Versioning

Each skill is versioned independently with a build number (e.g. build 12). There is no single toolkit version.

```bash
# Install the latest build (default)
npx skills add ravnhq/ai-toolkit -s core-coding-standards

# Pin to a specific build when you need a reproducible setup
npx skills add https://github.com/ravnhq/ai-toolkit/tree/skill-core-coding-standards-b12 -s core-coding-standards
```

Running `npx skills update` upgrades every installed skill to its latest build unless you pinned it to a specific one.

## Help

- See `docs/skill-versioning.md` for how versioning works in detail.
- Run `ruby scripts/skills_audit.rb` to validate skill structure and `ruby scripts/skills_harness.rb` to run the test harness.
- Open an issue with repro steps and relevant logs.

## Contributing

1. Create or edit a skill in `skills/<category>/<name>/`.
2. Open a PR to `main`.

CI handles validation, catalog sync, build bumps, and release tags automatically on merge.
