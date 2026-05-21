---
paths:
  - "prisma/**/*"
  - "src/**/*prisma*.ts"
  - "src/**/*db*.ts"
---

# Database and Prisma Rules

- Review schema changes, migrations, and seeds carefully before editing them.
- Prefer additive migrations and explicit backfills over destructive rewrites.
- Keep queries typed and narrow; select only what the caller needs.
- Watch for transaction safety, N+1 issues, and missing indexes on new access paths.
- Never hardcode credentials or connection strings.
