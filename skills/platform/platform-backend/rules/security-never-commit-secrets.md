---
title: Never Commit Secrets
impact: CRITICAL
tags: security, secrets, git
---

## Never Commit Secrets

Never commit API keys, database URLs, auth secrets, or any credentials to version control.

**Incorrect (secrets in code):**

```typescript
// NEVER DO THIS
const STRIPE_KEY = 'sk_live_abc123...';
const DATABASE_URL = 'postgres://user:password@host/db';

export const config = {
  stripe: { apiKey: STRIPE_KEY },
  database: { url: DATABASE_URL },
};
```

**Correct (use environment variables):**

```typescript
// Good - read from environment
const config = {
  stripe: { apiKey: process.env.STRIPE_SECRET_KEY },
  database: { url: process.env.DATABASE_URL },
};

// Validate required env vars at startup
function validateEnv() {
  const required = ['DATABASE_URL', 'STRIPE_SECRET_KEY', 'AUTH_SECRET'];
  const missing = required.filter(key => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing env vars: ${missing.join(', ')}`);
  }
}
```

**.gitignore setup:**

```gitignore
# Environment files
.env
.env.local
.env.*.local

# Never commit these
*.pem
*.key
credentials.json
```

**Why it matters:**
- Git history is permanent - secrets remain even after deletion
- Bots scan GitHub for leaked keys within minutes
- Leaked database URLs enable direct data access
- Leaked API keys can result in huge bills or data breaches

Reference: [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
