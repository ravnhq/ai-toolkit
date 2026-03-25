# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Query Optimization (query)

**Impact:** CRITICAL
**Description:** Efficient queries are the foundation of application performance. N+1 queries, missing indexes, and over-fetching are common causes of slow applications.

## 2. Migrations (migration)

**Impact:** HIGH
**Description:** Safe migration practices prevent data loss and production outages. One change per migration, forward-only, and careful review of generated SQL.

## 3. Indexing (index)

**Impact:** HIGH
**Description:** Proper indexing dramatically improves query performance. Always index foreign keys and columns used in WHERE/ORDER BY clauses.

## 4. Transactions (transaction)

**Impact:** MEDIUM
**Description:** Transactions ensure data consistency for related operations. Keep them short to avoid locks and deadlocks.

## 5. Schema Design (schema)

**Impact:** MEDIUM
**Description:** Good schema design makes queries natural and efficient. Proper column types, constraints, and normalization.
