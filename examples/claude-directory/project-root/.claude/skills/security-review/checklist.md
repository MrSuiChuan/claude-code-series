# Security Review Checklist

## Input Validation
- [ ] Untrusted input validated before queries, command execution, or template rendering
- [ ] File upload type, size, and storage path validated
- [ ] Path traversal prevented on file operations and download endpoints

## Authentication
- [ ] Session or token expiry, refresh, and revocation behavior reviewed
- [ ] API keys and service credentials stored outside source control
- [ ] Passwords or secrets stored with a modern approved hashing or secret-management approach

## Authorization
- [ ] Resource ownership and tenant boundaries enforced on read and write paths
- [ ] Privileged actions checked explicitly at the request boundary

## Browser Security
- [ ] Sensitive mutations reviewed for CSRF, redirect, and origin-handling risks
- [ ] User-controlled HTML, Markdown, or rich text reviewed for XSS exposure
