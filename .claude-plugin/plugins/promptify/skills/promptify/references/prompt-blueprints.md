# Prompt Blueprints

Reusable four-block skeletons for common prompt types. Fill in the bracketed placeholders, remove any blocks that don't add clarity, and run through the self-check before delivery.

---

## 1. Code Review

```markdown
## Context

Language: [LANGUAGE]
Framework: [FRAMEWORK and version]
Scope: [PR description or file list]
Team conventions: [link to style guide or key rules]

## Task

Review this code in three passes:

1. **Correctness** — logic errors, off-by-one bugs, missing edge cases. List each with file and line number.
2. **Security** — injection vectors, hardcoded secrets, missing input validation, auth bypasses.
3. **Style** — deviations from project conventions (naming, file structure, import order). Ignore personal preferences.

## Constraints

- Severity labels: P0 (must fix before merge), P1 (fix soon), P2 (nice to have)
- Skip: test file formatting, comment style, whitespace
- If no issues found in a pass, state "No issues found" instead of inventing nitpicks

## Output Format

Per finding:
- **[P0/P1/P2]** `file:line` — one-sentence description
- Suggested fix (code snippet if applicable)

Summary at the end: total findings by severity, ship/no-ship recommendation.
```

---

## 2. Content Creation

```markdown
## Context

Audience: [WHO — role, experience level, what they already know]
Platform: [WHERE — blog, docs, email, social]
Tone: [HOW — technical but accessible, casual, formal, etc.]

## Task

Write [CONTENT TYPE] about [TOPIC] covering:

1. [SUBTOPIC 1]
2. [SUBTOPIC 2]
3. [SUBTOPIC 3]

## Constraints

- Length: [WORD COUNT RANGE]
- [TERMINOLOGY RULES — define jargon? avoid acronyms?]
- [STYLE RULES — active voice? no first person?]
- [THINGS TO SKIP — don't cover X, Y]

## Output Format

[FORMAT DETAILS — markdown with H2 headings, bullet lists for key points, code blocks for examples, etc.]
```

---

## 3. Debugging

```markdown
## Context

Environment: [OS, runtime, framework, versions]
Error: [EXACT error message or unexpected behavior]
Reproduction: [Steps to trigger the issue, or "intermittent"]
What I've tried: [PRIOR ATTEMPTS and their results]

## Task

1. Diagnose the root cause of this error
2. Explain why it happens (the mechanism, not just "it's a bug")
3. Provide a fix with the minimal set of changes
4. Identify if other code paths have the same vulnerability

## Constraints

- Preserve existing behavior — fix only the bug, don't refactor
- If multiple root causes are possible, list each with likelihood
- If the fix has tradeoffs, state them

## Output Format

- **Root cause:** one paragraph
- **Fix:** code diff or snippet
- **Verification:** how to confirm the fix works
- **Related risks:** other places the same pattern appears
```

---

## 4. Data Analysis

```markdown
## Context

Dataset: [DESCRIPTION — what it contains, how many rows/columns, source]
Business question: [WHAT DECISION does this analysis support?]
Tools available: [SQL? Python/pandas? R? Spreadsheet?]

## Task

Analyze [DATASET] to answer: [SPECIFIC QUESTION]

Include:
1. Data quality check (nulls, outliers, duplicates)
2. Core analysis answering the business question
3. [ADDITIONAL ANALYSIS — trends, segments, correlations]

## Constraints

- Statistical rigor: [confidence level, significance threshold, sample size notes]
- Visualizations: [required charts — bar, line, scatter, etc.]
- Assumptions: [state any assumptions about the data]
- Skip: [what is out of scope]

## Output Format

1. **Summary** — 3-5 bullet points answering the business question
2. **Methodology** — one paragraph on approach
3. **Findings** — detailed analysis with charts/tables
4. **Recommendations** — actionable next steps based on findings
5. **Caveats** — limitations and what would strengthen the analysis
```

---

## 5. Research

```markdown
## Context

Domain: [FIELD or topic area]
Prior knowledge: [WHAT I already know — prevents the model from repeating basics]
Purpose: [WHY I need this — decision to make, article to write, problem to solve]

## Task

Investigate [RESEARCH QUESTION] covering:

1. [ANGLE 1 — e.g., current state of the art]
2. [ANGLE 2 — e.g., tradeoffs between approaches]
3. [ANGLE 3 — e.g., practical recommendations]

## Constraints

- Source quality: [peer-reviewed only? include blog posts? recency requirements?]
- Depth: [survey-level overview or deep technical dive?]
- Bias: [present all sides or recommend a winner?]
- Length: [WORD COUNT RANGE]

## Output Format

- **Executive summary** — 2-3 sentences answering the research question
- **Detailed findings** — one section per angle, with inline citations
- **Comparison table** — if comparing approaches/tools/options
- **Recommendation** — what to do based on the findings
- **Sources** — list of references used
```
