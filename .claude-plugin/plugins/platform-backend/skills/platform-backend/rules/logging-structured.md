---
title: Use Structured Logging With Context
impact: HIGH
tags: logging, observability, debugging
---

## Use Structured Logging With Context

Log structured objects with meaningful context, not string concatenation. Structured logs are queryable, filterable, and parseable by log aggregation tools. Always include enough context to debug an issue without reproducing it.

**Incorrect (string concatenation, missing context, wrong level):**

```typescript
// Bad - string concatenation is not queryable
console.log("user created: " + user.email);

// Bad - no context about what failed or who was affected
console.error("Something went wrong");

// Bad - logging sensitive data (see also: security-dont-log-secrets)
console.log("User logged in:", { email, password, sessionToken });

// Bad - using console.log for everything
console.log("Payment failed");
console.log("User signed up");
```

**Correct (structured objects, appropriate levels, context):**

```typescript
// Good - structured with context
logger.info({
  operation: "user.created",
  userId: user.id,
  organizationId: org.id,
});

// Good - error with full debugging context
console.error("Failed to create invitation", {
  operation: "createInvitation",
  error: error instanceof Error ? error.message : error,
  stack: error instanceof Error ? error.stack : undefined,
  userId: ctx.session.user.id,
  organizationId: ctx.organizationId,
  email: input.email,
  role: input.role,
});

// Good - appropriate log levels
console.error("Payment processing failed", { userId, error: error.message }); // Needs attention
console.warn("Rate limit approached", { userId, requestCount });              // Unexpected but handled
console.info("User signed up", { userId, plan });                            // Important business event
console.debug("Query result:", result);                                       // Development only
```

**What to log:**

- Errors and exceptions (with stack traces and context)
- Important business events (user signup, payment processed, invitation accepted)
- External service interactions (API calls, email sends)
- Security-relevant events (login attempts, permission denials)

**What NOT to log:**

- Sensitive data -- passwords, tokens, PII (see [security-dont-log-secrets](./security-dont-log-secrets.md))
- Full request/response bodies (use request IDs for tracing instead)
- Debug statements in production (gate with log level or environment check)
- Every routine success case (use metrics/tracing for volume tracking)

**Context to include:**

- Operation name (what was being attempted)
- User ID and organization ID (who was affected)
- Relevant entity IDs (which records were involved)
- Error message and stack trace (for error logs)
- Sanitized input (never raw secrets or PII)

**Guidelines:**

- Always log objects, never string concatenation
- Use appropriate log levels: error, warn, info, debug
- Include enough context to debug without reproducing the issue
- Keep debug logging out of production -- use environment checks or log-level configuration
- Log the error server-side but return a generic message to the client
