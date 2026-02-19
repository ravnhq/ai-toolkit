# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Identity

A marketplace of modular AI skills for LLM-assisted development. Provides layered architecture: generic platform rules + framework-specific patterns for frontend, backend, database, testing, and design.

## Tech Stack

- Skill System: Vercel agent-skills pattern
- Documentation: Markdown with YAML frontmatter
- Structure: Each skill in `skills/[category]/[name]/` with `SKILL.md` manifest
- Catalog: `marketplace.json` - machine-readable registry of all skills

## Tooling

- MUST use `fd` and `rg` for faster file operations (over `find` and `grep`)
- Use git for version control

## Commands

```bash
ruby scripts/skills_audit.rb                    # Validate all skills (frontmatter, structure, marketplace sync)
ruby scripts/skills_harness.rb                   # Run skill test harness
ruby scripts/skill_version.rb <SKILL.md> [build] # Bump skill build number
```

Releases happen automatically via CI on merge to main. For manual releases outside the PR flow: `bash scripts/release.sh <skill-name>`

## Skill Architecture

Skills are organized into **category subdirectories** matching their tier:

```
skills/
├── universal/     # core-coding-standards, lang-typescript
├── platform/      # platform-frontend, platform-backend, platform-database, platform-testing, platform-cli
├── framework/     # tech-react, tech-trpc, tech-drizzle, tech-vitest, swift-concurrency
├── design/        # design-frontend, design-accessibility, liquid-glass-ios
├── assistant/     # agent-add-rule, agent-init-deep, agent-skill-creator, promptify
└── _drafts/       # scaffold skills (in development), also categorized
```

**Hierarchy**:
1. **Universal** - apply to all code
2. **Platform** - generic patterns (frontend, backend, database, testing, cli)
3. **Framework** - extend platform skills with specific framework APIs
4. **Design** - visual and UX patterns
5. **Assistant** - agent workflow tools

### Skill Structure

```
skills/[category]/[name]/
├── SKILL.md              # Manifest with YAML frontmatter (name, description, category, tags, status)
├── rules/                # Rule files (optional)
│   ├── _sections.md      # Section definitions + impact levels
│   └── [prefix]-*.md     # Individual rules (kebab-case)
├── references/           # Reference docs loaded on demand (optional)
├── scripts/              # Executable helpers (optional)
└── assets/               # Templates, images, fonts for output (optional)
```

### SKILL.md Frontmatter

Every SKILL.md MUST have:
- `name` - kebab-case skill identifier
- `description` - what it does + trigger phrases for auto-invocation

Required inside `metadata`:
- `category` - one of: universal, platform, framework, design, assistant
- `tags` - array of keywords for discoverability
- `status` - ready or scaffold

Optional: `license`, `metadata.version`

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
- ALWAYS reference existing skills as examples when extracting new rules
- ALWAYS update the matching entry in `marketplace.json` when bumping `version` in any SKILL.md frontmatter (same commit)
- MUST use exact `- Error:` / `- Cause:` / `- Solution:` / `Expected behavior:` format in SKILL.md Troubleshooting and Examples sections (required by skills harness)

## More Information

- Architecture: See README.md for full skill hierarchy and stack recipes
- Skill Catalog: `marketplace.json` - registry of all skills with categories and tags
- Skill Design Guide: `docs/building-skills-claude-complete-guide-findings.md` - best practices from Anthropic's official guide
