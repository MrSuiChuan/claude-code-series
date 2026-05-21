# App Router Rules

- Prefer server components by default.
- Add `"use client"` only when state, effects, browser APIs, or interactive handlers are required.
- Keep route segments small and move reusable logic into `src/lib`.
- Handle loading, empty, and error states explicitly for user-facing pages.
- Keep server actions thin and validate inputs before mutating data.
