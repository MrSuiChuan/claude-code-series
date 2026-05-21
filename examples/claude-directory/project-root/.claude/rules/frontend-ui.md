---
paths:
  - "src/app/**/*.tsx"
  - "src/components/**/*.tsx"
---

# Frontend UI Rules

- Reuse existing layout and UI primitives before creating new visual patterns.
- Keep Tailwind class usage readable; extract repeated patterns into components or helpers.
- Handle loading, empty, success, and error states explicitly.
- Avoid leaking server-only logic into client components.
- Preserve responsive behavior on desktop and mobile.
