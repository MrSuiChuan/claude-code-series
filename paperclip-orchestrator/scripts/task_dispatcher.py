#!/usr/bin/env python3
"""
PaperClip Task Dispatcher
==========================
Intelligent task dispatching based on agent roles, capabilities, and workload.
Reads capabilities from agents.yaml (single source of truth).

Usage:
    python task_dispatcher.py --company-dir ./my-project [--dry-run]
    python task_dispatcher.py --company-dir ./my-project --task-id task_001
"""

import json
import argparse
import os
from datetime import datetime
from pathlib import Path


def ensure_yaml():
    try:
        import yaml  # noqa: F401
    except ImportError:
        print("[ERROR] PyYAML required. Run: pip install pyyaml")
        raise


def _paperclip_dir(company_dir):
    return Path(company_dir) / ".paperclip"


def _load_json(path):
    if path.exists():
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return None


def _save_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def _append_audit(pp_dir, event, detail=""):
    entry = {"timestamp": datetime.now().isoformat(), "event": event, "detail": detail}
    with open(pp_dir / "audits.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def load_capabilities(company_dir):
    """Read agent capabilities from agents.yaml — the single source of truth."""
    ensure_yaml()
    import yaml

    agents_path = Path(company_dir) / "agents.yaml"
    if not agents_path.exists():
        return {}

    with open(agents_path, "r", encoding="utf-8") as f:
        agents = yaml.safe_load(f)

    return {
        role_id: {
            "capabilities": role.get("capabilities", []),
            "display_name": role.get("display_name", role_id),
            "budget_share": role.get("budget_share", 0.2),
            "level": role.get("level", "execution"),
            "reports_to": role.get("reports_to", ""),
        }
        for role_id, role in agents.get("roles", {}).items()
    }


def match_task_to_agent(task, capabilities):
    """Score each agent based on capability match and task type."""
    task_tags = task.get("tags", [])
    task_type = task.get("type", "generic")

    type_bonus = {
        "feature":     {"developer": 8, "architect": 5},
        "bug":         {"developer": 8, "tester": 5},
        "review":      {"reviewer": 10},
        "design":      {"architect": 10},
        "deploy":      {"operator": 10},
        "test":        {"tester": 10},
        "docs":        {"developer": 5, "architect": 5},
        "security":    {"reviewer": 8, "developer": 3},
        "refactor":    {"developer": 8, "architect": 5},
    }

    scores = {}
    for role_id, role_info in capabilities.items():
        caps = role_info["capabilities"]
        score = 0

        for tag in task_tags:
            if tag in caps:
                score += 10

        for role, bonus in type_bonus.get(task_type, {}).items():
            if role == role_id:
                score += bonus

        if score > 0:
            scores[role_id] = {
                "score": score,
                "agent_id": role_id,
                "display_name": role_info["display_name"],
                "budget_share": role_info["budget_share"],
            }

    return sorted(scores.values(), key=lambda x: x["score"], reverse=True)


def create_task(company_dir, title, description="", task_type="feature",
                priority="normal", tags=None):
    """Create a new task file and dispatch it."""
    pp_dir = _paperclip_dir(company_dir)
    tasks_dir = pp_dir / "tasks"
    tasks_dir.mkdir(parents=True, exist_ok=True)

    # Find next task ID
    existing = list(tasks_dir.glob("task_*.json"))
    next_num = len(existing) + 1
    task_id = f"task_{next_num:03d}"

    capabilities = load_capabilities(company_dir)

    task = {
        "task_id": task_id,
        "title": title,
        "description": description,
        "type": task_type,
        "priority": priority,
        "tags": tags or [],
        "status": "todo",
        "assignee": None,
        "created_at": datetime.now().isoformat(),
        "tokens_spent": 0,
        "history": [{
            "timestamp": datetime.now().isoformat(),
            "event": "created",
        }],
    }

    # Auto-dispatch
    matches = match_task_to_agent(task, capabilities)
    if matches:
        best = matches[0]
        task["assignee"] = best["agent_id"]
        task["assigned_at"] = datetime.now().isoformat()
        task["history"].append({
            "timestamp": datetime.now().isoformat(),
            "event": "dispatched",
            "assignee": best["agent_id"],
            "score": best["score"],
        })

    _save_json(tasks_dir / f"{task_id}.json", task)
    _append_audit(pp_dir, "task_created",
                  f"{task_id}: {title} → {task.get('assignee', 'unassigned')}")

    return task


def dispatch_all(company_dir, dry_run=False):
    """Dispatch all unassigned tasks."""
    pp_dir = _paperclip_dir(company_dir)
    tasks_dir = pp_dir / "tasks"
    if not tasks_dir.exists():
        return {"dispatched": 0, "assignments": []}

    capabilities = load_capabilities(company_dir)
    assignments = []

    for task_file in sorted(tasks_dir.glob("task_*.json")):
        task = _load_json(task_file)
        if not task:
            continue
        if task.get("assignee") or task.get("status") not in ("todo", None):
            continue

        matches = match_task_to_agent(task, capabilities)
        if not matches:
            continue

        best = matches[0]
        if not dry_run:
            task["assignee"] = best["agent_id"]
            task["status"] = "todo"
            task["assigned_at"] = datetime.now().isoformat()
            if "history" not in task:
                task["history"] = []
            task["history"].append({
                "timestamp": datetime.now().isoformat(),
                "event": "dispatched",
                "assignee": best["agent_id"],
                "score": best["score"],
            })
            _save_json(task_file, task)
            _append_audit(pp_dir, "task_dispatched",
                          f"{task.get('task_id')} → {best['agent_id']} (score={best['score']})")

        assignments.append({
            "task_id": task.get("task_id", task_file.stem),
            "title": task.get("title", ""),
            "assignee": best["agent_id"],
            "role": best["display_name"],
            "score": best["score"],
        })

    return {"dispatched": len(assignments), "assignments": assignments}


def main():
    parser = argparse.ArgumentParser(description="PaperClip Task Dispatcher")
    parser.add_argument("--company-dir", required=True, help="Path to company directory")
    parser.add_argument("--dry-run", action="store_true", help="Preview without applying")
    parser.add_argument("--create", action="store_true", help="Create a new task")
    parser.add_argument("--title", help="Task title (with --create)")
    parser.add_argument("--description", default="", help="Task description (with --create)")
    parser.add_argument("--type", default="feature", dest="task_type",
                       choices=["feature","bug","review","design","deploy","test","docs","security","refactor"],
                       help="Task type")
    parser.add_argument("--priority", default="normal",
                       choices=["high", "normal", "low"], help="Task priority")
    parser.add_argument("--tags", default="", help="Comma-separated capability tags")

    args = parser.parse_args()

    if args.create:
        if not args.title:
            print('{"error": "--title is required with --create"}')
            return
        tags = [t.strip() for t in args.tags.split(",") if t.strip()]
        task = create_task(args.company_dir, args.title, args.description,
                          args.task_type, args.priority, tags)
        print(json.dumps(task, indent=2, ensure_ascii=False))
    else:
        result = dispatch_all(args.company_dir, args.dry_run)
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
