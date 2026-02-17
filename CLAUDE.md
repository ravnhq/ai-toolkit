# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Identity

A marketplace of modular AI skills for LLM-assisted development. Provides layered architecture: generic platform rules + framework-specific patterns for frontend, backend, database, testing, and design.

## Tech Stack

- Skill System: Vercel agent-skills pattern
- Documentation: Markdown with YAML frontmatter
- Standards: Reference material in `reference/standards/`
- Structure: Each skill in `skills/[name]/` with `SKILL.md` manifest
- Catalog: `marketplace.json` - machine-readable registry of all skills

## Tooling

- MUST use `fd` and `rg` for faster file operations (over `find` and `grep`)
- Use git for version control

## Skill Architecture

Skills follow a **layered hierarchy**:
1. **Universal** (`core-coding-standards`, `lang-typescript`) - apply to all code
2. **Platform Generic** (`platform-frontend`, `platform-backend`, `platform-database`, `platform-testing`, `platform-cli`) - generic patterns
3. **Framework-Specific** (`tech-react`, `tech-trpc`, `tech-drizzle`, `tech-vitest`, `swift-concurrency`) - extend platform skills with framework APIs
4. **Design** (`design-frontend`, `design-accessibility`, `liquid-glass-ios`) - visual and UX patterns
5. **Agent** (`agent-add-rule`, `agent-init-deep`, `agent-skill-creator`) - agent workflow tools

Scaffold skills (in development) live in `skills/_drafts/`.

### Skill Structure

```
skills/[name]/
├── SKILL.md              # Manifest with YAML frontmatter (name, description, category, tags, status)
├── rules/                # Rule files (optional)
│   ├── _sections.md      # Section definitions + impact levels
│   └── [prefix]-*.md     # Individual rules (kebab-case)
└── references/           # Reference docs (optional)
```

### SKILL.md Frontmatter

Every SKILL.md MUST have:
- `name` - kebab-case skill identifier
- `description` - what it does + trigger phrases for auto-invocation
- `category` - one of: universal, platform, framework, design, agent
- `tags` - array of keywords for discoverability
- `status` - ready or scaffold

Optional: `extends` (parent skill name)

### Rule File Format

Every rule MUST have:
- YAML frontmatter: `title`, `impact` (CRITICAL/HIGH/MEDIUM/LOW), `tags`
- **Incorrect** code example with explanation
- **Correct** code example with explanation
- **Why it matters** section explaining consequences

### Rule Organization

- Rules grouped by section prefix (defined in `_sections.md`)
- Use kebab-case for all filenames
- Each section has impact level and ordering

## Guardrails

- MUST follow skill structure conventions (Vercel pattern)
- MUST include impact levels in rule frontmatter
- MUST provide both correct and incorrect examples
- NEVER create duplicate rules across skills
- ALWAYS check if a rule belongs in generic (platform) or specific (tech) skill
- ALWAYS reference source material from `reference/standards/` when extracting rules
- ALWAYS update the matching entry in `marketplace.json` when bumping `version` in any SKILL.md frontmatter (same commit)

## More Information

- Architecture: See README.md for full skill hierarchy and stack recipes
- Reference Standards: `reference/standards/README.md` - source material for rule extraction
- Skill Catalog: `marketplace.json` - registry of all skills with categories and tags
