---
name: paperclip-orchestrator
description: PaperClip Orchestrator v2.0 — AI agent orchestration platform with 6 native sub-agents, automated hooks, heartbeat scheduling, task queues, and budget governance. Use when the user wants to orchestrate AI agents as a structured team, set up recurring agent check-ins, manage multi-agent projects, or create agent workflows. Triggers on /paperclip, "agent company", "orchestrate agents", "agent team".
---

# PaperClip Orchestrator v2.0

Orchestrate multiple AI agents as a structured "company" — define org charts, assign roles, schedule heartbeats, manage task queues, enforce budgets, and govern autonomous workflows.

All state stored as JSON files under `.paperclip/`. No database required.

**Full documentation:** See [README.md](README.md) for quickstart guide, complete walkthrough, and FAQ.

## v2.0 New: Native Sub-Agents & Hooks

PaperClip v2.0 ships with **6 native Claude Code sub-agents** and **3 automation hooks**. `/agents` to discover, hooks run automatically.

| Component | Count | Details |
|-----------|-------|---------|
| **Sub-Agents** (`agents/`) | 6 | architect (opus), developer, reviewer, tester, operator (sonnet), design-fetcher (haiku) |
| **Hooks** (`hooks/hooks.json`) | 3 | SessionStart dashboard, PostToolUse audit, SubagentStop heartbeat |

How it works:
1. User creates a task → auto-dispatched to matching agent role
2. Heartbeat fires → Claude invokes the **native sub-agent** (e.g., `paperclip-architect`) with independent context
3. Sub-agent reads its state from `.paperclip/`, executes the task, updates status
4. Hooks auto-append audit logs and update heartbeat timestamps — no manual bookkeeping

## Two Operating Modes

### Mode A: Dialogue (primary, no dependencies)

All operations happen in Claude Code conversation. Use natural language or slash commands:

| Operation | How |
|-----------|-----|
| Init company | `/paperclip-init` or "用 PaperClip 初始化 my-project" |
| Dashboard | `/paperclip-status` |
| Create task | "创建任务 '标题' --type feature" |
| Execute | "开始" — Claude invokes the matching sub-agent |
| Budget | `/paperclip-status --company-dir ./my-project` |

### Mode B: Terminal CLI

```bash
# Quick init
./bin/paperclip-init my-project --budget 500000

# Budget report
/paperclip-status --company-dir ./my-project

# Fetch design brand
（design-fetcher agent 自动获取）
```

No `pip install` required. Zero Python dependencies (PyYAML removed in v2.1).

## Command Mapping

