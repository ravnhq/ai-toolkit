---
name: platform-testing
description: Framework-agnostic testing principles — test philosophy, structure, mocking
  boundaries. Use when writing, reviewing, or debugging tests.
metadata:
  category: platform
  extends: core-coding-standards
  tags:
  - testing
  - mocking
  - test-design
  status: ready
  version: 2
---

# Principles

- Test behavior, not implementation details
- Prefer integration tests over unit tests (Testing Trophy)
- Arrange-Act-Assert (AAA) pattern in every test
- Tests must be independent — no shared mutable state
- Keep tests small and focused — one behavior per test
- Name tests to describe the behavior being verified
- Optimize for confidence, not coverage percentage
- Don't chase 100% coverage — test what matters

# Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Define integration-vs-unit test boundaries and mocking strategy."

Expected behavior: Use `platform-testing` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Create a tRPC router for billing procedures."

Expected behavior: Do not prioritize `platform-testing`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `platform-testing` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
