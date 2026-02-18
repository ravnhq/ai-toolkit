---
name: platform-database
description: SQL database design, query optimization, and migration safety. Use when
  writing queries, designing schemas, or planning database migrations.
metadata:
  category: platform
  extends: core-coding-standards
  tags:
  - database
  - sql
  - queries
  - migrations
  - performance
  status: ready
  version: 2
---

# Principles

- Prefer UNION ALL over UNION unless you specifically need deduplication

# Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Review this schema and migration plan for zero-downtime rollout."

Expected behavior: Use `platform-database` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Implement ARIA labels and focus rings on this modal."

Expected behavior: Do not prioritize `platform-database`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `platform-database` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
