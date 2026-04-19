---
title: Describe system behavior, not UI interactions
impact: HIGH
tags:
  - test-case
  - writing
  - standards
---

## Rule

Test cases must describe what the **system does**, not how the user interacts with specific UI elements. Steps and expected results must be implementation-agnostic so they remain valid if the UI changes.

## Incorrect

```json
{
  "steps": [
    "Click the blue 'Login' button in the top-right corner",
    "Type in the text field labeled 'Email Address'",
    "Click the green submit button"
  ],
  "expected_result": "The dashboard screen with the left sidebar appears"
}
```

- Error: Steps reference specific UI element colors, positions, and labels. Expected result describes layout appearance.
- Cause: Test written from a screen walkthrough perspective instead of a behavioral specification.

## Correct

```json
{
  "steps": [
    "Initiate the login flow with valid credentials for a standard user",
    "Submit the authentication form"
  ],
  "expected_result": "The system authenticates the user and navigates to the authenticated home view."
}
```

- Steps describe user intent and system actions, not UI appearance.
- Expected result describes the behavioral outcome (authentication + navigation) rather than layout.

## Why it matters

UI-coupled test cases break whenever the interface is redesigned, requiring maintenance that has nothing to do with behavior changes. Behavior-focused tests survive UI refactors and remain valid across web, mobile, and API contexts.
