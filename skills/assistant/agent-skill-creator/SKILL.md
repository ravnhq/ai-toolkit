---
name: agent-skill-creator
description: 'Guide for creating effective, portable skills that extend Claude''s
  capabilities with specialized knowledge, workflows, and tool integrations. Use when:
  (1) Creating a new skill from scratch, (2) Updating or improving an existing skill,
  (3) Structuring skill content for progressive disclosure, (4) Writing skill descriptions
  and triggers, (5) Packaging a skill for distribution. Triggers on: "create a skill",
  "build a skill", "new skill", "update this skill", "improve skill description",
  "skill structure", "skill triggers".'
license: Complete terms in LICENSE.txt
metadata:
  category: assistant
  tags:
  - agent
  - skills
  - authoring
  - templates
  status: ready
  version: 5
---

# Skill Creator

Create effective, portable skills that work across Claude.ai, Claude Code, and the API. A skill is a folderized instruction set that encodes a reusable workflow once, then applies it consistently.

## Skill Structure

```
skill-name/
├── SKILL.md              # Required: YAML frontmatter + markdown instructions
├── scripts/              # Optional: executable code for deterministic tasks
├── references/           # Optional: docs loaded into context as needed
└── assets/               # Optional: files used in output (templates, images, fonts)
```

### SKILL.md

Two parts:

1. **Frontmatter** (YAML) — `name` and `description` fields. Always in context. Determines when the skill triggers.
2. **Body** (Markdown) — Instructions, workflows, and pointers to bundled resources. Loaded only after triggering.

### Bundled Resources

| Directory | Purpose | Loaded into context? |
|-----------|---------|---------------------|
| `scripts/` | Executable code (Python/Bash) for deterministic operations | Only when Claude reads them |
| `references/` | Documentation Claude consults while working | On demand |
| `assets/` | Files used in output (templates, images, fonts) | Never — used directly in output |

Do not include README.md, CHANGELOG.md, or any auxiliary documentation files.

## Core Principles

### Context Budget

The context window is shared. Only include what Claude does not already know. Prefer concise examples over verbose explanations. Challenge each paragraph: "Does this justify its token cost?"

**Hard limit**: Keep SKILL.md body under 5,000 words. Move detailed content to `references/`.

### Degrees of Freedom

Match specificity to the task's fragility:

- **High freedom** (text guidance) — multiple valid approaches, context-dependent
- **Medium freedom** (pseudocode/parameterized scripts) — preferred pattern, some variation ok
- **Low freedom** (exact scripts) — fragile operations, consistency critical

### Progressive Disclosure

Three-layer loading minimizes context usage:

1. **Frontmatter** (~100 words) — always in context
2. **SKILL.md body** (<5k words) — loaded when skill triggers
3. **Bundled resources** (unlimited) — loaded as needed

Keep SKILL.md lean. Split into reference files when approaching 300 lines. Always reference split files from SKILL.md with clear descriptions of when to read them.

### Composability and Portability

- Skills must coexist without conflicting instructions
- Skills must work across Claude.ai, Claude Code, and the API
- Do not hard-depend on environment-specific tooling

## Workflow

### 1. Understand

Gather concrete use cases before building anything.

**Entry**: User request to create or improve a skill.

**Actions**:
- Identify 2-3 concrete examples of how the skill will be used
- For each example: what triggers it, what steps run, what the end result looks like
- Ask targeted questions — avoid overwhelming the user with too many at once

**Exit**: Clear understanding of the skill's scope, triggers, and expected outputs.

### 2. Plan

Determine what reusable resources the skill needs.

**Entry**: Concrete use cases from Step 1.

**Actions**:
- For each use case: what gets rewritten every time? That belongs in the skill.
- Categorize resources:
  - Code rewritten repeatedly → `scripts/`
  - Knowledge referenced repeatedly → `references/`
  - Templates/assets used in output → `assets/`
