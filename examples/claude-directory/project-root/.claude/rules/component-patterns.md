---
paths:
  - "src/components/**/*.tsx"
---

# Component Pattern Rules

- Prefer small components with clear responsibilities.
- Lift shared state only when multiple children truly need it.
- Keep component props explicit and narrowly typed.
- Avoid creating wrapper components that only forward many props without adding value.
- Prefer shared design system tokens and variants over one-off styling forks.
