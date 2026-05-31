#!/usr/bin/env python3
"""
PaperClip Heartbeat Worker
==========================
Executes a single heartbeat cycle for a PaperClip agent.
This is called by CronCreate-scheduled jobs and follows the PaperClip heartbeat protocol.

Heartbeat Protocol:
1. Wake up and check agent identity
2. Check for pending approvals
3. Get inbox (assigned tasks)
4. Prioritize and checkout a task
5. Execute the task
6. Report status and exit
"""

import os
import sys
import json
import argparse
from datetime import datetime
from pathlib import Path


def load_state(state_dir):
    """Load PaperClip runtime state."""
    state_file = Path(state_dir) / "state.json"
    if state_file.exists():
        with open(state_file, "r", encoding="utf-8") as f:
            return json.load(f)
    return None


def save_state(state_dir, state):
    """Save PaperClip runtime state."""
    state_file = Path(state_dir) / "state.json"
    with open(state_file, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)


def get_inbox(state, agent_id):
    """Get agent's task inbox, prioritized."""
    tasks = state.get("tasks", {})
    assigned = [
        (tid, t) for tid, t in tasks.items()
        if t.get("assignee") == agent_id
    ]

    # Priority order: in_progress > in_review > todo
    priority = {"in_progress": 0, "in_review": 1, "todo": 2, "done": 99}

    assigned.sort(key=lambda x: priority.get(x[1].get("status", "todo"), 50))
    return assigned


def heartbeat_report(agent_id, state_dir):
    """Generate a heartbeat status report for Claude to read."""
    state = load_state(state_dir)
    if not state:
        return {"status": "no_state", "message": "No PaperClip state found. Run init_company first."}

    inbox = get_inbox(state, agent_id)
    budget = state.get("budget", {})

    report = {
        "agent_id": agent_id,
        "timestamp": datetime.now().isoformat(),
        "budget": {
            "total": budget.get("total_allocated", 0),
            "spent": budget.get("spent", 0),
            "remaining": budget.get("total_allocated", 0) - budget.get("spent", 0),
        },
        "inbox_size": len(inbox),
        "inbox": [
            {
                "task_id": tid,
                "status": t.get("status"),
                "title": t.get("title", ""),
                "priority": t.get("priority", "normal"),
            }
            for tid, t in inbox[:10]  # Top 10
        ],
        "audit_trail": state.get("audit_log", [])[-5:],  # Last 5 events
    }

    return report


def main():
    parser = argparse.ArgumentParser(description="PaperClip Heartbeat Worker")
    parser.add_argument("--agent-id", required=True, help="Agent ID executing this heartbeat")
    parser.add_argument("--state-dir", required=True, help="Path to .paperclip state directory")
    parser.add_argument("--company-dir", required=True, help="Path to company directory")
    parser.add_argument("--report-only", action="store_true", help="Only generate report, don't execute")

    args = parser.parse_args()

    report = heartbeat_report(args.agent_id, args.state_dir)

    # Output report as JSON for Claude to consume
    print(json.dumps(report, indent=2, ensure_ascii=False))

    # Return next action hint
    if report["inbox_size"] > 0:
        next_task = report["inbox"][0]
        print(f"\n[NEXT] Checkout task: {next_task['task_id']} - {next_task['title']}")
        print(f"[ACTION] Use TaskUpdate to set status=in_progress on task {next_task['task_id']}")
    else:
        print("\n[IDLE] No tasks in inbox. Waiting for assignments.")
        print("[IDLE] Check for new tasks or wait for next heartbeat.")


if __name__ == "__main__":
    main()
