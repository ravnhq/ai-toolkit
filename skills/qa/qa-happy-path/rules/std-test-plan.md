---
title: Read the test plan before testing
impact: CRITICAL
tags:
  - qa
  - workflow
  - test-plan
---

## Rule

Always read `.qa/test-plan.md` and `.env.qa` before starting any test execution. Never assume what flows to test or what URLs to navigate to — the test plan is the single source of truth.

## Incorrect

```
# Agent starts testing immediately without reading configuration
1. Navigate to https://app.example.com
2. Click "Login"
3. Enter hardcoded credentials
```

- Error: Agent assumes URLs and credentials instead of reading from configuration files.
- Cause: Skipped the configuration loading step before test execution.

## Correct

```
# Agent reads configuration first
1. Read .qa/test-plan.md → found 3 UI flows
2. Read .env.qa → QA_PORTAL_URL=https://staging.example.com
3. Navigate to https://staging.example.com
4. Log in with QA_TEST_USER_EMAIL credentials
5. Execute Flow 1 from test plan...
```

- Configuration drives the test — URLs, credentials, and flows come from files, not assumptions.
- Test is reproducible because it references the same source of truth every time.

## Why it matters

Hardcoded URLs and credentials break when environments change. Test plans define the scope — testing without reading the plan means testing the wrong things or missing critical flows.
