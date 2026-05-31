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

## Runtime State (state.json)

```json
{
  "company": "my-project",
  "created_at": "2026-05-31T...",
  "agents": {
    "architect_01": {
      "role": "architect",
      "status": "idle",
      "tokens_spent": 0,
      "tasks_completed": 0,
      "current_task": null
    }
  },
  "tasks": {
    "task_001": {
      "title": "...",
      "status": "in_progress",
      "assignee": "developer_01",
      "created_at": "...",
      "tokens_spent": 0
    }
  },
  "budget": {
    "total_allocated": 500000,
    "spent": 0,
    "daily_reset": "2026-05-31"
  },
  "heartbeats": {
    "architect_01": {
      "cron_job_id": "...",
      "last_run": "...",
      "next_run": "..."
    }
  },
  "audit_log": []
}
```

## Multi-Company Setup

PaperClip supports multiple isolated companies. Each has its own directory:

```
companies/
├── project-alpha/
│   ├── company.yaml
│   └── .paperclip/state.json
├── project-beta/
│   ├── company.yaml
│   └── .paperclip/state.json
```

Switch between companies: `/paperclip switch project-beta`
