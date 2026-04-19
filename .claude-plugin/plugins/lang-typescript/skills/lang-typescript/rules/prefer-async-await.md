---
title: Prefer async/await Over .then() Chains
impact: MEDIUM
tags: async, promises, readability
---

## Prefer async/await Over .then() Chains

Use async/await for asynchronous code. It reads top-to-bottom, handles errors naturally with try/catch, and avoids callback nesting. Use `Promise.all()` for independent parallel operations and `Promise.allSettled()` when you need results from all promises even if some fail. Never use raw callbacks when promises are available.

**Incorrect (nested .then() chains):**

```typescript
// Bad - chained .then() is harder to read and debug
function loadUserDashboard(userId: string) {
  return db.query.users.findFirst({ where: eq(users.id, userId) })
    .then(user => {
      return db.query.organizations.findFirst({ where: eq(orgs.id, user.orgId) })
        .then(org => {
          return db.query.posts.findMany({ where: eq(posts.orgId, org.id) })
            .then(posts => {
              return { user, org, posts };
            });
        });
    })
    .catch(error => {
      console.error("Failed:", error);
      throw error;
    });
}
```

**Correct (async/await with try/catch, Promise.all for parallel):**

```typescript
// Good - sequential when operations depend on each other
async function getUser(userId: string) {
  try {
    const user = await db.query.users.findFirst({ where: eq(users.id, userId) });
    if (!user) throw new NotFoundError("User not found");

    const org = await db.query.organizations.findFirst({
      where: eq(orgs.id, user.orgId),
    });

    return { user, org };
  } catch (error) {
    console.error("Failed to load user", { userId, error: error.message });
    throw error;
  }
}

// Good - parallel when operations are independent
async function loadDashboard(userId: string, orgId: string) {
  const [user, org, posts] = await Promise.all([
    db.query.users.findFirst({ where: eq(users.id, userId) }),
    db.query.organizations.findFirst({ where: eq(orgs.id, orgId) }),
    db.query.posts.findMany({ where: eq(posts.orgId, orgId) }),
  ]);

  return { user, org, posts };
}

// Good - allSettled when you need results even if some fail
async function sendNotifications(userIds: string[]) {
  const results = await Promise.allSettled(
    userIds.map(id => notifyUser(id)),
  );

  const failures = results.filter(r => r.status === "rejected");
  if (failures.length > 0) {
    console.warn("Some notifications failed", { failureCount: failures.length });
  }
}
```

**Guidelines:**

- Always use async/await instead of `.then()` chains
- Use `Promise.all()` when multiple independent operations can run in parallel
- Use `Promise.allSettled()` when you need all results regardless of individual failures
- Never use raw callbacks (e.g., `fs.readFile(path, callback)`) when a promise-based API is available
