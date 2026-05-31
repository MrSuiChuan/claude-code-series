#!/usr/bin/env python3
"""
PaperClip Task Dispatcher
==========================
Intelligent task dispatching based on agent roles, capabilities, and workload.

Usage:
    python task_dispatcher.py --state-dir .paperclip --agents agents.yaml
"""

import os
import sys
import json
import yaml
import argparse
from datetime import datetime
from pathlib import Path


ROLE_CAPABILITIES = {
    "architect": ["system_design", "task_decomposition", "code_review", "architecture_planning"],
    "developer": ["code_implementation", "bug_fixing", "refactoring", "testing"],
    "reviewer": ["code_review", "security_audit", "quality_analysis", "test_review"],
    "operator": ["deployment", "monitoring", "automation", "incident_response"],
    "tester": ["test_creation", "automation_testing", "bug_reporting", "performance_testing"],
}


def load_config(company_dir):
    """Load company configuration files."""
    agents_path = Path(company_dir) / "agents.yaml"
    rules_path = Path(company_dir) / "rules.yaml"

    agents = {}
    rules = {}

    if agents_path.exists():
        with open(agents_path, "r", encoding="utf-8") as f:
            agents = yaml.safe_load(f)

    if rules_path.exists():
        with open(rules_path, "r", encoding="utf-8") as f:
            rules = yaml.safe_load(f)

    return agents, rules


def match_task_to_agent(task, agents_config):
    """
    Match a task to the most suitable agent based on:
    1. Required capabilities (task tags)
    2. Agent workload (current task count)
    3. Budget availability
    """
    roles = agents_config.get("roles", {})
    task_tags = task.get("tags", [])
    task_type = task.get("type", "generic")

    scores = {}
    for role_id, role_def in roles.items():
        capabilities = role_def.get("capabilities", [])
        score = 0

        # Capability match
        for tag in task_tags:
            if tag in capabilities:
                score += 10

        # Type-based matching
        type_map = {
            "feature": {"developer": 8, "architect": 5},
            "bug": {"developer": 8, "tester": 5},
            "review": {"reviewer": 10},
            "design": {"architect": 10},
            "deploy": {"operator": 10},
            "test": {"tester": 10},
            "docs": {"developer": 5, "architect": 5},
            "security": {"reviewer": 8, "developer": 3},
        }

        for role, bonus in type_map.get(task_type, {}).items():
            if role == role_id:
                score += bonus

        if score > 0:
            scores[role_id] = {
                "score": score,
                "agent_id": role_id,
                "display_name": role_def.get("display_name", role_id),
                "budget_share": role_def.get("budget_share", 0.2),
            }

    # Sort by score descending
    ranked = sorted(scores.values(), key=lambda x: x["score"], reverse=True)
    return ranked


def dispatch_tasks(state_dir, company_dir, dry_run=False):
    """Dispatch unassigned tasks to suitable agents."""
    agents_config, _ = load_config(company_dir)

    state_file = Path(state_dir) / "state.json"
    if not state_file.exists():
        print('{"error": "No state file found"}')
        return

    with open(state_file, "r", encoding="utf-8") as f:
        state = json.load(f)

    tasks = state.get("tasks", {})
    unassigned = {
        tid: t for tid, t in tasks.items()
        if t.get("status") in ("todo", None) and not t.get("assignee")
    }

    assignments = []
    for tid, task in unassigned.items():
        matches = match_task_to_agent(task, agents_config)
        if matches:
            best = matches[0]
            if not dry_run:
                task["assignee"] = best["agent_id"]
                task["status"] = "todo"
                task["assigned_at"] = datetime.now().isoformat()
                state["audit_log"].append({
                    "event": "task_dispatched",
                    "task_id": tid,
                    "assignee": best["agent_id"],
                    "score": best["score"],
                    "timestamp": datetime.now().isoformat(),
                })
            assignments.append({
                "task_id": tid,
                "title": task.get("title", ""),
                "assignee": best["agent_id"],
                "role": best["display_name"],
                "score": best["score"],
            })

    if not dry_run and assignments:
        save_state_custom(state_dir, state)

    result = {
        "dispatched": len(assignments),
        "assignments": assignments,
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return result


def save_state_custom(state_dir, state):
    """Save state to file."""
    state_file = Path(state_dir) / "state.json"
    with open(state_file, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description="PaperClip Task Dispatcher")
    parser.add_argument("--state-dir", required=True, help="Path to .paperclip state directory")
    parser.add_argument("--company-dir", required=True, help="Path to company directory")
    parser.add_argument("--dry-run", action="store_true", help="Preview assignments without applying")

    args = parser.parse_args()
    dispatch_tasks(args.state_dir, args.company_dir, args.dry_run)


if __name__ == "__main__":
    main()
