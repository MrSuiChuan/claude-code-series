---
paths:
  - "src/**/*form*.tsx"
  - "src/**/*Form*.tsx"
  - "src/**/*schema*.ts"
  - "src/**/*schema*.tsx"
---

# Forms and Validation Rules

- Validate on the server even if the client already validates.
- Keep form defaults, parsing, and submit behavior explicit.
- Reuse schemas between client and server where practical.
- Show actionable validation errors next to the relevant field.
- Do not silently coerce invalid user input without a good reason.
