# Heartbeat Scheduling System

## Overview

PaperClip agents operate in short execution windows called "heartbeats" — they wake on a schedule, check their inbox, execute tasks, report status, and exit. This prevents runaway execution and enables cost control.

## Heartbeat Protocol

Each heartbeat follows this exact sequence:

1. **Wake**: CronCreate triggers the agent
2. **Identity Check**: Read agent role and budget from state
3. **Approval Follow-up**: Check for pending Board approvals
4. **Get Inbox**: Read assigned tasks, sorted by priority
5. **Prioritize**: in_progress > in_review > todo > blocked
6. **Checkout**: Atomically claim the highest-priority task
7. **Execute**: Do the work, leave progress in task description
8. **Report**: Update task status and budget tracking
9. **Exit**: Release unclaimed resources

## Cron Patterns

### High-Frequency Agents (every 5-10 min)
For critical path agents that need quick response:
```
CronCreate:
  cron: "*/5 * * * *"    # Every 5 minutes
  prompt: "PaperClip heartbeat for developer_01"
  recurring: true
```

### Standard-Frequency Agents (every 15-30 min)
For regular development and review work:
```
CronCreate:
  cron: "*/15 * * * *"   # Every 15 minutes
  prompt: "PaperClip heartbeat for architect_01"
  recurring: true
```

### Low-Frequency Agents (hourly/daily)
For reporting, maintenance, and monitoring:
```
CronCreate:
  cron: "7 * * * *"      # Every hour at :07
  prompt: "PaperClip heartbeat for operator_01"
  recurring: true
```

### One-Shot Heartbeats
For manual triggers and urgent tasks:
```
CronCreate:
  cron: "30 14 31 5 *"   # Specific time
  prompt: "PaperClip urgent: deploy hotfix"
  recurring: false
```

## Agent-Specific Heartbeat Prompts

### Architect Heartbeat
```
PaperClip heartbeat for architect_01 in company {company_name}.
1. Check for pending approvals
2. Review in_progress tasks for architectural alignment
3. Decompose new requirements into tasks
4. Assign tasks to developers based on capability match
5. Report status and exit
```

### Developer Heartbeat
```
PaperClip heartbeat for developer_01 in company {company_name}.
1. Check inbox for assigned tasks
2. If task in_progress: continue work, update progress
3. If no active task: checkout highest-priority todo
4. Execute task (implement, fix, refactor)
5. If complete: update status to in_review with implementation notes
6. If blocked: update status to blocked with blocker description
7. Report status and exit
```

### Reviewer Heartbeat
```
PaperClip heartbeat for reviewer_01 in company {company_name}.
1. Check for in_review tasks
2. Review code for correctness, security, style
3. Use /code-review for systematic analysis
4. If passes: mark done, leave approval comment
5. If fails: create sub-tasks for fixes, mark in_progress
6. Report status and exit
```

## Heartbeat Worker Script

`scripts/heartbeat_worker.py` provides the runtime helper:
```bash
python scripts/heartbeat_worker.py \
  --agent-id developer_01 \
  --state-dir .paperclip \
  --company-dir .
```

## Monitoring Heartbeats

Check heartbeat health:
```bash
python scripts/heartbeat_worker.py --agent-id all --report-only
```

Stale heartbeat detection: if an agent hasn't checked in for 3× its heartbeat interval, flag it as potentially stuck and notify the Board.
