---
name: tech-trpc
description: tRPC router architecture, procedure design, and Vertical Slice Architecture
  patterns. Use when building tRPC APIs, designing procedures, or structuring backend
  slices.
metadata:
  category: framework
  extends: platform-backend
  tags:
  - trpc
  - api
  - rpc
  - web
  status: ready
  version: 2
---

# Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Design tRPC procedures and router slices for the checkout flow."

Expected behavior: Use `tech-trpc` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Implement Vitest fake timer tests for debounce utilities."

Expected behavior: Do not prioritize `tech-trpc`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `tech-trpc` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
