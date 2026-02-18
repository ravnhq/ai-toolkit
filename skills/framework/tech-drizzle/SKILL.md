---
name: tech-drizzle
description: Drizzle ORM schema design, relational queries, and migration patterns.
  Use when working with Drizzle ORM, writing database queries, or managing Drizzle
  migrations.
metadata:
  category: framework
  extends: platform-database
  tags:
  - drizzle
  - orm
  - database
  - web
  status: ready
  version: 2
---

# Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Model a Drizzle schema and migration for invoices with relations."

Expected behavior: Use `tech-drizzle` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Plan an accessibility audit for keyboard navigation."

Expected behavior: Do not prioritize `tech-drizzle`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `tech-drizzle` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
