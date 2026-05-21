---
paths:
  - "src/**/*.{ts,tsx}"
  - "prisma/**/*"
  - ".env*"
---

# Security and Secrets Rules

- Never commit secrets, tokens, API keys, or private credentials.
- Validate and sanitize all untrusted input before using it in commands, queries, or templates.
- Review file uploads, redirects, and external fetches carefully.
- Prefer least-privilege access and explicit permission checks.
- Call out security-sensitive changes in summaries and reviews.
