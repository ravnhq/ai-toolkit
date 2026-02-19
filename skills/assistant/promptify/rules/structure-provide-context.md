---
title: Provide Context
impact: HIGH
tags: structure, context, audience
---

## Provide Context

Include audience, domain, and environment background so the AI can calibrate tone, depth, and assumptions.

**Incorrect (no context):**

```markdown
Explain how authentication works.
```

**Correct (context provided):**

```markdown
## Context

Audience: backend developers building a SaaS product with Node.js and Express.
They understand HTTP but have not implemented auth before.
The app uses PostgreSQL and has no existing auth system.

## Task

Explain how to implement JWT-based authentication with refresh tokens.
Cover token generation, validation middleware, and secure storage.
```

**Why it matters:** Without context, the AI guesses at the audience's skill level, the technology stack, and the scope. A prompt about "authentication" could produce anything from a conceptual overview for students to an OAuth2 implementation guide for security engineers. Context eliminates this guesswork.
