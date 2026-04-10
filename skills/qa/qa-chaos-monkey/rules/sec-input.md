---
title: Test input validation with adversarial payloads
impact: HIGH
tags:
  - qa
  - security
  - input-validation
  - injection
---

## Rule

For every endpoint that accepts user input, test with: missing required fields (one at a time), invalid types, boundary values (empty strings, MAX_INT, 10K+ char strings), and injection payloads (SQL, XSS, command injection). Every 500 error on bad input is a bug.

## Incorrect

```
# Only tests with one bad input
1. POST /api/users with empty name → 400 ✓
# Stops here — no boundary values, no injection, no type mismatches
```

- Error: Tested only one validation case out of dozens of possible invalid inputs.
- Cause: Agent lacked systematic coverage of input validation categories.

## Correct

```
# Systematic input validation testing
1. POST /api/users with name="" → 400 ✓ (empty string)
2. POST /api/users with name=null → 400 ✓ (null value)
3. POST /api/users with name=12345 → 400 ✓ (wrong type)
4. POST /api/users with name="A"*10000 → 400 ✓ (boundary length)
5. POST /api/users with name="'; DROP TABLE users;--" → 400 ✓ (SQL injection)
6. POST /api/users with name="<script>alert(1)</script>" → 400 ✓ (XSS)
7. POST /api/users with email missing → 400 ✓ (missing required field)
8. POST /api/users with extra_field="test" → 201 ✓ (unknown fields ignored)
```

- Every category of invalid input is tested: empty, null, wrong type, boundary, injection, missing required, unknown fields.
- Each test verifies the response is a clear 400 error, not a 500 crash.

## Why it matters

APIs that crash on unexpected input (500 errors) expose stack traces, leak implementation details, and can be exploited for denial of service. Proper input validation returns clear 400 errors with helpful messages, preventing security vulnerabilities and improving developer experience.
