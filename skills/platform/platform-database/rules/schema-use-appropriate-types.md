---
title: Use Appropriate Column Types
impact: MEDIUM
tags: schema, types, constraints
---

## Use Appropriate Column Types

Choose column types that match your data constraints. Don't use unbounded TEXT for everything.

**Incorrect (loose types):**

```sql
CREATE TABLE users (
  id TEXT,                    -- Should be PRIMARY KEY
  email TEXT,                 -- No length limit, no unique
  age TEXT,                   -- Storing numbers as text!
  is_active TEXT,             -- Storing boolean as text!
  balance TEXT,               -- Storing money as text!
  created_at TEXT             -- Storing timestamp as text!
);
```

**Correct (appropriate types with constraints):**

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  age INTEGER CHECK (age >= 0 AND age < 150),
  is_active BOOLEAN NOT NULL DEFAULT true,
  balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

**Type selection guide:**

| Data | Type | Notes |
|------|------|-------|
| IDs | TEXT or UUID | TEXT for nanoid/cuid, UUID for uuid |
| Email | VARCHAR(255) | 255 is practical limit per RFC |
| Name | VARCHAR(100) | Reasonable display limit |
| Status/enum | VARCHAR(20) or ENUM | Short, known values |
| Boolean | BOOLEAN | Never use TEXT or INTEGER |
| Money | DECIMAL(p,s) | Never use FLOAT (precision loss) |
| Timestamps | TIMESTAMP WITH TIME ZONE | Always include timezone |
| Large text | TEXT | Blog posts, descriptions |

**Why it matters:**
- Type constraints catch bugs at insert time, not in application code
- Proper types enable database optimizations (sorting, indexing)
- Storage efficiency - INTEGER vs TEXT for numbers
- Clear schema documentation of data expectations
