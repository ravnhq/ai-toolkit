# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Relational Queries (rqb)

**Impact:** HIGH
**Description:** Drizzle's relational query builder (`db.query`) provides type-safe eager loading. Use it for reads with relations instead of manual JOINs.

## 2. Query Builder (qb)

**Impact:** MEDIUM
**Description:** The SQL-like query builder for complex queries, aggregations, and CTEs. Use when relational queries aren't sufficient.

## 3. Schema Definition (schema)

**Impact:** MEDIUM
**Description:** Drizzle schemas define tables, columns, indexes, and relations. Proper organization prevents circular imports.

## 4. Migrations (migration)

**Impact:** HIGH
**Description:** Drizzle-kit generates migrations from schema diffs. Understand when to use push vs generate, and always review generated SQL.
