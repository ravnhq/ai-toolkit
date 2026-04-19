---
title: Generation coverage strategy and grouping
impact: HIGH
tags:
  - generate
  - coverage
  - test-design
---

## Rule

Mode A (Generate) must produce a coverage-complete set of test cases. Number them sequentially and group them in this strict order — no exceptions: (1) all happy-path cases first, (2) all negative-path cases second, (3) all edge cases last. Never interleave groups — every negative case must appear before the first edge case.

## Test Design Techniques

Apply Equivalence Partitioning, Boundary Value Analysis, and State Transition Testing. Assign riskiest behaviors High risk / P1–P2 priority. No duplicates.

## Scale by Release Type

| Release type | Test count |
|---|---|
| Hotfix | 3–8 |
| Sprint | 8–15 |
| Major | 15–30 |

## Input-Source Context

If step 2 provided a DOM snapshot (URL) or parsed markup (HTML/XML), use that structure to:
- Identify real form fields, interactive elements, and navigation flows instead of inferring them from a text description.
- Derive preconditions from authentication gates, required fields, and visible state (e.g., `aria-disabled="true"` implies a precondition to enable).
- Detect testable flows: form submissions, dialogs, pagination, dynamic state changes.
- Note in `coverage_summary.input_source` which source was used (`"url"`, `"html"`, or `"text"`).

## Output

JSON/XML/CSV — see `ref-schema-generate.md` for required fields. The output file contains test cases only; the coverage summary is delivered inline (see Workflow steps 6–8).

## Incorrect

```json
[
  { "id": "TC-001", "title": "Login with valid credentials", "group": "happy" },
  { "id": "TC-002", "title": "Login with expired token", "group": "edge" },
  { "id": "TC-003", "title": "Login with empty password", "group": "negative" }
]
```

- Error: Edge case (TC-002) appears before negative case (TC-003).
- Cause: Test cases were not grouped in the required order.

## Correct

```json
[
  { "id": "TC-001", "title": "Login with valid credentials", "group": "happy" },
  { "id": "TC-002", "title": "Login with empty password", "group": "negative" },
  { "id": "TC-003", "title": "Login with expired token", "group": "edge" }
]
```

- Happy path first, then negative, then edge — strict ordering maintained.

## Why it matters

Consistent grouping lets reviewers quickly assess coverage balance at a glance. Interleaved groups hide gaps and make it harder to confirm that all negative paths were considered before moving to edge cases.
