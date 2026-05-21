---
paths:
  - "src/api/**/*.ts"
  - "src/api/**/*.tsx"
---

# External Integration Rules

- Wrap third-party APIs behind small typed clients or adapters.
- Normalize vendor-specific response shapes before passing data into `src/lib` or UI code.
- Keep retries, timeouts, auth headers, and backoff policies near the integration boundary.
- Handle non-2xx responses, partial failures, and rate limiting explicitly.
- Avoid scattering raw `fetch` calls to the same external service across multiple modules.
