---
title: Offer intelligent defaults for standardized sections
impact: MEDIUM
tags:
  - test-plan
  - defaults
  - workflow
  - standards
---

## Rule

For sections with well-established industry-standard content (Severity Definitions, Bug Lifecycle, Glossary, Entry/Exit Criteria), **offer the standard content as a default** that the user can accept, modify, or skip. Do not ask open-ended questions for content that has a sensible universal answer.

## Incorrect

```
"For the Defect Management section, what severity levels does your team use? Please describe each level
and its definition. What is your bug lifecycle? Please describe all the states a bug can be in."
```

- Error: Asking the user to write from scratch content that is effectively identical across all QA teams.
- Cause: Treating standardized sections the same as project-specific sections.

## Correct

```
"I'll use the standard severity levels (Critical / High / Medium / Low) and bug lifecycle
(New → In Progress → Ready for QA → Verified / Closed, with Reopened and Deferred).
Does your team use a different workflow, or should I proceed with these defaults?"
```

- The default is offered upfront with a simple accept/modify prompt.
- The user only needs to engage if their setup differs from the standard.

## Why it matters

Asking users to reinvent standard content slows the interview, frustrates experienced QA engineers, and often produces lower-quality answers than the defaults would. Offering sensible defaults for standardized sections makes the tool faster without sacrificing document quality.
