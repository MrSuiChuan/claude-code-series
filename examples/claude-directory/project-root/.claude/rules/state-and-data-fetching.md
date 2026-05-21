---
paths:
  - "src/app/**/*.{ts,tsx}"
  - "src/components/**/*.{ts,tsx}"
  - "src/lib/**/*.{ts,tsx}"
---

# State and Data Fetching Rules

- Keep server data fetching close to the route or server boundary when possible.
- Use client-side fetching only when interactivity or live updates require it.
- Prefer consistent cache keys and invalidation patterns.
- Avoid duplicating fetched state across multiple stores.
- Surface loading and refetch states clearly in the UI.
