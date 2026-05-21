---
paths:
  - "src/**/*auth*.ts"
  - "src/**/*auth*.tsx"
  - "src/**/*session*.ts"
  - "src/**/*session*.tsx"
---

# Auth and Session Rules

- Treat auth and session code as security-sensitive by default.
- Make login, logout, refresh, and permission checks easy to trace.
- Avoid silent fallbacks that weaken access control.
- Store secrets and tokens outside source control.
- Add tests for expiry, unauthorized access, and edge-case transitions.
