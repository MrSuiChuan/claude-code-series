---
paths:
  - "src/app/api/**/*.ts"
---

# API Design Rules

- Validate all request input with Zod schemas or equivalent runtime validation.
- Keep response shapes consistent across routes.
- Use explicit HTTP status codes and stable error payloads.
- Enforce authentication and authorization before business logic runs.
- Rate limit public endpoints and sensitive write endpoints.
