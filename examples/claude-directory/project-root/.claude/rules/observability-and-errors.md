---
paths:
  - "src/**/*.{ts,tsx}"
---

# Observability and Error Rules

- Errors should include enough context to debug without leaking secrets.
- Prefer structured logging for server-side failures.
- Keep user-facing errors understandable and non-technical.
- Track important async and background failure paths explicitly.
- When changing critical flows, check whether metrics, traces, or alerts should also change.
