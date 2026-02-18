---
title: Repository Per Slice
impact: MEDIUM
tags: data-access, repository, organization
---

## Repository Per Slice

Each slice has its own repository containing only the queries that slice needs. Avoid god-object repositories with dozens of methods.

**Incorrect (god-object repository):**

```typescript
// repositories/invitations.repository.ts
// 500 lines, 30 methods
export async function findAll(db: Database) { ... }
export async function findById(db: Database, id: string) { ... }
export async function findByToken(db: Database, token: string) { ... }
export async function findByEmail(db: Database, email: string) { ... }
export async function findPending(db: Database, orgId: string) { ... }
export async function findExpired(db: Database) { ... }
export async function create(db: Database, data: NewInvitation) { ... }
export async function update(db: Database, id: string, data: Partial<Invitation>) { ... }
export async function markAccepted(db: Database, id: string) { ... }
export async function markRevoked(db: Database, id: string) { ... }
// ... 20 more methods, many unused
```

**Correct (repository per slice):**

```typescript
// features/invitations/create/create.repository.ts
export async function insertInvitation(db: Database, data: NewInvitation) {
  const [invitation] = await db.insert(invitations).values(data).returning();
  return invitation;
}

export async function findExistingInvitation(
  db: Database,
  email: string,
  organizationId: string,
) {
  return db.query.invitations.findFirst({
    where: (inv, { and, eq }) =>
      and(
        eq(inv.email, email),
        eq(inv.organizationId, organizationId),
        eq(inv.status, 'PENDING'),
      ),
  });
}

// features/invitations/accept/accept.repository.ts
export async function findInvitationByToken(db: Database, token: string) {
  return db.query.invitations.findFirst({
    where: (inv, { eq }) => eq(inv.token, token),
  });
}

export async function markInvitationAccepted(db: Database, id: string) {
  await db.update(invitations)
    .set({ status: 'ACCEPTED', acceptedAt: new Date() })
    .where(eq(invitations.id, id));
}
```

**Why it matters:** Slice-scoped repositories are small, focused, and easy to test. You can see all the data access for a feature in one place. No hunting through a 500-line file.