- Decide SKILL.md structure — see `references/workflows.md` for common patterns.

**Exit**: List of resources to create and SKILL.md outline.

### 3. Build

Create the skill folder and write its contents.

**Entry**: Resource list and SKILL.md outline from Step 2.

**Actions**:

1. **Create the skill folder** following the structure above. If `scripts/init_skill.py` is available in the environment, use it as a scaffolding accelerator:
   ```bash
   scripts/init_skill.py <skill-name> --path <output-directory>
   ```
   Otherwise, create the folder and SKILL.md manually.

2. **Write bundled resources first** — scripts, references, assets. Test scripts by running them. Delete any scaffolding files not needed.

3. **Write SKILL.md**:
   - **Frontmatter**: Follow `references/description-authoring.md` for the description formula
   - **Body**: Use imperative/infinitive form. Structure by workflow steps or task categories.
   - Keep the body lean — point to references for depth
   - Validate against `references/validation-checklist.md` to ensure the skill meets all structural requirements

4. **Delete unused scaffolding** — remove example files and empty directories.

**Exit**: Complete skill folder with all resources and SKILL.md.

### 4. Test

Validate triggering and output quality.

**Entry**: Complete skill from Step 3.

**Actions**:
- Run triggering tests (positive and negative prompts)
- Run functional tests on real tasks
- Compare results against baseline (no skill)

See `references/testing-iteration.md` for detailed testing methodology and success criteria.

**Exit**: Skill triggers reliably (~90% on relevant prompts) and produces consistent output.

### 5. Iterate

Refine based on real usage.

**Entry**: Test results or user feedback.

**Actions**:
- Diagnose issues: undertriggering, overtriggering, or execution failures
- Apply targeted fixes per `references/testing-iteration.md`
- Re-test affected areas

**Exit**: Skill meets success criteria across real-world usage.

## Packaging

Package a finished skill as a `.skill` file (zip with `.skill` extension). If `scripts/package_skill.py` is available, use it — it validates and packages automatically:

```bash
scripts/package_skill.py <path/to/skill-folder> [output-directory]
```

Otherwise, zip the skill folder manually ensuring SKILL.md is at the root of the archive.

## Reference Guides

Consult these based on the skill's needs:

- **Description and triggers**: `references/description-authoring.md` — formula, trigger phrases, negative triggers, hard constraints
- **Workflow patterns**: `references/workflows.md` — sequential, multi-service, iterative, context-aware, domain intelligence
- **Output patterns**: `references/output-patterns.md` — templates and example-based output guidance
- **Testing and iteration**: `references/testing-iteration.md` — triggering tests, functional tests, performance metrics, diagnostics
- **Validation checklist**: `references/validation-checklist.md` — structural requirements every skill must meet
- **Troubleshooting**: `references/troubleshooting.md` — common failures and resolution paths

## Examples

### Positive Trigger

User: "Create a new skill for converting PDFs to markdown with reusable scripts."

Expected behavior: Follow this skill's workflow — understand use cases, plan resources, build the skill.

### Non-Trigger

User: "Find and fix a TypeScript type error in src/api/client.ts."

Expected behavior: Do not use this skill. Choose a more relevant skill or proceed directly.

## Troubleshooting

### Created Skill Does Not Trigger

- Error: The skill is not selected when expected.
- Cause: Description lacks specific trigger phrases or is too vague.
- Solution: Rewrite description following `references/description-authoring.md`.

### Created Skill Is Too Verbose

- Error: SKILL.md exceeds 5,000 words or fills excessive context.
- Cause: Detailed content belongs in references, not the body.
- Solution: Move detailed content to `references/` files. Keep SKILL.md as a lean workflow guide.

### Output Is Inconsistent Across Sessions

- Error: Skill produces different quality results each time.
- Cause: Instructions are ambiguous or lack explicit validation steps.
- Solution: Add concrete examples, exact commands, and verification steps. See `references/troubleshooting.md`.
