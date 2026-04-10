---
title: State Assumptions Explicitly
impact: HIGH
tags: constraints, assumptions, placeholders, transparency
---

## State Assumptions Explicitly

When the rewritten prompt makes assumptions about technology, environment, audience, or scope, mark each assumption visibly so the user can verify or correct them before use.

**Incorrect (silent assumptions):**

```markdown
Original: "Help me build an API for user management."

Rewritten:
## Task
Build a REST API with Express.js and PostgreSQL for user management.
Include endpoints for CRUD operations with JWT authentication.
Use Prisma as the ORM.
```

This silently chose: REST (not GraphQL), Express (not Fastify/Hono), PostgreSQL (not MySQL/MongoDB), JWT (not sessions), Prisma (not Drizzle/Knex). The user may not notice these choices until they are deep into implementation.

**Correct (assumptions marked):**

```markdown
Original: "Help me build an API for user management."

Rewritten:
## Context
[Assumption: Node.js backend — change if using a different runtime]
[Assumption: PostgreSQL database — change if using MySQL, MongoDB, etc.]

## Task
Build a [Assumption: REST] API with [Assumption: Express.js] for user management:
1. CRUD endpoints: create, read, update, delete users
2. Authentication: [Assumption: JWT with refresh tokens]
3. Input validation on all endpoints
4. Error responses following RFC 7807 Problem Details

## Constraints
- ORM: [Assumption: Prisma — change if using Drizzle, Knex, or raw SQL]
- Password hashing: bcrypt with cost factor 12
- Rate limiting on auth endpoints
```

**Why it matters:** Every assumption is a decision the user did not make. Silent assumptions produce prompts that look complete but encode hidden choices. When those choices are wrong, the user discovers it late, in the output, not in the prompt. Marking assumptions surfaces decisions upfront, where they are cheap to change.
