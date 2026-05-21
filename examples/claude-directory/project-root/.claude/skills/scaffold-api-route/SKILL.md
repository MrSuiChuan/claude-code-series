---
description: Creates or refactors an API endpoint for a TypeScript web application. Use when Claude needs to add a new route handler, server action, or mutation path with validation, auth checks, stable error handling, and tests.
argument-hint: <route-or-action-name>
---

Implement the API route or server action for $ARGUMENTS.

Checklist:

1. Identify the correct route location
2. Define request and response shapes
3. Validate all untrusted input
4. Apply auth, authorization, and rate limiting where needed
5. Keep business logic reusable from `src/lib`
6. Add tests or document why tests were skipped
