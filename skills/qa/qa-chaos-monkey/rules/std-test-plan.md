---
title: Read the test plan before testing
impact: CRITICAL
tags:
  - qa
  - workflow
  - test-plan
---

## Rule

Always read `.qa/test-plan.md` and `.env.qa` before starting any test execution. Never assume what endpoints to test or what credentials to use — the test plan is the single source of truth.

## Incorrect

```
# Agent starts attacking endpoints without reading configuration
1. POST /api/users with empty body
2. POST /api/users with SQL injection in name field
# No idea if /api/users even exists in this project
```

- Error: Agent assumes endpoint paths instead of reading from the test plan.
- Cause: Skipped the configuration loading step before test execution.

## Correct

```
# Agent reads configuration first
1. Read .qa/test-plan.md → found 5 API endpoints
2. Read .env.qa → QA_API_URL=https://staging-api.example.com
3. Target: POST /api/v1/orders (auth: required, fields: product_id, quantity)
4. Test: missing auth token → expect 401
5. Test: invalid product_id → expect 400
```

- Endpoints and their constraints come from the test plan, not assumptions.
- Tests are targeted and relevant to the actual application.

## Why it matters

Testing non-existent endpoints wastes time and produces false negatives. The test plan defines what endpoints exist, their auth requirements, and expected behavior — without it, adversarial tests are unfocused guesswork.
