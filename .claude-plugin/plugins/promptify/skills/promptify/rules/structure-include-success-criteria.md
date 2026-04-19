---
title: Include Success Criteria
impact: HIGH
tags: structure, criteria, acceptance, definition-of-done
---

## Include Success Criteria

Every rewritten prompt should define what a good answer must include, what it must avoid, or both. Success criteria turn subjective quality into a checkable list.

**Incorrect (no success criteria):**

```markdown
Write a function that validates email addresses.
Handle edge cases.
```

"Handle edge cases" is not actionable. The model decides which edge cases matter, and its choices may not match the user's expectations.

**Correct (explicit success criteria):**

```markdown
Write a TypeScript function `validateEmail(input: string): boolean`.

Must accept:
- Standard format: user@domain.tld
- Subaddresses: user+tag@domain.tld
- Dots in local part: first.last@domain.tld

Must reject:
- Missing @ symbol
- Missing domain
- Consecutive dots in local part
- Spaces anywhere in the string
- Domain without TLD

Returns `true` for valid, `false` for invalid.
No external dependencies.
```

**Correct (success criteria for non-code tasks):**

```markdown
Write a product comparison of Postgres vs MySQL for a SaaS startup.

The reader should be able to:
- Choose a database for a new project after reading this
- Understand the tradeoff in 3 specific areas: JSON support, replication, and hosted pricing
- See a decision matrix at the end with clear recommendations per use case

Avoid: marketing language, unsupported claims, "it depends" without specifics.
```

**Why it matters:** Without success criteria, the model optimises for plausibility instead of correctness. "Write a function that validates emails" can produce a regex that matches 80% of cases and silently fails on the rest. Success criteria make the output testable: did it accept subaddresses? Did it reject consecutive dots? The user can verify the output against the criteria instead of guessing whether it is good enough.
