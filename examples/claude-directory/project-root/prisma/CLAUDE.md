# Database Rules

- Treat schema changes, migrations, and seeds as review-sensitive changes.
- Prefer additive and reversible migrations when possible.
- Avoid destructive migration steps unless the task explicitly requires them.
- Keep database access through Prisma typed and scoped to the smallest useful query.
- Check for N+1 patterns, missing indexes, and transaction boundaries when changing data flows.
