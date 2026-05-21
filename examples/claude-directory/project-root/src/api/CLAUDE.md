# External Integration Rules

- Use `src/api` for third-party API clients, SDK wrappers, and integration adapters.
- Normalize external response shapes before they spread into the rest of the app.
- Keep retries, timeouts, auth headers, and rate-limit handling close to the integration boundary.
- Log failures with enough context to debug them, but never leak tokens, secrets, or raw credentials.
- Avoid scattering duplicate fetch logic for the same external service across pages and components.