| User Input | Execution |
|------------|-----------|
| `init <name> [--budget N]` | Write company.json from template + .paperclip/* |
| `start <name>` | Register CronCreate jobs (one per agent), record IDs in company.json |
| `status <name>` | Read .paperclip/agents/*.json + tasks/*.json, summarize |
| `task <name> "<title>" [--type T]` | Write task_NNN.json with auto-dispatch |
| `budget <name>` | `/paperclip-status --company-dir ./<name>` |
| `heartbeat <name> --agent <id>` | Invoke paperclip-<role> sub-agent via Agent tool |
| `pause <name>` | CronDelete all heartbeat job IDs |
| `resume <name>` | Same as start (re-register CronCreate) |

**Natural language triggers:**
- "启动心跳" → start heartbeats
- "开始" / "继续" → invoke paperclip sub-agent with pending tasks
- "测试" → invoke paperclip-tester
- "查看状态" → show dashboard
- `/agents` → discover all 6 paperclip sub-agents

## Six Native Sub-Agents

| Sub-Agent | `/agents` Name | Model | Max Turns | Use When |
|-----------|---------------|-------|-----------|----------|
| 🏗️ Architect | `paperclip-architect` | opus | 30 | design tasks, architecture, decomposition |
| 💻 Developer | `paperclip-developer` | sonnet | 25 | feature, bug, refactor, docs |
| 🔍 Reviewer | `paperclip-reviewer` | sonnet | 20 | review, security audit, in_review tasks |
| 🧪 Tester | `paperclip-tester` | sonnet | 20 | test creation, bug reporting |
| ⚙️ Operator | `paperclip-operator` | sonnet | 15 | deploy, monitor, automation |
| 🎨 Design | `paperclip-design-fetcher` | haiku | 10 | fetch DESIGN.md for brand specs |

Sub-agents are defined in `agents/*.md`. Each has independent context, model selection, and tool permissions. The Developer cannot create Cron jobs; the Architect uses opus for deeper reasoning.

## Three Automation Hooks

| Hook | Event | Behavior |
|------|-------|----------|
| Dashboard | `SessionStart` | Auto-displays company status when `.paperclip/` exists |
| Audit | `PostToolUse` | Auto-appends to `audits.jsonl` on task status changes |
| Heartbeat | `SubagentStop` | Auto-updates `last_heartbeat` when a paperclip sub-agent finishes |

Hooks are defined in `hooks/hooks.json`. They eliminate manual bookkeeping — no more manually typing audit entries or updating timestamps after every task.

## Core Concepts

| PaperClip Concept | Claude Code Implementation |
|-------------------|---------------------------|
| Company | YAML config + file-based state |
| Org Chart (v2.1) | `agents/*.md` `paperclip:` frontmatter — one source of truth |
| Agent | Native sub-agent with independent context, model, and permissions |
| Heartbeat | CronCreate scheduled prompts |
| Task/Issue | `.paperclip/tasks/*.json` files |
| Checkout | File-based atomic write |
| Budget | `budget.json` tracking |
| Board | AskUserQuestion for approvals |
| Hooks (v2.0) | Auto-audit, auto-heartbeat, session dashboard |

## Runtime State Structure

```
my-project/
├── company.json           # Company config (JSON, user-editable)
└── .paperclip/            # Runtime state (auto-managed, no database)
    ├── company.json       # Company info + schema_version + heartbeat IDs
    ├── budget.json        # Budget tracking
    ├── audits.jsonl       # Append-only audit log (auto-managed by hooks)
    ├── agents/            # One JSON file per agent (no write conflicts)
    │   ├── architect.json
    │   ├── developer.json
    │   ├── reviewer.json
    │   ├── tester.json
    │   └── operator.json
    ├── tasks/             # One JSON file per task
    │   ├── task_001.json
    │   └── task_002.json
    └── design/            # DESIGN.md cache (optional, fetched by design-fetcher agent)
```

## Plugin Structure (v2.0)

```
paperclip-orchestrator/
├── .claude-plugin/plugin.json   # v2.0.0 — registers skills, agents, hooks
├── SKILL.md                     # This file
├── README.md                    # Full documentation
├── agents/                      # 🆕 6 native sub-agents
│   ├── architect.md
│   ├── developer.md
│   ├── reviewer.md
│   ├── tester.md
│   ├── operator.md
│   └── design-fetcher.md
├── hooks/                       # 🆕 Automation hooks
│   └── hooks.json
├── assets/company_template/     # Templates for company init
├── scripts/                     # Python CLI helpers
└── references/                  # Detailed reference docs
```

## Workflow

### 1. Initialize a Company

```bash
./bin/paperclip-init my-project --budget 500000
```

Creates `company.json` and `.paperclip/` with file-based state.
See `references/company-structure.md` for full configuration reference.

### 2. Define Agent Roles

Agent roles defined in each `agents/*.md` file under the `paperclip:` frontmatter. Six default roles: architect (opus), developer, reviewer, tester, operator (sonnet), design-fetcher (haiku). Each sub-agent carries its own capabilities, budget share, and role definition.

The legacy `agents.yaml` is no longer generated for new companies, but existing companies with the file continue to work.

### 3. Schedule Heartbeats

```
"启动心跳"（在对话中对 Claude 说）
```

Registers CronCreate jobs. At each heartbeat, Claude invokes the corresponding `paperclip-*` sub-agent.

Protocol: CronCreate fires → Claude invokes sub-agent → Sub-agent reads state → Executes → Reports → Hook updates timestamps
See `references/heartbeat-system.md` for scheduling patterns.

### 4. Manage Tasks

Lifecycle: `todo → in_progress → in_review → done`

```
"创建任务 'Implement JWT login' --type feature"（在对话中对 Claude 说）
```

See `references/task-lifecycle.md` for complete lifecycle.

### 5. Track Budget

```bash
/paperclip-status --company-dir ./my-project --format summary
```

Enforces per-task caps, daily limits, auto-throttling at 80%.
See `references/budget-governance.md` for governance rules.

### 6. Multi-Agent Workflows

With native sub-agents in v2.0, use Workflow.pipeline or Workflow.parallel for concurrent agent execution:
- Architect designs → Developer implements → Reviewer verifies (pipeline)
- Developer + Tester run in parallel on independent tasks
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
# Init with a design brand — v2.2: design-fetcher agent auto-fetches DESIGN.md
./bin/paperclip-init my-app --budget 500000
（design-fetcher agent 自动获取）

# Browse and select a brand
（design-fetcher agent 自动获取）
（design-fetcher agent 自动获取）
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
