---
title: Test security boundaries on every authenticated endpoint
impact: CRITICAL
tags:
  - qa
  - security
  - authentication
  - authorization
---

## Rule

For every endpoint marked `auth: required` in the test plan, test these security boundaries: missing auth token, invalid/expired auth token, and accessing resources belonging to other users or organizations. Every failure to reject invalid auth is a BLOCKER or HIGH severity bug.

## Incorrect

```
# Only tests with valid credentials
1. POST /api/orders with valid JWT → 201 ✓
2. GET /api/orders/123 with valid JWT → 200 ✓
# Never tested what happens without auth
```

- Error: Only tested the happy path — never verified that authentication is enforced.
- Cause: Agent treated auth as a setup step rather than a test target.

## Correct

```
# Tests all auth boundary conditions
1. POST /api/orders with NO auth header → 401 ✓
2. POST /api/orders with expired JWT → 401 ✓
3. POST /api/orders with malformed JWT ("Bearer garbage") → 401 ✓
4. GET /api/orders/123 with User B's JWT (User A's order) → 403 ✓
5. POST /api/orders with valid JWT → 201 ✓ (baseline)
```

- Every auth boundary is tested: missing, expired, malformed, and cross-user access.
- Baseline valid request confirms the endpoint works — failures are in auth enforcement, not the endpoint itself.

## Why it matters

Broken authentication is consistently in the OWASP Top 10. An endpoint that accepts requests without valid auth, or returns another user's data, is a security vulnerability that can lead to data breaches. These bugs are always HIGH or BLOCKER severity.
