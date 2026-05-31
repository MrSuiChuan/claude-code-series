# Heartbeat Protocol - Pro Edition

Enhanced heartbeat protocol with Matt Pocock skill integration.

## Protocol Flow

```
┌─────────────────────────────────────────────────────┐
│                  HEARTBEAT CYCLE                     │
│                                                     │
│  WAKE ──→ IDENTITY ──→ INBOX ──→ CHECKOUT          │
│                                      │              │
│                                      ▼              │
│                           ┌─── TASK TYPE? ───┐      │
│                           │    │    │    │    │      │
│                           ▼    ▼    ▼    ▼    ▼     │
│                        feature bug review deploy test│
│                           │    │    │    │    │      │
│                           ▼    ▼    ▼    ▼    ▼     │
│                    SELECT SKILL BASED ON TASK TYPE   │
│                           │                         │
│                           ▼                         │
│                    INVOKE SKILL                      │
│                    (/tdd | /diagnose | /triage ...)  │
│                           │                         │
│                           ▼                         │
│                    EXECUTE WITH GUIDANCE             │
│                           │                         │
│                           ▼                         │
│                    GENERATE HANDOFF (/handoff)       │
│                           │                         │
│                           ▼                         │
│                    REPORT ──→ EXIT                   │
└─────────────────────────────────────────────────────┘
```

## Task Type → Skill Selection

| Task Type | Role | Primary Skill | Secondary Skills |
|-----------|------|--------------|-----------------|
| `feature` | Developer | `/tdd` | `/prototype`, `/handoff` |
| `bug` | Developer | `/diagnose` | `/caveman`, `/handoff` |
| `review` | Reviewer | `/triage` → `/code-review` | `/diagnose`, `/zoom-out` |
| `design` | Architect | `/grill-me` | `/grill-with-docs`, `/to-prd` |
| `deploy` | Operator | `/diagnose` | `/triage`, `/handoff` |
| `test` | Tester | `/tdd` | `/diagnose`, `/triage` |
| `docs` | Architect | `/to-prd` | `/write-a-skill` |
| `security` | Reviewer | `/code-review` | `/diagnose` |
| `refactor` | Developer | `/tdd` | `/improve-codebase-architecture` |

## Heartbeat Prompt Templates

### Architect Heartbeat (Pro)
```
PaperClip Pro heartbeat for architect_01.

1. CHECK INBOX: TaskList for assigned tasks
2. CHECKOUT: TaskUpdate status=in_progress on highest priority task
3. SELECT SKILL based on task type:
   - design → /grill-me → /to-prd → /to-issues
   - docs → /to-prd → /write-a-skill
   - review → /zoom-out → /improve-codebase-architecture
4. EXECUTE with skill guidance
5. HANDOFF: /handoff if handing off to developer
6. REPORT: TaskUpdate with progress summary
7. EXIT
```

### Developer Heartbeat (Pro)
```
PaperClip Pro heartbeat for developer_01.

1. CHECK INBOX: TaskList for assigned tasks
2. CHECKOUT: TaskUpdate status=in_progress
3. SELECT SKILL:
   - feature → /tdd (red → green → refactor)
   - bug → /diagnose (reproduce → minimize → hypothesize → fix)
   - refactor → /tdd (ensure tests pass before/after)
   - simple change → /caveman
4. EXECUTE with skill guidance
5. HANDOFF: /handoff with implementation notes
6. REPORT: TaskUpdate status=in_review
7. EXIT
```

### Reviewer Heartbeat (Pro)
```
PaperClip Pro heartbeat for reviewer_01.

1. CHECK INBOX: TaskList for in_review tasks
2. CHECKOUT: TaskUpdate status=in_progress
3. TRIAGE: /triage → classify findings as P0/P1/P2
4. REVIEW: /code-review (correctness, security, maintainability)
5. DEEP DIVE (if needed):
   - /diagnose for bug investigation
   - /zoom-out for architectural impact
   - /improve-codebase-architecture for refactoring opportunities
6. DECIDE:
   - P0 issues → create sub-tasks, set status back to in_progress
   - All clear → set status to done
7. EXIT
```

### Operator Heartbeat (Pro)
```
PaperClip Pro heartbeat for operator_01.

1. CHECK ALERTS: any monitoring alerts?
2. TRIAGE: /triage → prioritize by severity
3. DIAGNOSE (P0/P1): /diagnose → root cause analysis
4. FIX or ESCALATE: apply fix or escalate to developer
5. HANDOFF: /handoff for shift change
6. EXIT
```

## Budget-Aware Skill Execution

Before invoking any skill, the agent checks:
1. `budget.remaining` > skill estimated cost
2. If budget < 20% remaining: use `/caveman` mode
3. If budget < 10% remaining: request Board approval before continuing
4. All skill invocations logged to audit trail

## Failure Recovery

If a skill invocation fails:
1. Log error to audit trail
2. If `/diagnose` → escalate to human-readable summary
3. If `/tdd` → save failing test, create sub-task
4. Retry with different approach after 3 failures
5. After 5 failures → escalate to Board
