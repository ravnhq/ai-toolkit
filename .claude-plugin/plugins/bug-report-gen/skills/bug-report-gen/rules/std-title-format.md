---
title: Title must follow [Component] format with no filler words
impact: MEDIUM
tags:
  - bug-report
  - title
  - writing
  - standards
---

## Rule

Bug report titles must follow the format `[Component] Short description of what breaks`. Maximum 80 characters. The words "bug", "issue", "problem", "defect", or "error" must not appear in the title.

## Incorrect

```
Bug with checkout total calculation issue
Error on the order page - problem with totals
[Checkout] There is a bug where the total shows wrong amount
```

- Error: Filler words ("bug", "issue", "problem", "error") in the title. No component prefix in first two examples. Vague description.
- Cause: Titles written descriptively from the reporter's perspective rather than as a precise defect identifier.

## Correct

```
[Checkout] Order total recalculates after payment confirmation
[Auth] SSO login returns 401 for users with expired tokens
[Cart] Item quantity resets to 1 when navigating back from checkout
```

- Component in brackets identifies the area at a glance.
- Description states the broken behavior precisely and concisely.
- No filler words. Each title fits within 80 characters.

## Why it matters

Titles are the primary identifier in bug tracking tools, dashboards, and release notes. Clear, scannable titles reduce triage time and prevent duplicate reports. Filler words waste character space and add no information.
