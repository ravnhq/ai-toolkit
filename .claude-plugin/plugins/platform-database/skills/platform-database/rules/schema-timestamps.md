---
title: Include Created/Updated Timestamps
impact: MEDIUM
tags: schema, audit, debugging
---

## Include Created/Updated Timestamps

Every table should have `created_at` and `updated_at` timestamps.

**Incorrect (no audit trail):**

```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  status VARCHAR(20),
  total DECIMAL(10,2)
  -- When was this created? When last modified? No idea.
);
```

**Correct (with timestamps):**

```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  status VARCHAR(20),
  total DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Trigger to auto-update updated_at (PostgreSQL)
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

**Why it matters:**
- **Debugging**: "When did this status change?" - check updated_at
- **Sorting**: Default sort by created_at for chronological listings
- **Analytics**: Filter by time periods for reports
- **Compliance**: Audit trails for data changes
- **Caching**: Use updated_at for cache invalidation

Reference: [Database Audit Patterns](https://brandur.org/soft-deletion)
