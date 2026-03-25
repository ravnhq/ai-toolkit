# Endpoint Blueprint

Use this blueprint for new or refactored endpoints.

## 1. Contract

- Define input schema at the boundary.
- Define output schema (include success and known error shapes).
- Reject unknown fields by default.

## 2. Security

- Verify authentication before business logic.
- Verify authorization for resource/scope access.
- Enforce tenant scoping in every data read/write path.

## 3. Validation and Error Handling

- Validate all external input before executing handlers.
- Use domain-specific error codes/messages.
- Avoid leaking internal stack traces or raw SQL errors to clients.

## 4. Logging and Observability

- Log structured events with request ID/user/tenant context.
- Never log secrets or sensitive payload fields.
- Emit meaningful error context for debugging.

## 5. Implementation Checklist

- [ ] Input schema exists and is enforced.
- [ ] Output schema exists and is enforced.
- [ ] Auth + authorization checks are explicit.
- [ ] Tenant isolation is applied.
- [ ] Error mapping uses domain-specific codes.
- [ ] Structured logs include request context and redact sensitive fields.
