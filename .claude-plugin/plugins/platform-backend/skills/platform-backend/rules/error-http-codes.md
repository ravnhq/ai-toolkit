---
title: Use Appropriate HTTP Status Codes
impact: HIGH
tags: error, api, http
---

## Use Appropriate HTTP Status Codes

Return the correct HTTP status code for each error type. Don't use 200 for errors or 500 for validation failures.

**Common status codes:**

| Code | Name | Use Case |
|------|------|----------|
| 200 | OK | Successful GET, PUT |
| 201 | Created | Successful POST that creates resource |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid input, validation failed |
| 401 | Unauthorized | Not authenticated (no/invalid session) |
| 403 | Forbidden | Authenticated but not permitted |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate, already exists |
| 422 | Unprocessable Entity | Semantic validation failed |
| 500 | Internal Server Error | Unexpected server error |

**Incorrect (wrong codes):**

```typescript
// Bad - 200 for error
return res.status(200).json({ success: false, error: 'Not found' });

// Bad - 500 for validation
if (!email.includes('@')) {
  return res.status(500).json({ error: 'Invalid email' });
}

// Bad - 401 when 403 is correct
if (!user.isAdmin) {
  return res.status(401).json({ error: 'Admin only' });
}
```

**Correct (appropriate codes):**

```typescript
// Good - 404 for not found
if (!resource) {
  return res.status(404).json({ error: 'Resource not found' });
}

// Good - 400 for validation
if (!email.includes('@')) {
  return res.status(400).json({ error: 'Invalid email format' });
}

// Good - 403 for permission denied (user IS authenticated)
if (!user.isAdmin) {
  return res.status(403).json({ error: 'Admin access required' });
}

// Good - 409 for conflict
if (existingUser) {
  return res.status(409).json({ error: 'Email already registered' });
}
```

**Why it matters:**
- Clients rely on status codes for error handling
- 401 vs 403 distinction affects redirect behavior
- Proper codes enable automatic retry logic (5xx might retry, 4xx won't)
- API consumers expect standard HTTP semantics
