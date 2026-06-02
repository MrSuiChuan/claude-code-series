# Company Structure Reference

## company.yaml Schema

```yaml
company:
  name: "my-project"           # kebab-case identifier
  display_name: "我的项目"      # Human-readable name
  mission: "项目使命描述"        # What this company does
  created_at: "2026-05-31"
  version: "0.1.0"

budget:
  currency: "tokens"
  daily_limit: 500000          # Max tokens per day
  per_task_limit: 100000       # Max tokens per task
  alert_threshold: 0.8         # Alert at 80%
  enforce: true                # Auto-halt when exceeded

governance:
  approval_required_for:       # Operations needing Board approval
    - budget_exceeded
    - production_deploy
    - data_mutation
    - external_api_call
  auto_approve:                # Auto-approved operations
    - code_review
    - test_execution
  board_members: ["user"]

milestones:                    # Project phases (create as tasks)
  - name: "初始化"
    order: 1
  - name: "开发"
    order: 2
  - name: "测试"
    order: 3
```

## Runtime State (file-based, no database)

All runtime state stored as JSON files under `.paperclip/`. Each agent writes only its own file,
eliminating write conflicts.

```
.paperclip/
├── company.json       # Company info + schema_version
├── budget.json        # Budget tracking
├── audits.jsonl       # Append-only audit log (no write conflicts)
├── agents/            # One file per agent (each agent writes only its own)
│   ├── architect.json
│   ├── developer.json
│   ├── reviewer.json
│   ├── tester.json
│   └── operator.json
├── tasks/             # One file per task
│   ├── task_001.json
│   └── task_002.json
└── design/            # DESIGN.md cache (optional, Layer 4)
```

**Agent file example** (`agents/developer.json`):
```json
{
  "role": "developer",
  "display_name": "开发者",
  "status": "working",
  "tokens_spent": 125000,
  "tasks_completed": 3,
  "current_task": "task_001",
  "budget_share": 0.4,
  "max_autonomous_tokens": 50000,
  "last_heartbeat": "2026-06-02T14:30:00"
}
```

**Task file example** (`tasks/task_001.json`):
```json
{
  "task_id": "task_001",
  "title": "Implement JWT login",
  "description": "Add OAuth2 login flow",
  "type": "feature",
  "priority": "high",
  "status": "in_progress",
  "assignee": "developer",
  "tokens_spent": 42000,
  "history": [
    {"timestamp": "...", "event": "created"},
    {"timestamp": "...", "event": "dispatched", "assignee": "developer", "score": 18},
    {"timestamp": "...", "event": "checked_out", "agent": "developer"}
  ]
}
```

## Multi-Company Setup

PaperClip supports multiple isolated companies. Each has its own directory:

```
companies/
├── project-alpha/
│   ├── company.yaml
│   └── .paperclip/   (file-based state, no database)
├── project-beta/
│   ├── company.yaml
│   └── .paperclip/state.json
```

Switch between companies: `/paperclip switch project-beta`
