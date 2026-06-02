#!/usr/bin/env python3
"""
PaperClip Heartbeat Worker
==========================
Executes a single heartbeat cycle for a PaperClip agent.

Heartbeat Protocol:
1. Wake: load agent state and inbox
2. Check approvals: look for pending board decisions
3. Get inbox: find tasks assigned to this agent (or unassigned, for auto-checkout)
4. Checkout: atomically claim the highest-priority task
5. Generate execution prompt for Claude Code to consume
6. Report status

Usage:
    python heartbeat_worker.py --agent-id developer --company-dir ./my-project
    python heartbeat_worker.py --agent-id all --company-dir ./my-project --report-only
"""

import json
import argparse
import os
from datetime import datetime
from pathlib import Path


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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


def _append_audit(paperclip_dir, event, detail=""):
    entry = {
        "timestamp": datetime.now().isoformat(),
        "event": event,
        "detail": detail,
    }
    with open(paperclip_dir / "audits.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def _task_priority(task):
    order = {"in_progress": 0, "in_review": 1, "todo": 2, "blocked": 99, "done": 99}
    return order.get(task.get("status", "todo"), 50)


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------

def load_agent(paperclip_dir, agent_id):
    """Load agent state from its dedicated JSON file."""
    path = paperclip_dir / "agents" / f"{agent_id}.json"
    if not path.exists():
        return None
    return _load_json(path)


def save_agent(paperclip_dir, agent_id, state):
    """Save agent state to its dedicated JSON file."""
    path = paperclip_dir / "agents" / f"{agent_id}.json"
    _save_json(path, state)


def load_budget(paperclip_dir):
    return _load_json(paperclip_dir / "budget.json") or {
        "total_allocated": 0, "spent": 0, "daily_reset": ""
    }


def get_agent_tasks(paperclip_dir, agent_id):
    """Find all tasks assigned to this agent."""
    tasks_dir = paperclip_dir / "tasks"
    if not tasks_dir.exists():
        return []

    mine = []
    for task_file in sorted(tasks_dir.glob("*.json")):
        task = _load_json(task_file)
        if task and task.get("assignee") == agent_id:
            task["_file"] = task_file.name
            mine.append(task)

    mine.sort(key=_task_priority)
    return mine


def get_unassigned_tasks(paperclip_dir):
    """Find tasks with no assignee."""
    tasks_dir = paperclip_dir / "tasks"
    if not tasks_dir.exists():
        return []

    unassigned = []
    for task_file in sorted(tasks_dir.glob("*.json")):
        task = _load_json(task_file)
        if task and not task.get("assignee") and task.get("status") in ("todo", None):
            task["_file"] = task_file.name
            unassigned.append(task)

    unassigned.sort(key=lambda t: {"high": 0, "normal": 1, "low": 2}.get(
        t.get("priority", "normal"), 1))
    return unassigned


def checkout_task(paperclip_dir, task_file, agent_id, agent_display_name):
    """Atomically claim a task by writing the assignee."""
    path = paperclip_dir / "tasks" / task_file
    task = _load_json(path)
    if not task:
        return False

    if task.get("assignee") and task["assignee"] != agent_id:
        return False  # Already claimed by someone else

    task["assignee"] = agent_id
    task["status"] = "in_progress"
    task["assigned_at"] = datetime.now().isoformat()

    if "history" not in task:
        task["history"] = []
    task["history"].append({
        "timestamp": datetime.now().isoformat(),
        "event": "checked_out",
        "agent": agent_id,
    })

    _save_json(path, task)

    # Update agent state
    agent = load_agent(paperclip_dir, agent_id)
    if agent:
        agent["current_task"] = task.get("task_id", task_file)
        agent["status"] = "working"
        agent["last_heartbeat"] = datetime.now().isoformat()
        save_agent(paperclip_dir, agent_id, agent)

    _append_audit(paperclip_dir, "task_checked_out",
                  f"{agent_display_name} claimed {task.get('title', task_file)}")

    return True


def heartbeat(agent_id, company_dir):
    """Run one heartbeat cycle. Returns a report dict."""
    pp_dir = _paperclip_dir(company_dir)

    agent = load_agent(pp_dir, agent_id)
    if not agent:
        return {"status": "error", "message": f"Agent '{agent_id}' not found. Run init first."}

    budget = load_budget(pp_dir)
    my_tasks = get_agent_tasks(pp_dir, agent_id)
    unassigned = get_unassigned_tasks(pp_dir)

    # Update heartbeat timestamp
    agent["last_heartbeat"] = datetime.now().isoformat()
    save_agent(pp_dir, agent_id, agent)

    remaining = budget.get("total_allocated", 0) - budget.get("spent", 0)
    pct_used = (budget["spent"] / budget["total_allocated"] * 100) if budget["total_allocated"] > 0 else 0

    report = {
        "agent_id": agent_id,
        "display_name": agent.get("display_name", agent_id),
        "timestamp": datetime.now().isoformat(),
        "budget": {
            "total": budget.get("total_allocated", 0),
            "spent": budget.get("spent", 0),
            "remaining": remaining,
            "pct_used": round(pct_used, 1),
            "status": "critical" if pct_used > 90 else ("warning" if pct_used > 75 else "ok"),
        },
        "my_tasks": [
            {
                "task_id": t.get("task_id", t.get("_file", "")),
                "file": t.get("_file", ""),
                "title": t.get("title", ""),
                "status": t.get("status", ""),
                "priority": t.get("priority", "normal"),
                "type": t.get("type", ""),
                "tokens_spent": t.get("tokens_spent", 0),
            }
            for t in my_tasks[:10]
        ],
        "unassigned_count": len(unassigned),
        "top_unassigned": [
            {"task_id": t.get("task_id", t.get("_file", "")),
             "file": t.get("_file", ""),
             "title": t.get("title", ""),
             "type": t.get("type", "")}
            for t in unassigned[:3]
        ],
        "agent_status": agent.get("status", "idle"),
        "agent_tokens_spent": agent.get("tokens_spent", 0),
        "agent_tasks_completed": agent.get("tasks_completed", 0),
    }

    # ---- Auto-checkout logic ----
    action_prompt = ""

    if my_tasks:
        # Continue existing work or process review feedback
        active = [t for t in my_tasks if t.get("status") == "in_progress"]
        review = [t for t in my_tasks if t.get("status") == "in_review"]

        if active:
            top = active[0]
            action_prompt = generate_execution_prompt(agent, top, "continue")
        elif review:
            top = review[0]
            action_prompt = generate_execution_prompt(agent, top, "review")
        else:
            # We have todo tasks — start the top one
            top = my_tasks[0]
            fname = top.get("_file", "")
            if fname and checkout_task(pp_dir, fname, agent_id, agent["display_name"]):
                report["action"] = "checked_out"
                report["checked_out_task"] = top.get("title", fname)
                action_prompt = generate_execution_prompt(agent, top, "start")
    else:
        # No assigned tasks — try to claim an unassigned one
        if unassigned:
            best = unassigned[0]
            fname = best.get("_file", "")
            if fname and checkout_task(pp_dir, fname, agent_id, agent["display_name"]):
                report["action"] = "auto_claimed"
                report["checked_out_task"] = best.get("title", fname)
                action_prompt = generate_execution_prompt(agent, best, "start")
            else:
                report["action"] = "idle"
                action_prompt = f"[IDLE] No tasks available. {agent['display_name']} is waiting."
        else:
            report["action"] = "idle"
            action_prompt = f"[IDLE] {agent['display_name']} has no tasks. Create tasks via 'paperclip task'."

    report["action_prompt"] = action_prompt
    return report


def generate_execution_prompt(agent, task, phase):
    """Generate a Claude-Code-consumable execution prompt."""
    task_title = task.get("title", "unnamed task")
    task_desc = task.get("description", "")
    task_type = task.get("type", "generic")
    task_id = task.get("task_id", task.get("_file", ""))

    role = agent.get("role", "")
    display = agent.get("display_name", role)

    prompts = {
        "developer": f"你是 {display}，请处理任务 [{task_id}]「{task_title}」。\n"
                     f"任务类型: {task_type}\n"
                     f"描述: {task_desc}\n\n"
                     f"工作流程:\n"
                     f"1. 阅读任务上下文，理解要实现什么\n"
                     f"2. feature 类型 → TDD 模式：先写测试 → 实现 → 重构\n"
                     f"3. bug 类型 → 复现 → 定位根因 → 修复 → 加回归测试\n"
                     f"4. 完成后更新任务状态为 in_review\n\n"
                     f"去干吧。",

        "architect": f"你是 {display}，请处理任务 [{task_id}]「{task_title}」。\n"
                     f"描述: {task_desc}\n\n"
                     f"工作流程:\n"
                     f"1. 分析需求，识别关键约束\n"
                     f"2. 设计架构方案\n"
                     f"3. 如需拆解，创建子任务并分配给对应角色\n"
                     f"4. 完成后更新任务状态\n\n"
                     f"去干吧。",

        "reviewer": f"你是 {display}，请审查任务 [{task_id}]「{task_title}」。\n"
                    f"描述: {task_desc}\n\n"
                    f"工作流程:\n"
                    f"1. 检查代码正确性、安全性、可维护性\n"
                    f"2. 通过 → 标记 done\n"
                    f"3. 不通过 → 创建子任务，回退到 in_progress\n\n"
                    f"去干吧。",

        "tester": f"你是 {display}，请处理任务 [{task_id}]「{task_title}」。\n"
                  f"描述: {task_desc}\n\n"
                  f"工作流程:\n"
                  f"1. 编写/运行测试用例\n"
                  f"2. 报告结果\n"
                  f"3. 发现 bug → 创建 bug 子任务\n\n"
                  f"去干吧。",

        "operator": f"你是 {display}，请处理任务 [{task_id}]「{task_title}」。\n"
                    f"描述: {task_desc}\n\n"
                    f"工作流程:\n"
                    f"1. 执行运维/部署/监控任务\n"
                    f"2. 记录操作结果\n"
                    f"3. 异常 → 告警并记录\n\n"
                    f"去干吧。",
    }

    prefix = {
        "start": "[NEW] 新任务，开始执行。\n\n",
        "continue": "[CONTINUE] 继续之前的工作。\n\n",
        "review": "[REVIEW] 收到审查反馈，请处理。\n\n",
    }

    return prefix.get(phase, "") + prompts.get(role, prompts["developer"])


def report_all_agents(company_dir):
    """Generate a summary report for all agents (for status command)."""
    pp_dir = _paperclip_dir(company_dir)
    budget = load_budget(pp_dir)

    agents_summary = []
    agents_dir = pp_dir / "agents"
    if agents_dir.exists():
        for agent_file in sorted(agents_dir.glob("*.json")):
            agent = _load_json(agent_file)
            if agent:
                my_tasks = get_agent_tasks(pp_dir, agent_file.stem)
                agents_summary.append({
                    "agent_id": agent_file.stem,
                    "display_name": agent.get("display_name", ""),
                    "status": agent.get("status", "idle"),
                    "tasks_assigned": len(my_tasks),
                    "tasks_completed": agent.get("tasks_completed", 0),
                    "tokens_spent": agent.get("tokens_spent", 0),
                    "current_task": agent.get("current_task"),
                    "last_heartbeat": agent.get("last_heartbeat"),
                })

    # Count all tasks
    tasks_dir = pp_dir / "tasks"
    total_tasks = 0
    done_tasks = 0
    if tasks_dir.exists():
        for tf in tasks_dir.glob("*.json"):
            t = _load_json(tf)
            if t:
                total_tasks += 1
                if t.get("status") == "done":
                    done_tasks += 1

    return {
        "company": pp_dir.parent.name,
        "budget": budget,
        "agents": agents_summary,
        "tasks": {"total": total_tasks, "done": done_tasks},
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="PaperClip Heartbeat Worker")
    parser.add_argument("--agent-id", required=True, help="Agent ID or 'all'")
    parser.add_argument("--company-dir", required=True, help="Path to company directory")
    parser.add_argument("--report-only", action="store_true", help="Report without execution")

    args = parser.parse_args()

    if args.agent_id == "all":
        summary = report_all_agents(args.company_dir)
        print(json.dumps(summary, indent=2, ensure_ascii=False))
    elif args.report_only:
        pp_dir = _paperclip_dir(args.company_dir)
        agent = load_agent(pp_dir, args.agent_id)
        if agent:
            print(json.dumps(agent, indent=2, ensure_ascii=False))
        else:
            print(json.dumps({"error": f"Agent '{args.agent_id}' not found"}, ensure_ascii=False))
    else:
        result = heartbeat(args.agent_id, args.company_dir)
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
