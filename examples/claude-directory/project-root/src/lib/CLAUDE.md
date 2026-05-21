# Shared Logic Rules

- Shared utilities should be deterministic and easy to test.
- Keep domain logic here instead of spreading it across pages and components.
- Prefer pure functions where possible.
- Do not import client-only code into shared server utilities.
- External service clients should be wrapped behind narrow functions or modules.
