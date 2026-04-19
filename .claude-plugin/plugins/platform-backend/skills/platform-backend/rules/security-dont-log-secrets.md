---
title: Never Log Sensitive Data
impact: HIGH
tags: security, logging, privacy
---

## Never Log Sensitive Data

Logs should aid debugging without exposing sensitive information.

**Incorrect (logging sensitive data):**

```typescript
// Bad - logs secrets and PII
console.log('Connecting with:', process.env.DATABASE_URL);
console.log('User login:', { email, password });
console.log('API key:', apiKey);
console.log('User data:', user); // Might include password hash
```

**Correct (safe logging):**

```typescript
// Good - log identifiers, not secrets
console.log('Connecting to database...');
console.log('User login attempt:', { email, ip: req.ip });
console.log('API request:', { endpoint, userId: user.id });

// Redact sensitive fields
function safeLog(obj: Record<string, unknown>) {
  const sensitive = ['password', 'token', 'secret', 'apiKey', 'authorization'];
  return Object.fromEntries(
    Object.entries(obj).map(([k, v]) =>
      sensitive.some(s => k.toLowerCase().includes(s))
        ? [k, '[REDACTED]']
        : [k, v]
    )
  );
}

console.log('Request:', safeLog(requestData));
```

**What NOT to log:**

- Passwords (even hashed)
- API keys and tokens
- Full credit card numbers
- Social security numbers
- Database connection strings
- Session tokens

**Why it matters:**
- Logs are often stored in less secure systems
- Log aggregation services may be compromised
- Developers with log access shouldn't see user passwords
- Compliance regulations (GDPR, PCI) restrict PII in logs

Reference: [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
