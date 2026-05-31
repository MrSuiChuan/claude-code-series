---
name: paperclip-orchestrator
description: PaperClip Orchestrator - AI agent orchestration platform for managing multi-agent companies with org charts, heartbeat scheduling, task queues, budget tracking, and governance. Use when the user wants to orchestrate AI agents as a structured team, set up recurring agent check-ins, manage multi-agent projects, or create agent workflows. Triggers on /paperclip, "agent company", "orchestrate agents", "agent team".
---

# PaperClip Orchestrator

Orchestrate multiple AI agents as a structured "company" — define org charts, assign roles, schedule heartbeats, manage task queues, enforce budgets, and govern autonomous workflows.

## Quick Start

```
User: /paperclip init my-project
→ Creates company config with 5 agent roles

User: /paperclip start my-project
→ Sets up heartbeat schedules and begins orchestration

User: /paperclip create-task "Add user authentication" --type feature
→ Creates task, auto-dispatches to developer agent

User: /paperclip status
→ Shows budget, task board, agent status
```

## Core Concepts

This skill implements the PaperClip orchestration model using Claude Code's native tools:

| PaperClip Concept | Claude Code Tool |
|-------------------|-----------------|
| Company | YAML config + file-based state |
| Org Chart | Agent role prompts |
| Agent | Agent tool (subagent) |
| Heartbeat | CronCreate |
| Task/Issue | TaskCreate / TaskUpdate |
| Checkout | TaskUpdate (atomic) |
| Budget | budget.total/spent/remaining |
| Board | AskUserQuestion |

## Workflow

### 1. Initialize a Company

Run `scripts/init_company.py` to create a company configuration:
```bash
python scripts/init_company.py --name my-project --budget 500000
```

This creates `company.yaml`, `agents.yaml`, `rules.yaml`, and `.paperclip/state.json`.
See `references/company-structure.md` for full configuration reference.

### 2. Define Agent Roles

Load agent roles from `agents.yaml`. See `references/agent-roles.md` for the complete role library (architect, developer, reviewer, operator, tester + custom roles).

### 3. Schedule Heartbeats

Set up recurring agent check-ins using CronCreate:
```
CronCreate:
  cron: "*/10 * * * *"  # Every 10 minutes
  prompt: "PaperClip heartbeat: check inbox, execute tasks"
```

Protocol: Wake → Check inbox → Prioritize → Checkout task → Execute → Report → Exit
See `references/heartbeat-system.md` for scheduling patterns.

### 4. Manage Tasks

Use TaskCreate/TaskUpdate for the lifecycle: `todo → in_progress → in_review → done`
- **Create**: TaskCreate with title, description, type, tags
- **Dispatch**: Auto-assign via `scripts/task_dispatcher.py`
- **Checkout**: Atomic via TaskUpdate (prevents double-assignment)
- **Review**: Reviewer agent inspects and approves/rejects
See `references/task-lifecycle.md` for complete lifecycle.

### 5. Track Budget

Monitor with `scripts/cost_reporter.py`. Enforces per-task caps, daily limits, auto-throttling at 80%.
See `references/budget-governance.md` for governance rules.

### 6. Multi-Agent Workflows

Pipeline, Parallel Review, Master-Worker, Competitive patterns via Workflow tool.
See `references/workflow-patterns.md` for detailed patterns.

## Pro Mode (4-Layer Integration)

PaperClip Pro integrates four skill layers for production-grade agent teams:

| Layer | Skills | Provides |
|-------|--------|----------|
| **Orchestration** | PaperClip Core | Org chart, heartbeats, task queue, budget, governance |
| **Engineering Quality** | mattpocock/skills | /tdd, /diagnose, /triage, /code-review, /to-prd |
| **Design Taste** | taste-skill | Anti-slop frontend, design variance, motion, visual density |
| **Design Spec** | awesome-design-md | 58+ brand DESIGN.md specs, on-demand fetching |

### Prerequisites
```bash
npx skills@latest add mattpocock/skills
npx skills add https://github.com/Leonxlnx/taste-skill
```

### Quick Setup
```bash
# One-command full setup (all 4 layers)
bash scripts/setup_all.sh my-project 500000

# Init with a design brand
python scripts/init_company.py --name my-app --design vercel

# Browse and select a brand
python scripts/design_fetcher.py search "dark saas"
python scripts/design_fetcher.py fetch vercel --output ./my-project
```

### Role → Skill Mapping (Full 3-Layer)

| Role | Engineering (Matt Pocock) | Design (Taste) |
|------|--------------------------|----------------|
| Architect | /grill-me, /to-prd, /to-issues, /grill-with-docs, /zoom-out | - |
| Developer | /tdd, /diagnose, /prototype, /caveman, /handoff | taste-skill, output-skill, image-to-code, soft-skill, minimalist-skill |
| Reviewer | /triage, /code-review, /diagnose, /zoom-out, /grill-me | taste-skill (frontend), output-skill |
| Tester | /tdd, /diagnose, /triage | - |
| Operator | /diagnose, /triage, /handoff | - |

### Taste Dials (Frontend Tasks)
| Dial | Range | Controls |
|------|-------|----------|
| DESIGN_VARIANCE | 1-10 | Layout creativity (1=safe → 10=wild) |
| MOTION_INTENSITY | 1-10 | Animation richness (1=static → 10=cinematic) |
| VISUAL_DENSITY | 1-10 | Content density (1=spacious → 10=dense) |

See `references/skill-matrix.md` for the complete cross-reference.

## Commands

| Command | Action |
|---------|--------|
| `/paperclip init <name> [--pro]` | Create new company (use --pro for enhanced agents) |
| `/paperclip start <name>` | Begin orchestration |
| `/paperclip status` | Show dashboard |
| `/paperclip create-task <desc>` | Create and dispatch task |
| `/paperclip budget` | Show cost report |
| `/paperclip approve <task-id>` | Board approval |
| `/paperclip pause` | Pause all heartbeats |
| `/paperclip resume` | Resume heartbeats |
