---
name: platform-backend
description: Server-side architecture and security — API design, error handling, validation,
  logging. Use when building APIs, server logic, or reviewing backend security.
metadata:
  category: platform
  extends: core-coding-standards
  tags:
  - backend
  - api
  - security
  - server
  status: ready
  version: 2
---

# Principles

- Throw early with guard clauses — fail fast at the top of functions
- Never swallow errors silently — log or propagate every failure

# Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Design error handling and validation strategy for this API endpoint."

Expected behavior: Use `platform-backend` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Create a Tailwind design token scale."

Expected behavior: Do not prioritize `platform-backend`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `platform-backend` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
