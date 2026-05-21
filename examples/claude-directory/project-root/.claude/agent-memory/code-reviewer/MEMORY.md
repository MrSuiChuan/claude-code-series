# code-reviewer memory

## Project patterns seen
- Server components are preferred unless interactivity requires `"use client"`
- Route handlers validate input before business logic
- Shared domain logic lives in `src/lib`
- Prisma access should stay typed and narrowly scoped

## Recurring issues
- Missing loading or empty states on new screens
- Inconsistent error payloads across API routes
- Auth checks placed too late in request handlers
- Tests that miss regression coverage for edge cases
