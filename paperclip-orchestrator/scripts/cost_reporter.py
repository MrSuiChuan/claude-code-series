#!/usr/bin/env python3
"""
PaperClip Cost Reporter
========================
Generates cost/budget reports from file-based PaperClip state.
Aggregates agent/*.json and tasks/*.json into budget summaries.

Usage:
    python cost_reporter.py --company-dir ./my-project [--format summary|json|text]
"""

import json
import argparse
from datetime import datetime
from pathlib import Path


def _paperclip_dir(company_dir):
    return Path(company_dir) / ".paperclip"


def _load_json(path):
    if path.exists():
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return None


def _save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def generate_report(company_dir, fmt="summary"):
    """Aggregate budget from agent and task files, write updated budget.json."""
    pp_dir = _paperclip_dir(company_dir)
    budget = _load_json(pp_dir / "budget.json") or {}

    total = budget.get("total_allocated", 0)

    # ---- Aggregate from agent files ----
    agent_costs = {}
    total_spent_agents = 0
    agents_dir = pp_dir / "agents"
    if agents_dir.exists():
        for af in agents_dir.glob("*.json"):
            agent = _load_json(af)
            if agent:
                spent = agent.get("tokens_spent", 0)
                agent_costs[af.stem] = {
                    "display_name": agent.get("display_name", af.stem),
                    "spent": spent,
                    "tasks_completed": agent.get("tasks_completed", 0),
                    "status": agent.get("status", "idle"),
                }
                total_spent_agents += spent

    # ---- Aggregate from task files ----
    task_costs = []
    total_tasks = 0
    completed = 0
    in_progress = 0
    tasks_dir = pp_dir / "tasks"
    if tasks_dir.exists():
        for tf in tasks_dir.glob("task_*.json"):
            task = _load_json(tf)
            if task:
                total_tasks += 1
                status = task.get("status", "unknown")
                if status == "done":
                    completed += 1
                elif status == "in_progress":
                    in_progress += 1
                task_costs.append({
                    "task_id": task.get("task_id", tf.stem),
                    "title": (task.get("title", "") or "")[:50],
                    "cost": task.get("tokens_spent", 0),
                    "status": status,
                    "assignee": task.get("assignee", "unassigned"),
                })

    task_costs.sort(key=lambda x: x["cost"], reverse=True)
    spent = total_spent_agents  # Agent tally is authoritative
    remaining = total - spent
    pct = (spent / total * 100) if total > 0 else 0

    # ---- Update budget.json ----
    budget["spent"] = spent
    budget["last_updated"] = datetime.now().isoformat()
    _save_json(pp_dir / "budget.json", budget)

    report = {
        "generated_at": datetime.now().isoformat(),
        "company": pp_dir.parent.name,
        "budget": {
            "total": total,
            "spent": spent,
            "remaining": remaining,
            "percent_used": round(pct, 1),
            "status": "critical" if pct > 90 else ("warning" if pct > 75 else "ok"),
        },
        "agent_costs": agent_costs,
        "top_expensive_tasks": task_costs[:5],
        "total_tasks": total_tasks,
        "completed_tasks": completed,
        "in_progress_tasks": in_progress,
    }

    if fmt == "json":
        print(json.dumps(report, indent=2, ensure_ascii=False))
    elif fmt == "summary":
        b = report["budget"]
        print(f"""
╔══════════════════════════════════════╗
║   PaperClip Budget Report            ║
╠══════════════════════════════════════╣
║  Total Budget:    {total:>10,} tokens     ║
║  Spent:           {spent:>10,} tokens     ║
║  Remaining:       {remaining:>10,} tokens     ║
║  Used:            {pct:>9.1f}%            ║
║  Status:          {b['status']:<20s} ║
╠══════════════════════════════════════╣
║  Tasks: {total_tasks:>3d} total                      ║
║         {completed:>3d} completed                  ║
║         {in_progress:>3d} in progress               ║
╚══════════════════════════════════════╝
""")
        if task_costs:
            print("  Top Tasks by Cost:")
            for t in task_costs[:5]:
                print(f"    [{t['status']:11s}] {t['task_id']}: {t['cost']:>8,} tokens - {t['title']}")

        if agent_costs:
            print("\n  Per-Agent Costs:")
            for aid, ac in agent_costs.items():
                print(f"    {ac['display_name']:<10s} ({aid:<12s}): {ac['spent']:>8,} tokens ({ac['tasks_completed']} tasks)")
    else:
        print(f"PaperClip Budget Report ({datetime.now().strftime('%Y-%m-%d %H:%M')})")
        print(f"Budget: {spent:,}/{total:,} tokens ({pct:.1f}%) - {report['budget']['status']}")
        print(f"Tasks: {completed}/{total_tasks} completed, {in_progress} in progress")

    return report


def main():
    parser = argparse.ArgumentParser(description="PaperClip Cost Reporter")
    parser.add_argument("--company-dir", required=True, help="Path to company directory")
    parser.add_argument("--format", choices=["json", "text", "summary"], default="summary")

    args = parser.parse_args()
    generate_report(args.company_dir, args.format)


if __name__ == "__main__":
    main()
