---
title: Mode A output schema — Generate
impact: HIGH
tags:
  - schema
  - generate
  - json
  - output
---

## Test Case Fields (required per test case)

| Field | Notes |
|---|---|
| `id` | Unique identifier |
| `title` | Descriptive test case title |
| `objective` | Single observable outcome being validated |
| `platform` | `web` / `ios` / `android` / `cross-platform` |
| `preconditions` | All required setup state |
| `steps` | Array of objects: `step` (number), `action`, `expected_result` |
| `expected_result` | Final observable outcome |
| `risk_level` | `High` / `Medium` / `Low` |
| `priority` | `P1` / `P2` / `P3` / `P4` |
| `type` | See Field Reference |
| `automation_candidate` | `true` or `false` |
| `tags` | Required tags per `std-mandatory-tagging.md` |

## Output File Structure

The output file contains **only** test case data — a flat array (JSON), rows (CSV), or `<test_case>` elements (XML). No wrapper object or summary. This keeps the file directly importable into test case management tools.

## Coverage Summary (delivered inline, not in file)

The following fields are delivered in the chat response after the file is saved. Counts must reflect only the test cases the user selected in the preview step.

| Field | Notes |
|---|---|
| `release_type` | `Hotfix` / `Sprint` / `Major` |
| `feature` | Feature or story name |
| `coverage_strategy` | Techniques applied (EP, BVA, State Transition) |
| `happy_path_count` | Count of happy path tests |
| `negative_count` | Count of negative tests |
| `edge_case_count` | Count of edge case tests |
| `integration_count` | Count of integration tests |
| `total` | Total selected test count |
| `excluded` | Count of test cases the user unchecked |
| `p1_count` | Count of P1 priority tests |
| `p2_count` | Count of P2 priority tests |
| `automation_candidates` | Count of automation-candidate tests |
| `input_source` | `"url"` / `"html"` / `"text"` |
