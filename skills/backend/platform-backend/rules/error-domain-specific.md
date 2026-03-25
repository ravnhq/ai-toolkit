---
title: Use Domain-Specific Error Classes
impact: HIGH
tags: error, design, maintainability
---

## Use Domain-Specific Error Classes

Create custom error classes for domain-specific error cases. Don't use generic errors everywhere.

**Incorrect (generic errors):**

```typescript
// Bad - generic errors, inconsistent codes
if (!user) {
  throw new Error('User not found');
}

if (invitation.status !== 'PENDING') {
  throw new Error('Bad request');
}

if (!isAdmin) {
  throw new Error('Forbidden');
}
```

**Correct (domain-specific errors):**

```typescript
// Define domain errors
class NotFoundError extends BaseError {
  constructor(resource: string, id: string) {
    super({
      code: 'NOT_FOUND',
      status: 404,
      message: `${resource} not found`,
    });
  }
}

class InvitationExpiredError extends BaseError {
  constructor() {
    super({
      code: 'INVITATION_EXPIRED',
      status: 400,
      message: 'Invitation has expired',
    });
  }
}

class ForbiddenError extends BaseError {
  constructor(message = 'You do not have permission') {
    super({
      code: 'FORBIDDEN',
      status: 403,
      message,
    });
  }
}

// Usage is clear and consistent
if (!user) throw new NotFoundError('User', input.userId);
if (invitation.expiresAt < new Date()) throw new InvitationExpiredError();
if (!isAdmin) throw new ForbiddenError('Admin access required');
```

**Why it matters:**
- Consistent error handling across the codebase
- Clients can reliably handle specific error types
- Error messages are centralized and consistent
- Easier to add logging, metrics, or translations
