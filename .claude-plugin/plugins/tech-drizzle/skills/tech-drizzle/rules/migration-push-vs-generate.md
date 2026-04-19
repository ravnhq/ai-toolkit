---
title: Use Push Locally, Generate Before Commit
impact: HIGH
tags: migration, workflow, drizzle-kit
---

## Use Push Locally, Generate Before Commit

Use `db:push` for rapid local iteration. Generate migrations only when ready to commit.

**Development workflow:**

```bash
# 1. Make schema changes in code
# 2. Push to local database (no migration file)
pnpm db:push

# 3. Iterate on schema, push again
pnpm db:push

# 4. When satisfied, generate migration file
pnpm db:generate

# 5. Review the generated SQL
cat packages/db/drizzle/0001_add_invitations_table.sql

# 6. Commit schema changes + migration file together
git add packages/db/src/schema packages/db/drizzle
git commit -m "Add invitations table"
```

**When to use each:**

| Command | When | Creates File |
|---------|------|--------------|
| `db:push` | Local development, experimenting | No |
| `db:generate` | Ready to commit, before PR | Yes |
| `db:migrate` | Staging/production deployment | No (runs existing) |

**Why separate:**

- `push` is fast - no migration file to manage
- `generate` creates clean, intentional migrations
- Avoids cluttering history with WIP migrations
- Migration history stays meaningful

**Why it matters:**
- Clean migration history
- Faster local development
- Migrations represent intentional schema changes
- Easier to review and understand changes

Reference: [Drizzle Push vs Generate](https://orm.drizzle.team/kit-docs/commands)
