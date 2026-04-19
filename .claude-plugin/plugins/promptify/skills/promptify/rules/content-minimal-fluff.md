---
title: Minimal Fluff
impact: MEDIUM
tags: content, brevity, specification
---

## Minimal Fluff

Remove politeness, filler phrases, and conversational padding. Treat prompts as specifications, not conversations.

**Incorrect (conversational fluff):**

```markdown
Hey! I was wondering if you could help me out with something.
I'd really appreciate it if you could write a function that
validates email addresses. It would be great if it could handle
edge cases too. Thanks so much in advance!
```

**Correct (specification language):**

```markdown
Write a TypeScript function `validateEmail(input: string): boolean` that:

- Accepts: standard emails (user@domain.tld), subaddresses (user+tag@domain.tld)
- Rejects: missing @, missing domain, consecutive dots, spaces
- Returns `true` for valid, `false` for invalid
- No regex longer than 80 characters; prefer structured parsing
```

**Why it matters:** Every token of politeness and filler is a token not spent on specification. "It would be great if it could handle edge cases" adds zero information — the correct version names the exact edge cases. Specifications are unambiguous; conversations are not.
