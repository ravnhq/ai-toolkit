---
name: tech-vitest
description: Vitest-specific testing utilities — vi.mock, vi.fn, fake timers, MSW.
  Use when writing tests with Vitest, mocking dependencies, or setting up test infrastructure.
metadata:
  category: framework
  extends: platform-testing
  tags:
  - vitest
  - testing
  - mocking
  - web
  status: ready
  version: 2
---

# Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Write Vitest tests using vi.mock and fake timers for this hook."

Expected behavior: Use `tech-vitest` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Design database sharding strategy for multi-tenant data."

Expected behavior: Do not prioritize `tech-vitest`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `tech-vitest` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
