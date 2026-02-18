---
title: Four-Block Pattern
impact: HIGH
tags: structure, organisation, pattern
---

## Four-Block Pattern

Organise prompts into up to four distinct blocks: Context, Task, Constraints, and Output Format. Not every prompt needs all four — use only what adds clarity.

**Incorrect (unstructured wall of text):**

```markdown
I need you to write a blog post about React hooks. It should be beginner-friendly
and around 1000 words. Make sure to include code examples and explain useState
and useEffect. Don't use jargon. Format it nicely.
```

**Correct (four-block structure):**

```markdown
## Context

Target audience: junior developers with HTML/CSS experience but no React knowledge.
Publishing platform: company engineering blog (technical but accessible tone).

## Task

Write a tutorial introducing React's `useState` and `useEffect` hooks. Cover:

1. What hooks are and why they exist
2. `useState` with a counter example
3. `useEffect` with a data-fetching example
4. Common mistakes (stale closures, missing dependencies)

## Constraints

- 800-1200 words
- No jargon without inline definitions
- Each hook gets a runnable code example

## Output Format

Markdown with H2 headings per section. Code blocks use `tsx` syntax highlighting.
```

**Why it matters:** Structured prompts reduce ambiguity by separating what the AI needs to know (context) from what it needs to do (task), within what boundaries (constraints), and in what shape (output format). Unstructured prompts force the model to infer all four, increasing the chance of misinterpretation.
