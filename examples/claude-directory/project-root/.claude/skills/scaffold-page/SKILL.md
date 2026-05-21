---
description: Creates or refactors a page or route segment for a React/Next.js style web application. Use when Claude needs to add a new screen, layout, route segment, loading state, or page-level composition while following the project's UI and data-loading conventions.
argument-hint: <route-or-screen-name>
---

Build a new page or route segment for $ARGUMENTS.

Working rules:

1. Inspect nearby routes and layouts before creating anything new
2. Prefer server components by default
3. Add loading, empty, and error states when the page fetches data
4. Reuse existing UI primitives and design patterns
5. Move shared logic into `src/lib` or reusable components
6. Summarize the route entry points and any tests that should be added
