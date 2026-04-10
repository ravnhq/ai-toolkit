---
name: tech-trpc
description: 'tRPC end-to-end typesafe APIs. Router architecture, procedure design,
  middleware chaining, input validation with Zod, error handling, and Vertical Slice
  Architecture. Use when building tRPC APIs, designing procedures, structuring backend
  slices, or handling cross-procedure logic.

  '
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
metadata:
  category: backend
  extends: platform-backend
  tags:
  - trpc
  - api
  - rpc
  - web
  - typescript
  - middleware
  - error-handling
  - validation
  status: ready
  version: 6
---

# tRPC End-to-End Typesafe APIs

Type-safe remote procedure calls with full client-server type inference. No code generation needed. tRPC excels at:
- **Zero API generation** — Shared types between client and server; type-safe mutations/queries by default
- **Middleware composition** — Chain middlewares with `unstable_pipe()` for authentication, logging, authorization
- **Input validation** — Zod schema validation with auto-formatted error responses
- **Error handling** — Domain-specific `TRPCError` codes mapped to HTTP status automatically
- **Vertical Slice pattern** — Organize by feature (slice), not layer; each slice owns procedures, schemas, data access

Core patterns: procedures (queries/mutations) in routers, input/output schemas for contracts, middleware for cross-cutting concerns, domain errors with proper codes.

## Workflow

When designing tRPC APIs:

1. **Define the slice** — Which feature? (e.g., `invitations`, `payments`, `users`)
2. **Schema first** — Input schema with Zod, output schema for response contract
3. **Create procedures** — Query, mutation, or subscription with `.procedure.input().query()`
4. **Add middleware** — Authentication, logging, authorization; chain with `unstable_pipe()`
5. **Error handling** — Throw `TRPCError` with domain-specific codes, not plain Error
6. **Organize** — One file per procedure; repository per slice; no cross-slice imports

## Rules

Patterns are organized by concern:

- **Architecture** — Vertical Slice pattern, one procedure per file, feature isolation
- **Procedures** — Query, mutation, subscription; procedure hierarchy and composition
- **Schemas** — Zod input/output validation; always define schemas
- **Middleware** — Authentication, logging, context enrichment; unstable_pipe chaining
- **Error Handling** — Domain-specific errors, proper TRPCError codes, error formatting
- **Data Access** — Repository pattern per slice; data layer isolation

See `rules/` for implementation patterns and examples.

## Examples

### Positive Trigger

User: "Add a tRPC mutation for creating invoices with Zod input validation."

Expected behavior: Use `tech-trpc` guidance, apply procedure design with Zod schema and proper error handling.

### Non-Trigger

User: "Write a Python Flask endpoint for file uploads."

Expected behavior: Do not prioritize `tech-trpc`; choose a more relevant skill or proceed without it.

- Error: Throwing plain Error in procedures
- Cause: Plain errors become INTERNAL_SERVER_ERROR (500); clients cannot distinguish errors
- Solution: Throw `TRPCError` with domain code: `throw new TRPCError({ code: 'NOT_FOUND', message: '...' })`

- Error: Middlewares not chaining properly; context lost
- Cause: Middlewares not piped with `unstable_pipe()`; context isolation between middleware layers
- Solution: Use `.unstable_pipe()` to chain middleware and extend context

## Troubleshooting

- Error: Client receives generic "Input validation failed"
- Cause: No custom `errorFormatter` configured; Zod errors not sent to client
- Solution: Configure `initTRPC.create({ errorFormatter })` to flatten Zod errors in response

- Error: Middleware context not accessible in procedure
- Cause: Middleware not piped or context not merged in `opts.next()`
- Solution: Ensure middleware returns `opts.next({ ctx: { ...prevCtx, newKey: value } })`

- Error: Procedure types leak into client; can import server code
- Cause: Exporting procedure instance instead of type; `typeof appRouter` not used
- Solution: Export only `type AppRouter = typeof appRouter`; client imports type only
