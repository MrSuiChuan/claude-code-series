#!/usr/bin/env python3
"""
PaperClip Cost Reporter
========================
Generates cost/budget reports for PaperClip-managed companies.

Usage:
    python cost_reporter.py --state-dir .paperclip [--format json|text|summary]
"""

import os
import sys
import json
import argparse
from datetime import datetime
from pathlib import Path


def generate_report(state_dir, format="summary"):
    """Generate cost report from PaperClip state."""
    state_file = Path(state_dir) / "state.json"
    if not state_file.exists():
        print('{"error": "No state file found"}')
        return

    with open(state_file, "r", encoding="utf-8") as f:
        state = json.load(f)

    budget = state.get("budget", {})
    tasks = state.get("tasks", {})
    agents = state.get("agents", {})

    total = budget.get("total_allocated", 0)
    spent = budget.get("spent", 0)
    remaining = total - spent
    pct = (spent / total * 100) if total > 0 else 0

    # Per-agent cost breakdown
    agent_costs = {}
    for agent_id, agent_data in agents.items():
        agent_costs[agent_id] = {
            "spent": agent_data.get("tokens_spent", 0),
            "tasks_completed": agent_data.get("tasks_completed", 0),
        }

    # Per-task cost breakdown
    task_costs = []
    for tid, task in tasks.items():
        task_costs.append({
            "task_id": tid,
            "title": task.get("title", "")[:50],
            "cost": task.get("tokens_spent", 0),
            "status": task.get("status", "unknown"),
            "assignee": task.get("assignee", "unassigned"),
        })
    task_costs.sort(key=lambda x: x["cost"], reverse=True)

    report = {
        "generated_at": datetime.now().isoformat(),
        "budget": {
            "total": total,
            "spent": spent,
            "remaining": remaining,
            "percent_used": round(pct, 1),
            "status": "critical" if pct > 90 else ("warning" if pct > 75 else "ok"),
        },
        "agent_costs": agent_costs,
        "top_expensive_tasks": task_costs[:5],
        "total_tasks": len(tasks),
        "completed_tasks": sum(1 for t in tasks.values() if t.get("status") == "done"),
        "in_progress_tasks": sum(1 for t in tasks.values() if t.get("status") == "in_progress"),
    }

    if format == "json":
        print(json.dumps(report, indent=2, ensure_ascii=False))
    elif format == "summary":
        print(f"""
╔══════════════════════════════════════╗
║   PaperClip Budget Report            ║
╠══════════════════════════════════════╣
║  Total Budget:    {total:>10,} tokens     ║
║  Spent:           {spent:>10,} tokens     ║
║  Remaining:       {remaining:>10,} tokens     ║
║  Used:            {pct:>9.1f}%            ║
║  Status:          {report['budget']['status']:<20s} ║
╠══════════════════════════════════════╣
║  Tasks: {report['total_tasks']:>3d} total                      ║
║         {report['completed_tasks']:>3d} completed                  ║
║         {report['in_progress_tasks']:>3d} in progress               ║
╚══════════════════════════════════════╝
""")
        if task_costs:
            print("  Top Tasks by Cost:")
            for t in task_costs[:5]:
                print(f"    [{t['status']:11s}] {t['task_id']}: {t['cost']:>8,} tokens - {t['title']}")

        if agent_costs:
            print("\n  Per-Agent Costs:")
            for aid, ac in agent_costs.items():
                print(f"    {aid:<15s}: {ac['spent']:>8,} tokens ({ac['tasks_completed']} tasks)")

    else:  # text
        print(f"PaperClip Budget Report ({datetime.now().strftime('%Y-%m-%d %H:%M')})")
        print(f"Budget: {spent:,}/{total:,} tokens ({pct:.1f}%) - {report['budget']['status']}")
        print(f"Tasks: {report['completed_tasks']}/{report['total_tasks']} completed, {report['in_progress_tasks']} in progress")

    return report


def main():
    parser = argparse.ArgumentParser(description="PaperClip Cost Reporter")
    parser.add_argument("--state-dir", required=True, help="Path to .paperclip state directory")
    parser.add_argument("--format", choices=["json", "text", "summary"], default="summary", help="Output format")

    args = parser.parse_args()
    generate_report(args.state_dir, args.format)


if __name__ == "__main__":
    main()
