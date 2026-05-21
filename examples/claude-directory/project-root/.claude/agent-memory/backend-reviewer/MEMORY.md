# backend-reviewer memory

## Project patterns seen
- Request validation should happen at the boundary
- Response shapes should stay stable across routes
- Database changes are review-sensitive and often need migration scrutiny

## Recurring issues
- Missing auth checks on write paths
- Input parsing without runtime validation
- Broad queries that fetch more data than the caller needs
