---
title: Suite audit and health analysis
impact: MEDIUM
tags:
  - audit
  - coverage
  - suite-health
---

## Rule

Mode C (Audit) analyzes a complete test suite by mapping tests to flows/features, identifying gaps and redundancies, and producing actionable recommendations.

## Analysis Criteria

1. **Coverage mapping** — Map tests to flows/features and find uncovered areas.
2. **Duplicate detection** — Identify duplicate clusters for merging.
3. **Distribution checks** — Verify risk/priority distribution (80% P3/P4 = red flag).
4. **Automation assessment** — Check automation candidates for viability.
5. **Recommended suite** — Produce specific add/remove/modify actions.

## Output

JSON with:
- `suite_health`: `total_test_cases`, `coverage_score`, `health_grade`, `automation_coverage_pct`, type/priority/risk distributions, `issues_summary`
- `coverage_gap_analysis`: `uncovered_areas`, `over_tested_areas`, `risk_exposure`
- `redundancy_analysis`: `duplicate_groups`
- `recommended_suite`: `add`, `remove`, `modify` arrays

## Incorrect

```json
{
  "suite_health": { "health_grade": "B" },
  "recommended_suite": { "summary": "Add more negative tests" }
}
```

- Error: `recommended_suite` uses a vague summary instead of specific add/remove/modify arrays.
- Cause: Audit produced general advice instead of actionable test-level recommendations.

## Correct

```json
{
  "suite_health": {
    "total_test_cases": 30,
    "coverage_score": 72,
    "health_grade": "C",
    "automation_coverage_pct": 40,
    "issues_summary": ["80% of tests are P3/P4 — insufficient smoke coverage"]
  },
  "recommended_suite": {
    "add": [{ "area": "Password reset", "reason": "No negative-path coverage" }],
    "remove": [{ "id": "TC-012", "reason": "Duplicate of TC-003" }],
    "modify": [{ "id": "TC-005", "change": "Split into two — covers login and logout" }]
  }
}
```

- Each recommendation is specific, traceable, and actionable at the test-case level.

## Why it matters

Vague audit results ("add more tests") leave teams guessing. Specific add/remove/modify actions tied to coverage gaps enable teams to act immediately and measurably improve suite quality.
