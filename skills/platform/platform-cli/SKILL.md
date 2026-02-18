---
name: platform-cli
description: Design and implementation patterns for building command-line tools with
  modern UX. Use when designing a CLI, reviewing CLI UX, defining commands and flags,
  or implementing error handling and signal handling.
metadata:
  category: platform
  extends: core-coding-standards
  tags:
  - cli
  - terminal
  - commands
  - flags
  status: ready
  version: 2
---

# CLI Development Patterns

Modern CLI design patterns for commands, flags, output, errors, signals, config, and distribution.

## Rules

Core CLI design rules extracted as discrete, actionable patterns. See [rules index](rules/_sections.md) for the full list organized by:

- **Commands & Naming** - Lowercase, typeable command names
- **Flags & Arguments** - Standard flag conventions (-h, -v, -q, etc.)
- **Configuration** - Precedence order (flags > env > config > defaults)
- **Output & Streams** - stdout vs stderr separation
- **Error Handling** - Actionable error messages with clear fixes
- **Signals & Lifecycle** - Ctrl-C handling with timeout and force option
- **Security** - Never read secrets from environment variables
- **Distribution** - Single binary packaging when possible

## References

See [references/cli-patterns.md](references/cli-patterns.md) for comprehensive guidance organized by:

- **Design & Naming** - Command structure, naming conventions, future-proofing
- **Flags & Arguments** - Standard flags, short forms, boolean negation
- **Output & Formatting** - stdout/stderr, TTY detection, colors, machine-readable formats
- **Error Handling** - Exit codes, error messages, signal-to-noise ratio
- **Signals & Lifecycle** - Ctrl-C handling, cleanup timeouts
- **Environment & Config** - Standard variables, precedence, naming
- **Distribution & Packaging** - Single binary distribution, uninstall instructions
- **Security & Privacy** - Secret handling, telemetry consent

## Examples

### Positive Trigger

User: "Design CLI commands, flags, and exit codes for a deployment tool."

Expected behavior: Use `platform-cli` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Write a migration plan for PostgreSQL partitioning."

Expected behavior: Do not prioritize `platform-cli`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `platform-cli` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
