---
title: Evaluation rubric and scoring
impact: MEDIUM
tags:
  - evaluate
  - rubric
  - scoring
---

## Rule

Mode B (Evaluate) scores a test case on a 0–100 scale using a fixed rubric. Every deduction must cite a specific standard rule. An improved version is required when the score is below 80.

## Rubric

| Dimension | Weight |
|---|---|
| Risk Coverage | 20 |
| Clarity | 15 |
| Maintainability | 15 |
| Expected Results | 15 |
| Non-Redundancy | 10 |
| Test Design Technique | 10 |
| Business Alignment | 10 |
| Tagging Compliance | 5 |

## Grades

| Grade | Score range |
|---|---|
| A | ≥ 90 |
| B | ≥ 80 |
| C | ≥ 70 |
| D | ≥ 60 |
| F | < 60 |

## Rule Citation Requirement

Every deduction in `rubric_breakdown` MUST include a `rules_violated` field citing the specific standard (e.g., `"std-behavior-over-ui"`, `"std-measurable-expected-results"`) — generic descriptions without rule citations are not acceptable.

## Improved Version

Include `improved_version` when score < 80, `null` when ≥ 80.

## Output

JSON with `overall_score`, `grade`, `rubric_breakdown`, `top_issues`, `improved_version`.

## Incorrect

```json
{
  "rubric_breakdown": [
    { "dimension": "Clarity", "score": 10, "deduction": 5, "reason": "Steps are vague" }
  ]
}
```

- Error: Deduction has no `rules_violated` field.
- Cause: Reviewer described the issue generically instead of citing the violated standard.

## Correct

```json
{
  "rubric_breakdown": [
    {
      "dimension": "Clarity",
      "score": 10,
      "deduction": 5,
      "reason": "Steps use passive voice and omit the actor",
      "rules_violated": ["std-active-voice-steps"]
    }
  ]
}
```

- Deduction cites the specific rule that was violated, enabling traceable feedback.

## Why it matters

Rule citations make evaluation feedback actionable — the author knows exactly which standard to follow when fixing the test case. Without citations, feedback is subjective and inconsistently applied across reviewers.
