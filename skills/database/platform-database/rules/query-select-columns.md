---
title: Select Only Needed Columns
impact: HIGH
impactDescription: 2-5x bandwidth reduction
tags: query, performance, bandwidth
---

## Select Only Needed Columns

Fetch only the columns you actually need. Avoid `SELECT *` in production code.

**Incorrect (over-fetching):**

```sql
-- Fetches all columns including large text fields, blobs
SELECT * FROM users WHERE id = 123;

-- Returns: id, email, name, password_hash, avatar_blob,
--          preferences_json, created_at, updated_at, ...
```

**Correct (explicit columns):**

```sql
-- Only fetches what's needed for display
SELECT id, email, name FROM users WHERE id = 123;
```

**Why it matters:**
- **Bandwidth**: Large columns (JSON, text, blobs) waste network transfer
- **Memory**: Application loads unnecessary data into memory
- **Security**: Accidentally exposing sensitive fields (password hashes, tokens)
- **Clarity**: Explicit columns document what data the code actually uses

Reference: [Why SELECT * is bad](https://tanelpoder.com/posts/reasons-why-select-star-is-bad-for-sql-performance/)
