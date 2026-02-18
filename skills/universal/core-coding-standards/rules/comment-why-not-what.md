---
title: Comment the Why, Never the What
impact: MEDIUM
tags: comments, documentation, readability
---

## Comment the Why, Never the What

Self-documenting code is the goal. Comments are a last resort, not a first choice. When you do comment, explain the *why* (intent, trade-offs, workarounds), never the *what* (the code already says what it does).

**Incorrect (commenting the obvious, stale TODOs, commented-out code):**

```typescript
// Bad - states the obvious
// Loop through users
for (const user of users) {
}

// Bad - describes what, not why
// Set status to active
user.status = "active";

// Bad - stale TODO without actionable context
// TODO: fix this later

// Bad - commented-out code (use git history instead)
// const oldValue = calculateLegacy(input);
// if (oldValue !== newValue) { ... }
```

**Correct (explaining why, concise JSDoc where needed):**

```typescript
// Good - explains why, not what
// Skip deactivated users to avoid sending them notifications
if (user.status === "deactivated") continue;

// Good - explains a non-obvious pattern
// Match ISO 8601 duration format (e.g., "PT2H30M")
const durationRegex = /^PT(\d+H)?(\d+M)?(\d+S)?$/;

// Good - JSDoc on exported function where name + types aren't sufficient
/**
 * Sends invitation email and creates audit log entry.
 * @throws {InvitationExpiredError} If invitation has expired
 */
export async function sendInvitation(invitationId: string): Promise<void> {
  // ...
}

// Good - no JSDoc needed when signature is self-explanatory
export function formatCurrency(amount: number, currency: string): string {
  // ...
}
```

**Guidelines:**

- Write clear names and small functions so comments become unnecessary
- Comment the *why*: intent, trade-offs, workarounds, non-obvious business logic
- Use JSDoc sparingly -- only on exported functions where the name and types are not sufficient
- Never commit commented-out code -- that is what git history is for
- No stale TODOs -- every TODO must have actionable context (ticket number, owner, or specific next step), or be removed
- Keep comments concise -- if you need a paragraph, the code is probably too complex
