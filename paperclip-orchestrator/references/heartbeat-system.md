# Heartbeat Scheduling System (v2.2)

## Overview

PaperClip uses two complementary mechanisms for agent scheduling:

1. **Hooks-based heartbeat** (primary, v2.2): `SubagentStop` hook automatically updates `last_heartbeat` whenever a paperclip sub-agent finishes execution.
2. **CronCreate heartbeat** (optional, v1.0): Register CronCreate jobs that fire every 15 minutes. Each heartbeat invokes the corresponding `paperclip-*` sub-agent.

**Recommendation:** Use hooks for automatic timestamp tracking. Use CronCreate only when you need periodic task polling (e.g., agents should wake up and check for new tasks without user intervention).

## Heartbeat Protocol (v2.2)

When a sub-agent (e.g., `paperclip-architect`) is invoked:

1. **Invoke**: User says "开始" or CronCreate fires → Claude invokes sub-agent
2. **Identity**: Sub-agent reads its own `paperclip:` frontmatter for role definition
3. **State Check**: Reads `.paperclip/agents/<role>.json` for current status
4. **Inbox**: Scans `.paperclip/tasks/` for assigned todo/in_progress tasks
5. **Checkout**: Updates task status → in_progress, agent status → working
6. **Execute**: Performs the work (design, implement, review, test, deploy)
7. **Complete**: Updates task status → in_review or done
8. **Hook fires**: `SubagentStop` hook auto-updates `last_heartbeat` timestamp
9. **Audit**: `PostToolUse` hook auto-appends to `audits.jsonl` on status changes

## CronCreate Patterns (optional)

### Standard-Frequency Agents (every 15 min)
```
CronCreate:
  cron: "*/15 * * * *"
  prompt: "PaperClip heartbeat for architect. Invoke paperclip-orchestrator:paperclip-architect."
  recurring: true
```

### Manual Trigger (preferred for v2.2)
No CronCreate needed. The user triggers agents on demand:
- "开始" / "继续" → invoke sub-agent with pending tasks
- "测试" → invoke paperclip-tester
- "审查" → invoke paperclip-reviewer

## Agent-Specific Heartbeat Prompts

### Architect
```
PaperClip heartbeat for architect in company {company_name}.
Invoke paperclip-orchestrator:paperclip-architect sub-agent.
```

### Developer
```
PaperClip heartbeat for developer in company {company_name}.
Invoke paperclip-orchestrator:paperclip-developer sub-agent.
```

### Reviewer
```
PaperClip heartbeat for reviewer in company {company_name}.
Check for in_review tasks. Invoke paperclip-orchestrator:paperclip-reviewer sub-agent.
```

## Monitoring Heartbeats

Check heartbeat health:
```
/paperclip-status  → show all agent statuses + last_heartbeat timestamps
```

Stale heartbeat detection: if an agent's `last_heartbeat` is more than 3× its expected interval old, the dashboard flags it.
