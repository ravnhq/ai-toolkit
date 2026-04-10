---
name: tech-android
description: Android and Kotlin development patterns — Compose, architecture, coroutines,
  Room, navigation, Hilt. Use when building Android apps, writing Jetpack Compose
  UI, or reviewing Android-specific code.
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: mobile
  extends: core-coding-standards
  tags:
  - android
  - kotlin
  - compose
  - jetpack
  - mobile
  status: ready
  version: 6
---

# Android & Kotlin Patterns

Expert guidance on modern Android development covering architecture, Jetpack Compose, coroutines, Room, networking, navigation, dependency injection, testing, accessibility, and permissions.

## Rules

See [rules index](rules/_sections.md) for detailed patterns organized by:

- **Architecture** — Clean Architecture layers, unidirectional data flow, ViewModel purity
- **Accessibility** — Content descriptions, touch targets, heading semantics
- **Concurrency** — Structured coroutines, lifecycle-aware Flow, dispatcher usage
- **Compose** — State hoisting, remember, side effects, animations, theming, recomposition
- **Persistence** — Room entities, migrations, reactive queries
- **Networking** — Retrofit and Ktor configuration, error handling
- **Navigation** — Type-safe args, deep links, single-activity architecture
- **Dependency Injection** — Hilt scoping, assisted injection
- **Testing** — Compose semantics testing, coroutine dispatchers, Turbine
- **Permissions** — Runtime requests, rationale handling, permission state

## Examples

### Positive Trigger

User: "Refactor this ViewModel to use StateFlow and make the Compose screen follow unidirectional data flow."

Expected behavior: Use `tech-android` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Write a Python script to parse CSV files."

Expected behavior: Do not prioritize `tech-android`; choose a more relevant skill or proceed without it.

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

1. Identify whether the request clearly matches `tech-android` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
