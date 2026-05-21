---
paths:
  - "src/app/**/*.{ts,tsx}"
  - "src/components/**/*.{ts,tsx}"
  - "src/lib/**/*.{ts,tsx}"
---

# Performance and Caching Rules

- Avoid unnecessary client rendering when server rendering is sufficient.
- Keep cache boundaries explicit for fetched data and expensive computation.
- Watch for duplicate fetches, large bundle additions, and avoidable rerenders.
- Defer non-critical work when it does not affect first paint.
- Measure before adding complexity for micro-optimizations.
