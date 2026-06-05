# Test-Plan Obligation Clause

Verbatim clause to include in every **code-touching** task dispatch prompt. Copy this text exactly into the prompt body alongside the primary task instructions.

```text
After completing your primary task, append or update `.qa/test-plan.md`
with the surface area you changed, so qa-orchestrator can pick the right
QA agents in its Phase 2 selector:
  - If you added or modified a UI flow, add it under `## UI Flows` with
    the entry point URL/route, steps, and expected outcome.
  - If you added or modified an API endpoint, add it under
    `## API Endpoints` with method, path, auth requirements, and
    request/response shape.
  - If `.qa/test-plan.md` does not yet exist, scaffold it from
    `skills/qa/qa-orchestrator/references/test-plan.md` first, then
    add your section.
  - Do not delete or rewrite entries that belong to unchanged surface
    area — only add or update what your change touched.
  - If `.qa/test-plan.md` is being modified by another process, retry
    the update after a brief delay (a few seconds) rather than overwriting.
This update is required, not optional. The dev-orchestrator will hand
off to qa-orchestrator immediately after, and the test plan is the
input that decides which QA agents (qa-happy-path, qa-chaos-monkey,
custom personalities) actually run.
```

## Who is exempt

Doc-only tasks (`test-case-gen`, `test-plan-gen`, `bug-report-gen`, `locators-scanner`) are exempt — they do not change runtime behavior, so there is no surface area to register.

## See also

- [`../SKILL.md`](../SKILL.md) — Phase 3 "Test-plan obligation" section where this clause is required.
- [`dispatch-contract.md`](dispatch-contract.md) — the four-part isolated-agent contract that governs how dispatch prompts are built.
