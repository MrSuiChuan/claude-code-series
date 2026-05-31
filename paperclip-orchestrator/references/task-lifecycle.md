# Task Lifecycle Management

## State Machine

```
                    ┌─────────┐
                    │   todo  │ ← New task created
                    └────┬────┘
                         │ agent checkout (TaskUpdate status=in_progress)
                    ┌────▼──────┐
            ┌───────│ in_progress│───────┐
            │       └─────┬─────┘       │
            │ blocked      │ done        │ needs review
       ┌────▼────┐   ┌────▼───┐   ┌─────▼──────┐
       │ blocked │   │  done  │   │ in_review  │
       └────┬────┘   └────────┘   └─────┬──────┘
            │ unblocked                 │
            └───────────────────────────┘
                              │ approved  │ rejected
                         ┌────▼───┐  ┌───▼────┐
                         │  done  │  │  todo  │ (back to queue)
                         └────────┘  └────────┘
```

## Task Creation

```python
# Via TaskCreate
TaskCreate:
  subject: "Implement user authentication"
  description: "Add OAuth2 login flow with JWT token management"
  metadata:
    type: "feature"
    tags: ["code_implementation", "security"]
    priority: "high"
    estimated_tokens: 30000
    parent_milestone: "核心功能开发"
```

## Task Dispatch

Auto-dispatch unassigned tasks:
```bash
python scripts/task_dispatcher.py --state-dir .paperclip --company-dir .
```

Dispatch rules:
1. Match task tags to agent capabilities
2. Consider agent workload (fewer tasks = higher priority)
3. Check budget availability for that agent
4. Assign to highest-scoring available agent

## Task Checkout (Atomic)

To prevent two agents from working on the same task:

```
1. Agent reads inbox (TaskList)
2. Agent selects highest-priority task
3. Agent calls TaskUpdate(taskId, status="in_progress")
   → If another agent already claimed it, the update fails atomically
4. If success: agent proceeds with work
5. If failure: agent picks the next task
```

## Task Priority Ordering

Agents should process their inbox in this order:
1. `in_progress` tasks (continue existing work)
2. `in_review` tasks (process feedback)
3. `todo` tasks sorted by: high > normal > low priority
4. Never touch `blocked` tasks (they need unblocking first)

## Sub-Task Delegation

Agents can create sub-tasks for delegation:
```
architect creates "Implement login API" for developer
→ TaskCreate with parent task reference
→ Auto-dispatched to developer agent
→ developer completes → reviewer verifies → parent progresses
```

## Task Metadata Schema

```yaml
metadata:
  type: feature | bug | review | design | deploy | test | docs | security
  tags: [capability_tags]       # For dispatch matching
  priority: high | normal | low
  estimated_tokens: number      # Budget estimation
  parent_milestone: string      # Link to company milestone
  parent_task: string           # Parent for sub-tasks
  reviewer: string              # Designated reviewer
  deadline: ISO8601             # Optional deadline
```

## Task Comments

Use TaskUpdate to add progress comments:
```
TaskUpdate(taskId, description="[ORIGINAL]\n\n[2026-05-31 14:30] Implemented JWT middleware. Tests passing.")
```
