---
title: Don't Expose Internal Details in Errors
impact: HIGH
tags: security, errors, information-leakage
---

## Don't Expose Internal Details in Errors

Error responses should be helpful for users but not reveal system internals to attackers.

**Incorrect (leaking internals):**

```typescript
// Bad - exposes stack trace
catch (error) {
  return res.status(500).json({
    error: error.stack,
    query: 'SELECT * FROM users WHERE id = $1',
    path: '/var/app/src/users/repository.ts:42'
  });
}

// Bad - reveals user existence
if (!user) throw new Error('User not found');
if (!passwordMatch) throw new Error('Incorrect password');
// Attacker learns valid emails by different error messages
```

**Correct (generic messages, internal logging):**

```typescript
// Good - generic user message, detailed internal log
catch (error) {
  // Log full details for debugging
  console.error('Database error:', {
    error: error.message,
    stack: error.stack,
    userId: input.userId,
  });

  // Return generic message to client
  throw new InternalError('An unexpected error occurred');
}

// Good - don't reveal user existence
if (!user || !passwordMatch) {
  throw new AuthError('Invalid email or password');
}
```

**What NOT to expose:**

- Stack traces and file paths
- Database errors and query details
- Internal IP addresses
- Library versions
- User existence (different errors for "not found" vs "wrong password")

**Why it matters:** Detailed error messages help attackers understand your system. Stack traces reveal file structure and library versions. Different errors for "user not found" vs "wrong password" enable email enumeration attacks.

Reference: [OWASP Error Handling](https://owasp.org/www-community/Improper_Error_Handling)
