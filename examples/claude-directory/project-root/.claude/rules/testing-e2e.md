---
paths:
  - "tests/e2e/**/*.ts"
  - "tests/e2e/**/*.tsx"
---

# E2E Testing Rules

- Prefer user-visible selectors before test ids.
- Keep flows resilient to timing and minor UI changes.
- Reuse fixtures, auth setup, and helpers to reduce duplication.
- Avoid broad sleeps; wait on stable signals.
- Record the failing scenario clearly when adding a regression test.
