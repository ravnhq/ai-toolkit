# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Identity

A marketplace of modular AI skills for LLM-assisted development. Skills are organized by role (frontend, backend, database, mobile, testing, cli) so developers find everything for their domain in one place.

## Tech Stack

- Skill System: Vercel agent-skills pattern
- Documentation: Markdown with YAML frontmatter
- Structure: Each skill in `skills/[category]/[name]/` with `SKILL.md` manifest
- Catalog: `marketplace.json` - machine-readable registry of all skills

## Tooling

- MUST use `fd` and `rg` for faster file operations (over `find` and `grep`)
- Use git for version control
- Ruby 2.7+ required for audit/harness scripts

## Commands

```bash
ruby scripts/skills_audit.rb                    # Validate all skills (frontmatter, structure, marketplace sync)
ruby scripts/skills_harness.rb                   # Run skill test harness
ruby scripts/skill_version.rb <SKILL.md> [build] # Bump skill build number
ruby scripts/skill_score.rb                      # Score skill quality
ruby scripts/markdown_lint.rb                    # Lint markdown in skill files
bash scripts/changelog.sh                        # Generate changelog
```

Releases happen automatically via CI on merge to main. For manual releases outside the PR flow: `bash scripts/release.sh <skill-name>`

## Skill Architecture

Skills are organized **flat by role** — everything for a domain lives in one directory:

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

Scaffold (in-progress) skills live alongside ready skills, distinguished by `metadata.status: scaffold`.

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
- `category` - one of: universal, frontend, backend, database, mobile, testing, cli, assistant
- `tags` - array of keywords for discoverability
- `status` - ready or scaffold

Optional: `license`, `metadata.version`

Skills can declare `extends: <parent-skill-name>` in frontmatter to inherit rules from a parent skill (e.g., `tech-react` extends `platform-frontend`).

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

## Output Rules

- When asked to write a file (SKILL.md, rule file, etc.): produce the COMPLETE file content directly — do not describe what you would write or output a plan instead of the artifact

## Guardrails

- MUST follow skill structure conventions (Vercel pattern)
- MUST include impact levels in rule frontmatter
- MUST provide both correct and incorrect examples
- NEVER create duplicate rules across skills — when creating a new rule, FIRST search `skills/` for existing rules that cover the same topic (check platform skills, not just the target skill), THEN proceed only if no duplicate exists
- ALWAYS check if a rule already exists in another skill within the same role directory before creating a duplicate
- ALWAYS reference existing skills as examples when extracting new rules — when creating a new skill, FIRST name 2-3 existing skills (e.g., `tech-react`, `platform-testing`) as structural models to follow, THEN build the new skill matching their pattern
- ALWAYS update the matching entry in `marketplace.json` when bumping `version` in any SKILL.md frontmatter (same commit)
- MUST use exact `- Error:` / `- Cause:` / `- Solution:` / `Expected behavior:` format in SKILL.md Troubleshooting and Examples sections (required by skills harness)

## More Information

- Architecture: See README.md for full skill hierarchy and stack recipes
- Skill Catalog: `marketplace.json` - registry of all skills with categories and tags
- Skill Design Guide: `docs/building-skills-claude-complete-guide-findings.md` - best practices from Anthropic's official guide
