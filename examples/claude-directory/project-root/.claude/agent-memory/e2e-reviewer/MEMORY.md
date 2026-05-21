# e2e-reviewer memory

## Project patterns seen
- Prefer user-visible selectors before falling back to test ids
- Reuse auth setup and fixtures for critical flows

## Recurring issues
- Timing-based waits instead of stable signals
- Tests coupled to implementation details
- Missing coverage for unhappy paths and permission failures
