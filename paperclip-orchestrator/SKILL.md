---
name: paperclip-orchestrator
description: PaperClip Orchestrator - AI agent orchestration platform for managing multi-agent companies with org charts, heartbeat scheduling, task queues, budget tracking, and governance. Use when the user wants to orchestrate AI agents as a structured team, set up recurring agent check-ins, manage multi-agent projects, or create agent workflows. Triggers on /paperclip, "agent company", "orchestrate agents", "agent team".
---

# PaperClip Orchestrator

Orchestrate multiple AI agents as a structured "company" — define org charts, assign roles, schedule heartbeats, manage task queues, enforce budgets, and govern autonomous workflows.

All state stored as JSON files under `.paperclip/`. No database required.

## Command Mapping

When the user invokes `/paperclip`, map their input to `paperclip.py`:

| User Input | Execute |
|------------|---------|
| `/paperclip init <name> [--budget N] [--design brand]` | `python scripts/paperclip.py init <name> --budget N` |
| `/paperclip start <name>` | `python scripts/paperclip.py start <name>` |
| `/paperclip status <name>` | `python scripts/paperclip.py status <name>` |
| `/paperclip task <name> "<title>" [--type T] [--priority P]` | `python scripts/paperclip.py task <name> "<title>" --type T --priority P` |
| `/paperclip budget <name>` | `python scripts/paperclip.py budget <name>` |
| `/paperclip heartbeat <name> --agent <id>` | `python scripts/paperclip.py heartbeat <name> --agent <id>` |
| `/paperclip pause <name>` | `python scripts/paperclip.py pause <name>` |
| `/paperclip resume <name>` | `python scripts/paperclip.py resume <name>` |
| `/paperclip setup [name] [--pro]` | `python scripts/paperclip.py setup <name>` |

**First run only** — install dependencies:
```bash
pip install -r scripts/requirements.txt
```

`<name>` is the company/project directory. If omitted, use the current directory or ask the user.

## Core Concepts

| PaperClip Concept | Claude Code Tool |
|-------------------|-----------------|
| Company | YAML config + file-based state |
| Org Chart | Agent role prompts |
| Agent | Agent tool (subagent) |
| Heartbeat | CronCreate |
| Task/Issue | TaskCreate / TaskUpdate |
| Checkout | File-based atomic write |
| Budget | budget.total/spent/remaining |
| Board | AskUserQuestion |

## Runtime State Structure

```
my-project/
├── company.yaml           # Company config (user-editable)
├── agents.yaml            # Agent role definitions (user-editable)
├── rules.yaml             # Governance rules (user-editable)
└── .paperclip/            # Runtime state (auto-managed, no database)
    ├── company.json       # Company info + schema_version
    ├── budget.json        # Budget tracking
    ├── audits.jsonl       # Append-only audit log
    ├── agents/            # One JSON file per agent (no write conflicts)
    │   ├── architect.json
    │   ├── developer.json
    │   ├── reviewer.json
    │   ├── tester.json
    │   └── operator.json
    ├── tasks/             # One JSON file per task
    │   ├── task_001.json
    │   └── task_002.json
    └── design/            # DESIGN.md cache (optional, Layer 4)
```

## Unified CLI

All commands via `python scripts/paperclip.py`:

| Command | Action |
|---------|--------|
| `init <name> [--budget N] [--design brand]` | Create new company |
| `start <name>` | Generate CronCreate prompts for all agents |
| `status <name>` | Show company dashboard |
| `task <name> "<title>" [--type T] [--priority P]` | Create and auto-dispatch task |
| `budget <name> [--format json|summary]` | Show cost report |
| `heartbeat <name> --agent <id>` | Run single agent heartbeat |
| `pause <name>` | Generate CronDelete prompts |
| `resume <name>` | Re-generate CronCreate prompts |
| `setup [name] [--pro] [--budget N]` | One-command full setup |

## Workflow

### 1. Initialize a Company

```bash
python scripts/paperclip.py init my-project --budget 500000
```

Creates `company.yaml`, `agents.yaml`, `rules.yaml`, and `.paperclip/` with file-based state.
See `references/company-structure.md` for full configuration reference.

### 2. Define Agent Roles

Agent roles defined in `agents.yaml`. Five default roles: architect, developer, reviewer, operator, tester.
See `references/agent-roles.md` for the complete role library.

### 3. Schedule Heartbeats

```bash
python scripts/paperclip.py start my-project
```

Outputs CronCreate specifications. Claude Code registers each agent's heartbeat.

Protocol: Wake → Check inbox → Auto-checkout task → Generate execution prompt → Execute → Report
See `references/heartbeat-system.md` for scheduling patterns.

### 4. Manage Tasks

Lifecycle: `todo → in_progress → in_review → done`

```bash
# Create and auto-dispatch
python scripts/paperclip.py task my-project "Implement JWT login" --type feature

# Or use the dispatcher directly
python scripts/task_dispatcher.py --company-dir ./my-project
python scripts/task_dispatcher.py --company-dir ./my-project --create --title "Fix login bug" --type bug
```

See `references/task-lifecycle.md` for complete lifecycle.

### 5. Track Budget

```bash
python scripts/paperclip.py budget my-project
# or directly:
python scripts/cost_reporter.py --company-dir ./my-project --format summary
```

Enforces per-task caps, daily limits, auto-throttling at 80%.
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

### Quick Setup (Pro)

```bash
# One-command full setup with external skills
python scripts/paperclip.py setup my-project --pro --budget 500000

# Init with a design brand
python scripts/paperclip.py init my-app --design vercel

# Browse and select a brand
python scripts/design_fetcher.py search "dark saas"
python scripts/design_fetcher.py fetch vercel --output ./my-project
```

### Role → Skill Mapping

| Role | Engineering (Matt Pocock) | Design (Taste) |
|------|--------------------------|----------------|
| Architect | /grill-me, /to-prd, /to-issues, /grill-with-docs, /zoom-out | - |
| Developer | /tdd, /diagnose, /prototype, /caveman, /handoff | taste-skill, output-skill, image-to-code, soft-skill, minimalist-skill |
| Reviewer | /triage, /code-review, /diagnose, /zoom-out, /grill-me | taste-skill (frontend), output-skill |
| Tester | /tdd, /diagnose, /triage | - |
| Operator | /diagnose, /triage, /handoff | - |

See `references/skill-matrix.md` for the complete cross-reference.
