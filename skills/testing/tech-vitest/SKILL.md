---
name: tech-vitest
description: 'Vitest testing framework for modern JavaScript. Unit and integration
  tests with Jest-compatible API, native TypeScript, Vite integration, MSW v2 for
  HTTP mocking, and snapshot testing. Covers vi.mock hoisting, fake timers, test isolation,
  and async patterns. Use when writing tests with Vitest, mocking dependencies, or
  setting up test infrastructure.

  '
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
metadata:
  category: testing
  extends: platform-testing
  tags:
  - testing
  - vitest
  - jest
  - unit-testing
  - fixtures
  - mocking
  - msw
  - snapshot
  status: ready
  version: 5
---

# Vitest Testing Framework

Fast, Vite-powered testing framework with Jest-compatible API and native ESM. Vitest excels at:
- **Watch mode** — Instant feedback during development with smart file watching
- **Native TypeScript/JSX** — Compiled by Vite, no extra setup
- **Mocking ecosystem** — `vi.mock()` for modules, MSW v2 for HTTP requests, fake timers for time-dependent code
- **Snapshot testing** — Auto-managed snapshots with inline snapshot support
- **Concurrent tests** — Parallel test execution with proper isolation

Core challenge: test isolation. Vitest's hoisting rules for `vi.mock()` require `vi.hoisted()` for shared mock state. MSW v2 changes handler APIs. Snapshot updates must be intentional.

## Workflow

When setting up tests or adding test cases:

1. **Identify scope** — What behavior? (unit/integration/e2e?)
2. **Determine dependencies** — HTTP? Timers? Other modules?
3. **Choose strategy** — `vi.mock()` with hoisting for modules, MSW for HTTP, fake timers for time
4. **Hoist shared state** — Use `vi.hoisted()` if mocks need variables from test scope
5. **Set up handlers** — MSW server in `beforeAll()`, reset in `afterEach()`
6. **Assert & snapshot** — Use matchers; snapshot only stable outputs
7. **Validate** — `vitest --watch` with coverage checks

## Rules

Tests are organized by concern:

- **Mocking Modules** — `vi.mock()`, `vi.hoisted()`, partial mocking with `importOriginal`
- **Mocking Functions** — `vi.fn()` with return values, implementations, and call tracking
- **Spying on Methods** — `vi.spyOn()` to watch object methods without replacing
- **Mocking HTTP** — MSW v2 handlers, `setupServer()`, per-test overrides
- **Fake Timers** — `vi.useFakeTimers()`, `vi.setSystemTime()`, timer advancement
- **Snapshots** — `toMatchSnapshot()`, inline snapshots, edge cases
- **Assertions** — Choosing matchers for your test assertions
- **Hooks & Setup** — `beforeEach`, `afterEach`, fixtures, setup files

See `rules/` for implementation patterns and examples.

## Examples

### Positive Trigger

User: "Mock the API client in this Vitest test so it returns a fake response."

Expected behavior: Use `tech-vitest` guidance, apply `vi.mock()` with hoisting rules and MSW patterns.

### Non-Trigger

User: "Set up a PostgreSQL database schema for user accounts."

Expected behavior: Do not prioritize `tech-vitest`; choose a more relevant skill or proceed without it.

- Error: Placing `vi.mock()` inside a condition
- Cause: `vi.mock()` is hoisted; conditions are ignored, leading to unexpected module state
- Solution: Move mocks to file top; use `vi.hoisted()` for conditional mock state

- Error: Updating snapshots without reviewing changes
- Cause: Snapshots bypass assertions; unexpected changes hide bugs
- Solution: Always review diffs in `--ui` mode before accepting with `-u`

## Troubleshooting

- Error: `Cannot access 'mockData' before initialization`
- Cause: Variables defined outside `vi.mock()` are not accessible in the factory (hoisting)
- Solution: Wrap in `vi.hoisted()` to define shared mock state at the top level

- Error: Mock handler never invoked; real HTTP request fires
- Cause: MSW server not started or wrong handler method (http vs graphql)
- Solution: Call `server.listen()` in `beforeAll()`; check handler verb matches request

- Error: Test passes locally but fails in CI
- Cause: Fake timers not reset between tests; time drifts across suite
- Solution: Call `vi.useRealTimers()` in `afterEach()` without fail
