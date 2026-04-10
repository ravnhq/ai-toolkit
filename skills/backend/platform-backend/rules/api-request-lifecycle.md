---
title: Follow Request Lifecycle Order
impact: HIGH
tags: security, api-design, architecture
---

## Follow Request Lifecycle Order

Every API endpoint must process requests in a specific order to prevent security vulnerabilities and ensure correct behavior. The wrong sequence can leak system internals to attackers or process invalid data.

**Incorrect (authentication after validation):**

```typescript
// Bad - validates before authentication
app.post('/api/documents', async (req, res) => {
  // Step 1: Validate input (WRONG - do this after auth!)
  const input = createDocumentSchema.parse(req.body);

  // Step 2: Check authentication
  const user = await verifyAuth(req.headers.authorization);
  if (!user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Step 3: Check authorization
  if (!user.hasPermission('documents:create')) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  // Step 4: Business logic
  const doc = await db.createDocument({ ...input, userId: user.id });
  res.json(doc);
});
```

**Why this is dangerous:** If validation fails (e.g., missing required field), the error message is returned to an unauthenticated user. Error details like "documentTypeId must be UUID" reveal your schema structure to attackers who can probe your API without credentials.

**Correct (proper lifecycle order):**

```typescript
// Good - follows security-first lifecycle
app.post('/api/documents', async (req, res) => {
  // Step 1: Verify authentication
  const user = await verifyAuth(req.headers.authorization);
  if (!user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Step 2: Verify authorization
  if (!user.hasPermission('documents:create')) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  // Step 3: Validate input schema
  const input = createDocumentSchema.parse(req.body);

  // Step 4: Execute business logic
  const doc = await db.createDocument({
    ...input,
    userId: user.id,
    tenantId: user.tenantId, // Filter by tenant
  });

  // Step 5: Log and return
  logger.info('Document created', { documentId: doc.id, userId: user.id });
  res.json(doc);
});
```

**Request Lifecycle Checklist:**

1. **Verify Authentication** - Is the caller who they claim to be?
2. **Verify Authorization** - Does the caller have permission for this action?
3. **Validate Input** - Is the request data valid and safe?
4. **Execute Business Logic** - Perform the requested operation
5. **Log & Return** - Record the action and send response

**Why it matters:**

- **Security**: Prevents information disclosure to unauthenticated users through validation errors
- **Performance**: Rejects unauthorized requests before expensive validation or database queries
- **Correctness**: Ensures tenant filtering happens before queries (multi-tenant safety)
- **Auditability**: Logs always include authenticated user context
- **Defense in depth**: Each layer (auth, authz, validation) provides independent protection

**Common mistakes:**

- Validating before authentication → leaks schema to attackers
- Querying database before authorization → exposes existence of resources
- Forgetting tenant filtering → cross-tenant data leaks
- Logging before authentication → logs contain unauthenticated noise
