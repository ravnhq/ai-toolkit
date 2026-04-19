---
title: Steps must use active voice imperative present tense
impact: MEDIUM
tags:
  - bug-report
  - writing
  - steps
  - standards
---

## Rule

Reproduction steps must use **imperative present tense** (active voice): "Navigate to…", "Enter…", "Click…", "Observe…". Passive constructions, past tense, and ambiguous phrasing are not acceptable.

## Incorrect

```
Steps:
1. The user went to the login page
2. Credentials were entered
3. The submit button was clicked
4. An error was observed
```

- Error: All steps are in passive past tense. Subject is unclear. Steps cannot be directly followed as instructions.
- Cause: Reporter narrated what happened rather than writing actionable instructions.

## Correct

```
Steps to reproduce:
1. Navigate to /login
2. Enter a valid email in the Email field
3. Enter the correct password in the Password field
4. Click "Sign In"
5. Observe the error response
```

- Each step is a direct instruction starting with an imperative verb.
- Steps are scannable, unambiguous, and directly executable.

## Why it matters

Active imperative steps can be executed directly by engineers and converted into automated test scripts without rewriting. Passive narration forces the reader to mentally translate the description into instructions, introducing ambiguity and slowing down reproduction.
