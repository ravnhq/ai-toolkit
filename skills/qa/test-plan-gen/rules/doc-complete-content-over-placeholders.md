---
title: Generate complete content — never leave placeholders in the output
impact: CRITICAL
tags:
  - test-plan
  - document-quality
  - standards
---

## Rule

The generated test plan must contain **real content** in every section. Placeholders like `[INSERT PROJECT NAME]`, `TBD`, `[TO BE DEFINED]`, or empty tables are not acceptable in the final output. Where the user has not provided a specific value, use an intelligent default based on project context.

## Incorrect

```markdown
## 1. Introduction

**Project Name:** [INSERT PROJECT NAME]
**Purpose:** This test plan defines the QA strategy for [PROJECT].

## 4. Test Environment

| Environment | URL | Type |
|---|---|---|
| [TBD] | [TBD] | [TBD] |
```

- Error: Placeholders throughout that require manual replacement. The document is a template, not a test plan.
- Cause: Content generated before sufficient information was gathered, or defaults not applied where information was missing.

## Correct

```markdown
## 1. Introduction

**Project Name:** Mobile Checkout Feature — Sprint 14
**Purpose:** This test plan defines the QA strategy, scope, approach, and schedule for testing the
checkout flow of the RAVN Commerce mobile application.

## 4. Test Environment

| Environment | URL | Type |
|---|---|---|
| Staging | https://staging.app.ravn.co | Pre-production |
```

- Every field contains real content derived from the interview or from a sensible default.
- A client or stakeholder can read the document without needing to fill anything in.

## Why it matters

A test plan with placeholders is not a deliverable — it is an unfinished template. Clients and stakeholders receiving a document with `[TBD]` fields lose confidence in the QA team's preparation. Complete content demonstrates professional readiness.
