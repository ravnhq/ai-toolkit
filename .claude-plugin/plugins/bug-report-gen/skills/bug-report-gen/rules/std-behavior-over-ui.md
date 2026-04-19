---
title: Describe system behavior, not UI appearance
impact: HIGH
tags:
  - bug-report
  - writing
  - standards
---

## Rule

Describe what the **system does**, not what UI elements look like or how to click through them. Bug reports must be implementation-agnostic so they remain valid if the UI is redesigned.

## Incorrect

```
The blue "Submit" button on the right side of the checkout form turns gray and the spinner never stops spinning.
```

- Error: Describes visual appearance ("blue", "right side") and UI element state instead of system behavior.
- Cause: Writer focused on what they saw on screen rather than what the system failed to do.

## Correct

```
The order submission endpoint does not return a response after the user submits the checkout form, leaving the UI in an indefinite loading state.
```

- The description identifies the broken system behavior (no response from endpoint) rather than the visual symptom.
- Remains accurate even if the button color or layout changes.

## Why it matters

UI-coupled descriptions become stale as the interface evolves and mislead engineers who may not recognize the symptom from a different UI version. Behavior-focused reports stay valid across redesigns, platform differences, and automation contexts.
