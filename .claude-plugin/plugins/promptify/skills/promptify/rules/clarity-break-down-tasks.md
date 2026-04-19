---
title: Break Down Tasks
impact: HIGH
tags: clarity, steps, decomposition
---

## Break Down Tasks

Split complex tasks into numbered sequential steps so the AI follows a predictable path.

**Incorrect (single monolithic instruction):**

```markdown
Review this pull request and give me feedback.
```

**Correct (sequential steps):**

```markdown
Review this pull request in three steps:

1. **Correctness** - Identify logic errors, off-by-one bugs, or missing edge cases. List each with the file and line number.
2. **Style** - Flag deviations from the project's existing patterns (naming conventions, file structure, import order). Ignore personal preferences.
3. **Security** - Check for injection vulnerabilities, hardcoded secrets, or missing input validation.

For each finding, provide:
- File and line number
- What the issue is (one sentence)
- Suggested fix (code snippet if applicable)
```

**Why it matters:** Monolithic instructions let the AI choose its own review strategy, which may skip categories entirely or blend them together. Numbered steps ensure completeness and make the output scannable. Each step acts as a checkpoint the AI must address.
