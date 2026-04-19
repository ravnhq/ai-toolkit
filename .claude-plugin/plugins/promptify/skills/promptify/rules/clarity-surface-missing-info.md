---
title: Surface Missing Information
impact: CRITICAL
tags: clarity, gaps, completeness, placeholders
---

## Surface Missing Information

Detect when a user's request omits key inputs (audience, tech stack, scope, environment) and either insert explicit placeholders or ask follow-up questions before rewriting.

**Incorrect (inheriting the blind spot):**

```markdown
Original: "Write a tutorial on hooks."

Rewritten:
## Context
This tutorial covers hooks for developers.

## Task
Write a tutorial explaining hooks with code examples.

## Constraints
- Keep it beginner-friendly
- Include code examples

## Output Format
Markdown with H2 headings and code blocks.
```

The rewrite is better structured but still does not specify: which framework's hooks (React? Vue? Git?), who the audience is (junior dev? senior switching stacks?), or what hooks to cover.

**Correct (gaps surfaced as placeholders or questions):**

```markdown
Original: "Write a tutorial on hooks."

Missing information detected:
- Framework: React? Vue? Git? [FRAMEWORK: specify]
- Audience: What experience level? [AUDIENCE: specify]
- Scope: Which hooks? All of them, or a subset? [HOOKS: specify]
- Length: Blog post? Chapter? Quick reference? [FORMAT: specify]

Rewritten (with placeholders):
## Context
Target audience: [AUDIENCE: e.g., junior developers with HTML/CSS experience].
Framework: [FRAMEWORK: e.g., React 18].

## Task
Write a tutorial covering [HOOKS: e.g., useState, useEffect, useRef] with:
1. What each hook does and when to use it
2. A runnable code example per hook
3. Common mistakes for each

## Constraints
- [LENGTH: e.g., 800-1200 words]
- Define each hook on first use
- No jargon without inline definitions

## Output Format
Markdown with H2 per hook. Code blocks use `tsx` syntax highlighting.
```

**Why it matters:** Polishing the phrasing of an incomplete request produces a well-structured but still ambiguous prompt. The downstream model fills in the blanks silently, often guessing wrong. Surfacing gaps forces the user to make explicit choices, which produces a prompt that works on the first attempt.
