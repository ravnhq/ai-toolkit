# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Architecture (arch)

**Impact:** CRITICAL
**Description:** Vertical Slice Architecture organizes code by feature, not layer. Each slice owns its procedure, schemas, repository, and tests. This is foundational to maintainability.

## 2. Procedures (proc)

**Impact:** HIGH
**Description:** Procedures are the API endpoints. Proper structure, authorization levels, and schema definitions ensure type-safe, secure APIs.

## 3. Schemas (schema)

**Impact:** HIGH
**Description:** Input/output schemas provide runtime validation and TypeScript types. Always define them, even for simple cases.

## 4. Error Handling (error)

**Impact:** MEDIUM-HIGH
**Description:** Domain-specific errors with proper tRPC codes improve debugging and client experience.

## 5. Data Access (data)

**Impact:** MEDIUM
**Description:** Repository pattern per slice keeps data access focused and testable. Avoid god-object repositories.

## 6. Cross-Slice Communication (cross)

**Impact:** MEDIUM
**Description:** Slices should not import from other slices. Use messages or background jobs for cross-cutting behavior.
