---
name: tech-drizzle
description: 'Drizzle ORM typesafe schema design, relational queries, prepared statements,
  migrations, and transactions. Use when working with Drizzle ORM, writing database
  queries, managing migrations, or optimizing query performance with prepared statements.

  '
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
metadata:
  category: database
  extends: platform-database
  tags:
  - drizzle
  - orm
  - database
  - typescript
  - migration
  - query
  - performance
  status: ready
  version: 5
---

# Drizzle ORM TypeSafe Database Access

Lightweight, headless TypeScript ORM with zero dependencies. Drizzle excels at:
- **Type inference** — Full TypeScript types from schema; no generated types or separate schema language
- **Relational queries** — Fetch nested data with `.with()` without manual joins
- **Prepared statements** — Pre-compile queries for repeated execution; significant performance boost
- **Migrations** — Version-controlled schema changes with drizzle-kit; rollback support
- **Transactions** — Atomic multi-operation commits with savepoints for nested transactions

Core patterns: one table per file, relational API for nested queries, prepared statements for hot paths, transactions for consistency.

## Workflow

When working with Drizzle ORM:

1. **Design schema** — Tables, columns, constraints; one file per table
2. **Define relations** — `defineRelations()` for one-to-many, many-to-many; enables nested queries
3. **Choose query style** — Relational API for nested data (prefer), SQL builder for flexibility
4. **Optimize hot paths** — Use prepared statements with placeholders for repeated queries
5. **Handle transactions** — Wrap multi-operation writes in `db.transaction()`
6. **Test migrations** — `drizzle-kit migrate:dev` before push; review generated SQL
7. **Type extraction** — Use `InferSelectModel` for runtime types from schema

## Rules

Patterns are organized by concern:

- **Schema** — Table design, column types, constraints, one file per table
- **Relational Queries** — `with()` for nested data, partial columns, filtering
- **Query Builder** — SQL builder for aggregations and complex queries
- **Prepared Statements** — Pre-compile for performance; use placeholders for parameters
- **Migrations** — Version control, review SQL, push vs generate
- **Transactions** — Atomic operations, savepoints, error handling

See `rules/` for implementation patterns and examples.

## Examples

### Positive Trigger

User: "Define a Drizzle schema for orders with relations to users and products."

Expected behavior: Use `tech-drizzle` guidance, apply schema design with relational queries and type inference.

### Non-Trigger

User: "Write a raw SQL migration for adding a column to the users table."

Expected behavior: Do not prioritize `tech-drizzle`; choose a more relevant skill or proceed without it.

- Error: Running unprepared queries in tight loops
- Cause: Query compiled every execution; no reuse of parsed SQL
- Solution: Use `.prepare()` with placeholders; execute multiple times with different params

- Error: Manual joins in code; fetching parent then children separately
- Cause: Not using relational API; writing complex join logic
- Solution: Define relations, use `.with()` to fetch nested data in single query

## Troubleshooting

- Error: `Column not included in result` when selecting from relation
- Cause: Selecting from nested relation without explicitly including columns
- Solution: Use `columns: { id: true, name: true }` to specify nested relation columns

- Error: Transaction rolls back unexpectedly; no clear error
- Cause: Unhandled promise rejection inside `db.transaction()`
- Solution: Wrap transaction operations in try/catch; all errors must be caught

- Error: Schema types not updating after migration
- Cause: drizzle-kit didn't regenerate types; cache stale
- Solution: Run `drizzle-kit generate` after migration changes
