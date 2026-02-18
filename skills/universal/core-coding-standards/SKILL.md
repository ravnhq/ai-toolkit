---
name: core-coding-standards
description: Universal code quality rules — KISS, DRY, clean code, code review. Base
  skill every project should include. Use when writing or reviewing any code.
metadata:
  category: universal
  tags:
  - code-quality
  - review
  - fundamentals
  status: ready
  version: 2
---

# Principles

- Keep it simple (KISS) — prefer the simplest solution that works
- Don't repeat yourself (DRY) — extract when you see three duplicates, not before
- Single Responsibility — each module/function does one thing
- Use descriptive, intention-revealing names
- Use kebab-case for files and folders
- Functions should have clear inputs and outputs with minimal side effects
- Keep functions right-sized — extract when logic needs a comment to explain
- Delete dead code — don't comment it out
- Never swallow errors silently
- Measure before optimizing — no premature performance work
- No premature abstraction — wait for three concrete duplicates before extracting

# Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Review this service and remove duplication while keeping behavior unchanged."

Expected behavior: Use `core-coding-standards` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Generate a one-off product marketing tagline."

Expected behavior: Do not prioritize `core-coding-standards`; choose a more relevant skill or proceed without it.

## Troubleshooting

### Skill Does Not Trigger

- Error: The skill is not selected when expected.
- Cause: Request wording does not clearly match the description trigger conditions.
- Solution: Rephrase with explicit domain/task keywords from the description and retry.

### Guidance Conflicts With Another Skill

- Error: Instructions from multiple skills conflict in one task.
- Cause: Overlapping scope across loaded skills.
- Solution: State which skill is authoritative for the current step and apply that workflow first.

### Output Is Too Generic

- Error: Result lacks concrete, actionable detail.
- Cause: Task input omitted context, constraints, or target format.
- Solution: Add specific constraints (environment, scope, format, success criteria) and rerun.

## Workflow

1. Identify whether the request clearly matches `core-coding-standards` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
