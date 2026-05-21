---
description: Reviews database schema or migration changes for safety and operability. Use when Claude should inspect Prisma schema edits, generated migrations, data backfills, or seed changes for destructive steps, transaction safety, and rollout risk.
argument-hint: <migration-or-schema-path>
---

Review the database change for $ARGUMENTS.

Check for:

1. Destructive migration steps
2. Data backfill requirements
3. Transaction and lock risk
4. Indexing implications
5. Rollback or recovery concerns
6. Test or staging validation needs
