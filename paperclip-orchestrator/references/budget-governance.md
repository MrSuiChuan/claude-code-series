# Budget & Governance

## Budget Tracking

PaperClip tracks token consumption at multiple levels:
- **Per-action**: Each tool call's token cost
- **Per-task**: Aggregated cost of all actions for a task
- **Per-agent**: Total tokens consumed by an agent
- **Per-company**: Aggregate across all agents

### Cost Report

```bash
python scripts/cost_reporter.py --state-dir .paperclip --format summary
```

Output:
```
╔══════════════════════════════════════╗
║   PaperClip Budget Report            ║
╠══════════════════════════════════════╣
║  Total Budget:      500,000 tokens   ║
║  Spent:             125,000 tokens   ║
║  Remaining:         375,000 tokens   ║
║  Used:                  25.0%        ║
║  Status:              ok              ║
╚══════════════════════════════════════╝
```

### Budget Enforcement

| Threshold | Action |
|-----------|--------|
| < 75% | Normal operation |
| 75-90% | Warning notification to agent |
| 90-95% | Auto-throttle: reduce heartbeat frequency |
| > 95% | Pause all agents, notify Board |
| 100% | Hard stop: no more agent execution |

## Governance Rules

### Approval Workflows

Operations requiring Board approval (from `rules.yaml`):
- `budget_exceeded` — Going over allocated budget
- `production_deploy` — Deploying to production
- `data_mutation` — Destructive data operations
- `external_api_call` — Calling external services

### Approval Flow

```
Agent requests action
  → Check rules.yaml for approval requirement
  → If auto_approved: proceed immediately
  → If requires approval:
      1. Agent creates approval request (log to audit trail)
      2. Board member (user) receives AskUserQuestion
      3. Board approves/rejects
      4. Agent proceeds or aborts
      5. Decision logged to audit trail
```

### Quality Gates

Before a task moves to `done`, it must pass quality gates:
1. **Code Review Gate**: reviewer_approval AND test_pass
2. **Test Gate**: All tests passing
3. **Security Gate** (critical projects): No critical vulnerabilities

## Autonomy Limits

| Agent Level | Max Tokens/Action | Can Delegate | Can Approve |
|------------|-------------------|-------------|-------------|
| Leadership | 80,000 | Yes | code_review, test_execution |
| Execution | 50,000 | No | None |
| Quality | 40,000 | Yes | test_execution |

When an agent hits its autonomy limit, it must request Board approval to continue.

## Audit Trail

All significant events are logged to `state.json > audit_log`:
- Task creation, assignment, completion
- Budget threshold crossings
- Approval requests and decisions
- Agent heartbeat check-ins
- Errors and exceptions
