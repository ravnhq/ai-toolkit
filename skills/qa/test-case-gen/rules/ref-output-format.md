---
title: Output format and file output rules
impact: HIGH
tags:
  - output
  - csv
  - json
  - xml
  - file
  - slug
---

## Output Format

Modes A and D: default CSV; support JSON and XML on request. Modes B and C: inline JSON only.

**CSV encoding rules:**

| Field | Encoding |
|---|---|
| `preconditions` | Pipe-delimited list |
| `steps` | Pipe-delimited `"1. Action >> Expected result"` strings |
| `tags` | Comma-delimited |
| `automation_candidate` | Literal string `"true"` or `"false"` |

## File vs. Inline Split (Modes A and D)

The output file must contain **test case data only** — no wrapper object, no summaries. This ensures the file is directly importable into test case management tools (TestRail, Zephyr, qTest, etc.).

| Content | Where it goes |
|---|---|
| Selected test cases | Output file (`{feature-slug}-test-cases.{format}`) |
| `coverage_summary` (Mode A) | Inline in the chat response |
| `normalization_summary` (Mode D) | Inline in the chat response |
| Included/excluded counts | Inline in the chat response |

**JSON file structure:** a flat array of test case objects — no wrapper.
**CSV file structure:** header row + one row per test case — no summary rows.
**XML file structure:** `<test_cases>` root with `<test_case>` children — no summary elements.

## File Output (Modes A and D)

Save to: `templates/test-case-gen/output/{feature-slug}-test-cases.{format}`

Example: `forgot-password-test-cases.json`

**Slug derivation (in order):**
1. Kebab-case the user-provided feature name.
2. If URL input: use the last meaningful path segment.
3. If HTML input with a `<title>`: kebab-case the title text.
4. Fallback: `feature`.

After saving, provide a download link.

If `templates/test-case-gen/output/` is not writable, deliver inline and note: "File output unavailable — delivering inline. Save manually."
