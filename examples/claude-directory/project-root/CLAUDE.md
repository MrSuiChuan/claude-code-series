# Web App Project Conventions

## Product shape
- This project is a modern web application built with TypeScript.
- Default assumptions: React + Next.js App Router, server components by default, pnpm as the package manager, Tailwind CSS for styling, Zod for runtime validation, Prisma for database access, and Playwright/Vitest for testing.
- Prefer established project patterns over introducing new abstractions.

## Primary workflow
- First understand the relevant module before editing it.
- Keep changes small, local, and easy to review.
- After implementing, run the narrowest useful verification first, then broader checks if needed.
- If a task spans multiple areas, propose a short plan before touching code.

## Common commands
- Install dependencies: `pnpm install`
- Start development: `pnpm dev`
- Run type checks: `pnpm typecheck`
- Run lint: `pnpm lint`
- Run unit tests: `pnpm test`
- Run E2E tests: `pnpm test:e2e`
- Build production bundle: `pnpm build`
- Apply database migrations in development: `pnpm prisma migrate dev`

## Architecture boundaries
- UI components belong in `src/components` and should stay focused on rendering and interaction.
- Route handlers and server actions belong in `src/app`, especially `src/app/api`, and own request/response boundaries.
- External service clients and integration adapters belong in `src/api`.
- Shared domain logic belongs in `src/lib` and should be reusable from both server code and tests.
- Database schema and migrations belong in `prisma`.
- End-to-end flows belong in `tests/e2e`.

## Coding rules
- Prefer named exports.
- Prefer explicit types on public functions, route handlers, and shared utilities.
- Reuse existing utilities before adding new helpers.
- Keep side effects close to the edge of the system.
- Do not mix server-only code into client components.
- Do not add dependencies unless the project already uses them or the change clearly requires them.

## Data and API rules
- Validate all untrusted input with Zod or an equivalent schema.
- Return consistent API shapes and consistent error handling.
- Keep auth, permissions, and rate limiting visible at the request boundary.
- Avoid hiding important business logic inside UI components.

## Testing rules
- Add or update tests for behavior changes when practical.
- Prefer unit or integration tests for domain logic and Playwright for critical user journeys.
- Keep test names descriptive and scenario-based.
- When fixing a bug, add the narrowest regression test that proves the fix.

## Review checklist
- Does the change follow existing patterns in nearby files?
- Are loading, error, and empty states handled?
- Are auth and permission checks still correct?
- Are types, validation, and tests aligned with the behavior change?
- Is there a simpler implementation with fewer moving parts?
