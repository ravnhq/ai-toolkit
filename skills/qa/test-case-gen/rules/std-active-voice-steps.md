---
title: Steps must use active voice imperative present tense
impact: MEDIUM
tags:
  - test-case
  - writing
  - steps
  - standards
---

## Rule

Test case steps must use **imperative present tense**: "Navigate to…", "Enter…", "Submit…", "Verify…". Passive constructions and narrative descriptions are not acceptable.

## Incorrect

```
Steps:
1. The login page was opened
2. Valid credentials should be entered by the tester
3. The form needs to be submitted
4. Dashboard visibility should be confirmed
```

- Error: Passive voice and conditional phrasing throughout. Steps cannot be directly executed.
- Cause: Steps written as a description of expected behavior rather than as direct instructions.

## Correct

```
Steps:
1. Navigate to /login
2. Enter valid credentials (email and password) for a standard user account
3. Submit the login form
4. Verify that the authenticated dashboard view is displayed
```

- Each step starts with an imperative verb.
- Steps are direct, actionable, and executable in sequence without interpretation.

## Why it matters

Imperative steps can be read as a script — by a human tester or an automation framework. Passive or narrative steps require mental translation that introduces ambiguity and inconsistency between testers. Active steps also map directly to automation action methods (`.click()`, `.navigate()`, `.fill()`).
