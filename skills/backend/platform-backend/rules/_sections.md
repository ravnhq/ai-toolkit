# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Security (security)

**Impact:** CRITICAL
**Description:** Security is non-negotiable. Authentication, authorization, input validation, and secret management protect your users and data.

## 2. API Design (api)

**Impact:** HIGH
**Description:** Well-designed APIs are consistent, predictable, and self-documenting. Clear contracts between frontend and backend reduce bugs and confusion.

## 3. Error Handling (error)

**Impact:** HIGH
**Description:** Proper error handling provides good developer experience, aids debugging, and prevents information leakage to attackers.

## 4. Validation (validation)

**Impact:** HIGH
**Description:** Validate all inputs at the API boundary. Never trust client data. Schema validation catches bugs early and prevents injection attacks.

## 5. Logging (logging)

**Impact:** HIGH
**Description:** Structured logging with appropriate context enables effective debugging and monitoring.
