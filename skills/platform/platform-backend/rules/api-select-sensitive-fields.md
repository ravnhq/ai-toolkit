---
title: Explicitly Select Columns, Exclude Sensitive Fields
impact: HIGH
tags: security, api, database
---

## Explicitly Select Columns, Exclude Sensitive Fields

Never return all columns from database queries. Explicitly select what's needed and exclude sensitive data.

**Incorrect (returns everything):**

```typescript
// Bad - includes password_hash, reset_token, etc.
export const getUser = protectedProcedure
  .query(async ({ ctx }) => {
    return db.findUser(ctx.userId);
  });

// Bad - spread exposes internal fields
const user = await db.findUser(id);
return { ...user, computedField: 'value' };
```

**Correct (explicit selection):**

```typescript
// Good - select only needed columns
export const getUser = protectedProcedure
  .query(async ({ ctx }) => {
    return db.query.users.findFirst({
      where: eq(users.id, ctx.userId),
      columns: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        createdAt: true,
        // Explicitly NOT included: passwordHash, resetToken, etc.
      },
    });
  });

// Good - construct response explicitly
const user = await db.findUser(id);
return {
  id: user.id,
  email: user.email,
  name: user.name,
  // Only include what's needed
};
```

**Fields to NEVER expose:**

- Password hashes
- Reset tokens / magic links
- API keys / secrets
- Internal IDs (if using public-facing IDs)
- Deleted/banned reasons (internal notes)
- Full audit logs

**Why it matters:**
- Accidentally exposed password hashes can be cracked
- Reset tokens enable account takeover
- Internal fields leak system architecture
- GDPR/privacy - minimize data exposure
