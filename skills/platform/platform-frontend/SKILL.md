---
name: platform-frontend
description: Framework-agnostic frontend architecture — state management, components,
  data fetching. Use when building any web frontend, choosing state patterns, or structuring
  UI code.
metadata:
  category: platform
  extends: core-coding-standards
  tags:
  - frontend
  - ui
  - components
  - state
  status: ready
  version: 2
---

# Principles

- Start with local state — lift only when shared
- Organize code by feature, not by type
- Use named exports for better refactoring and searchability
- Never use barrel files (index.ts re-exports) — they break tree-shaking and slow builds
- Measure before memoizing — don't optimize what isn't slow

# Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Choose state boundaries and data-fetching patterns for this web app."

Expected behavior: Use `platform-frontend` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Write a Swift actor for thread-safe cache access."

Expected behavior: Do not prioritize `platform-frontend`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `platform-frontend` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
