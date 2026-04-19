---
title: Normalization conversion rules and defaults
impact: MEDIUM
tags:
  - normalize
  - conversion
  - defaults
---

## Rule

Mode D (Normalize) converts test cases from any format to the RAVN standard schema. Every original step must be preserved — never collapse steps into preconditions. Compound tests must be split.

## Step Preservation

Preserve all original test steps — every step in the source must appear as a step in the output. Do not collapse steps into preconditions.

## Splitting Compound Tests

Split compound tests (multiple objectives) into separate test cases using `-A`/`-B` suffixes on the original ID (e.g., `OLD-042-A`, `OLD-042-B`). Record the count in `normalization_summary.splits_performed`.

## Fix Behavior-Over-UI Violations

Fix violations of `std-behavior-over-ui.md` during conversion and record each fix in `normalization_summary.issues_fixed` (integer count).

## Defaults When Uninferable

Apply these exactly — do not override:

| Field | Default |
|---|---|
| `risk_level` | `Medium` |
| `priority` | `P3` |
| `type` | `Functional` |
| `automation_candidate` | `false` |
| `platform` | `cross-platform` |

In particular, `automation_candidate` MUST default to `false` unless the source explicitly marks it otherwise.

## Platform Detection

Detect platform from source content (device names, gesture vocabulary, UI element names). Apply defaults only when platform is not inferable.

## Output

JSON/XML/CSV with `normalized_test_cases` (array) and `normalization_summary` (`original_count`, `normalized_count`, `splits_performed`, `fields_inferred`, `issues_fixed`, `data_loss_warnings`). The `normalization_summary` is always delivered inline — never in the output file.

## Incorrect

```json
{
  "id": "OLD-042",
  "steps": ["Log in and verify dashboard loads and check notification count"],
  "automation_candidate": true
}
```

- Error: Compound test not split. `automation_candidate` defaults to `true` instead of `false`. Original multi-action step collapsed.
- Cause: Normalizer inferred `true` for automation and merged objectives instead of splitting.

## Correct

```json
[
  {
    "id": "OLD-042-A",
    "objective": "Verify dashboard loads after login",
    "steps": [
      { "step": 1, "action": "Log in with valid credentials" },
      { "step": 2, "action": "Verify dashboard loads" }
    ],
    "automation_candidate": false
  },
  {
    "id": "OLD-042-B",
    "objective": "Verify notification count displays on dashboard",
    "steps": [
      { "step": 1, "action": "Log in with valid credentials" },
      { "step": 2, "action": "Navigate to dashboard" },
      { "step": 3, "action": "Check notification count is visible" }
    ],
    "automation_candidate": false
  }
]
```

- Compound test split into two with `-A`/`-B` suffixes. `automation_candidate` defaults to `false`. All original steps preserved.

## Why it matters

Normalizing with incorrect defaults or collapsed steps produces test cases that misrepresent the original intent. Splitting compounds ensures one-objective-per-test compliance, and conservative defaults prevent false automation signals.
