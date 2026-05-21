---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
---

# Testing Rules

- Test names should describe the scenario and the expected outcome.
- Prefer testing behavior over implementation details.
- Mock external services before mocking internal modules.
- Clean up side effects in `afterEach`.
- When fixing a bug, add the smallest regression test that proves the fix.
