# Company Structure Reference

## company.json Schema (v2.1)

```json
{
  "company": {
    "name": "my-project",
    "display_name": "我的项目",
    "mission": "项目使命描述",
    "created_at": "2026-06-04",
    "version": "0.1.0"
  },
  "budget": {
    "currency": "tokens",
    "daily_limit": 500000,
    "per_task_limit": 100000,
    "alert_threshold": 0.8,
    "enforce": true
  },
  "governance": {
    "approval_required_for": [
      "budget_exceeded",
      "production_deploy",
      "data_mutation",
      "external_api_call"
    ],
    "auto_approve": [
      "code_review",
      "test_execution"
    ],
    "board_members": ["user"]
  },
  "rules": {
    "budget_enforcement": [...],
    "approval_workflows": [...],
    "quality_gates": [...],
    "autonomy_limits": [...]
  },
  "milestones": [
    { "name": "初始化", "description": "...", "order": 1 }
  ]
}
```

Legacy `company.yaml` and `rules.yaml` are still supported for existing projects but no longer generated for new ones.

## Runtime State (file-based, no database)

All runtime state stored as JSON files under `.paperclip/`. Each agent writes only its own file, eliminating write conflicts.

```
.paperclip/
├── company.json       # Company info + schema_version + heartbeat IDs
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
└── design/            # DESIGN.md cache (optional)
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
│   ├── company.json
│   └── .paperclip/
├── project-beta/
│   ├── company.json
│   └── .paperclip/
```

Switch between companies: `/paperclip switch project-beta`
