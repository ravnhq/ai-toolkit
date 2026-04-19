---
title: Avoid Leading Wildcards in LIKE
impact: MEDIUM
tags: query, performance, search
---

## Avoid Leading Wildcards in LIKE

Leading wildcards (`%search`) force full table scans. Trailing wildcards (`search%`) can use indexes.

**Incorrect (leading wildcard - no index):**

```sql
-- Forces full table scan
SELECT * FROM products WHERE name LIKE '%widget%';
```

**Correct (trailing wildcard - uses index):**

```sql
-- Can use index on name column
SELECT * FROM products WHERE name LIKE 'widget%';
```

**For full-text search:**

```sql
-- Use proper full-text search instead of LIKE
-- PostgreSQL
SELECT * FROM products
WHERE to_tsvector('english', name) @@ to_tsquery('widget');

-- Or use a search service (Elasticsearch, Meilisearch, Typesense)
```

**Why it matters:** B-tree indexes are sorted. `LIKE 'widget%'` can seek to 'widget' and scan forward. `LIKE '%widget%'` must check every row because matching values could start with anything.

Reference: [LIKE Performance](https://use-the-index-luke.com/sql/where-clause/searching-for-ranges/like-performance)
