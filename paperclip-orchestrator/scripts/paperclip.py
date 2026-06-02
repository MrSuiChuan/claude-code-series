#!/usr/bin/env python3
"""
PaperClip Orchestrator — Unified CLI
=====================================
Single entry point for all /paperclip commands.

Usage:
    python paperclip.py init <name> [--budget N] [--design brand]
    python paperclip.py start <name>
    python paperclip.py status <name>
    python paperclip.py task <name> "<title>" [--type feature] [--priority normal]
    python paperclip.py budget <name>
    python paperclip.py heartbeat <name> --agent <id>
    python paperclip.py pause <name>
    python paperclip.py resume <name>
    python paperclip.py setup [name] [--pro]
"""

import sys
import json
import argparse
import os
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent


def cmd_init(args):
    """Create a new PaperClip company."""
    from init_company import create_company, print_summary, fetch_design
    company_dir = create_company(args.name, args.output or ".", args.mission or "", args.budget)
    print_summary(args.name, company_dir, args.budget, args.design)
    if args.design:
        fetch_design(company_dir, args.design)


def cmd_start(args):
    """Generate CronCreate prompts to start all agent heartbeats."""
    company_dir = Path(args.name)
    pp_dir = company_dir / ".paperclip"
    if not pp_dir.exists():
        print(f"[ERROR] Company '{args.name}' not found. Run 'paperclip init {args.name}' first.")
        return

    agents_dir = pp_dir / "agents"
    heartbeats = []
    for af in sorted(agents_dir.glob("*.json")):
        agent_id = af.stem
        heartbeats.append({
            "agent_id": agent_id,
            "cron": "*/15 * * * *",  # Every 15 min
            "prompt": (
                f"PaperClip heartbeat for {agent_id} in company {args.name}.\n"
                f"Run: python scripts/heartbeat_worker.py --agent-id {agent_id} --company-dir {args.name}\n"
                f"Read the output JSON, find action_prompt, and execute the task.\n"
                f"When done, update the task status via cost_reporter."
            ),
        })

    print(json.dumps({
        "action": "register_heartbeats",
        "company": args.name,
        "heartbeats": heartbeats,
        "instruction": "Use CronCreate for each heartbeat above.",
    }, indent=2, ensure_ascii=False))


def cmd_status(args):
    """Show company status dashboard."""
    from heartbeat_worker import report_all_agents
    result = report_all_agents(args.name)
    print(json.dumps(result, indent=2, ensure_ascii=False))


def cmd_task(args):
    """Create and auto-dispatch a new task."""
    from task_dispatcher import create_task
    if not args.title:
        print('{"error": "Task title required"}')
        return
    tags = [t.strip() for t in (args.tags or "").split(",") if t.strip()]
    task = create_task(args.name, args.title, args.description or "",
                      args.type or "feature", args.priority or "normal", tags)
    print(json.dumps(task, indent=2, ensure_ascii=False))


def cmd_budget(args):
    """Show budget report."""
    from cost_reporter import generate_report
    generate_report(args.name, args.format or "summary")


def cmd_heartbeat(args):
    """Run a single agent heartbeat."""
    from heartbeat_worker import heartbeat
    result = heartbeat(args.agent, args.name)
    print(json.dumps(result, indent=2, ensure_ascii=False))


def cmd_pause(args):
    """Output CronDelete instructions for all heartbeats."""
    company_dir = Path(args.name)
    pp_dir = company_dir / ".paperclip"
    company_json_path = pp_dir / "company.json"
    if not company_json_path.exists():
        print(f"[ERROR] Company '{args.name}' not found.")
        return

    company = json.loads(company_json_path.read_text(encoding="utf-8"))
    heartbeats = company.get("heartbeats", {})

    print(json.dumps({
        "action": "delete_heartbeats",
        "company": args.name,
        "heartbeats": heartbeats,
        "instruction": "Use CronDelete for each job_id above.",
    }, indent=2, ensure_ascii=False))


def cmd_resume(args):
    """Re-register heartbeats (same as start)."""
    cmd_start(args)


def cmd_setup(args):
    """One-command setup: install external skills and init company."""
    import subprocess

    name = args.name or "my-project"
    budget = args.budget

    print(f"\n  PaperClip Setup\n  {'=' * 40}")
    print(f"  Company: {name}")
    print(f"  Budget:  {budget:,} tokens/day\n")

    # Step 1: Init company
    print("[1/3] Initializing company...")
    sys.path.insert(0, str(SCRIPT_DIR))
    from init_company import create_company, print_summary, fetch_design
    company_dir = create_company(name, args.output or ".", "", budget)

    # Step 2: External skills (optional)
    if args.pro:
        print("[2/3] Installing external skills (Pro mode)...")
        for skill_url in [
            "mattpocock/skills",
            "https://github.com/Leonxlnx/taste-skill",
        ]:
            try:
                subprocess.run(
                    ["npx", "skills", "add", skill_url],
                    check=False, timeout=120,
                    capture_output=True,
                )
            except Exception:
                print(f"  [WARN] Could not install {skill_url}. Skipping.")

        # Activate pro agents
        pro_yaml = SCRIPT_DIR.parent / "assets" / "company_template" / "agents_pro.yaml"
        dest = company_dir / "agents.yaml"
        if pro_yaml.exists() and dest.exists():
            import shutil
            shutil.copy(pro_yaml, dest)
            print("  [OK] PRO agents activated")
    else:
        print("[2/3] Skipping external skills (use --pro for Pro mode)")

    print(f"[3/3] Done!\n")
    print_summary(name, company_dir, budget, args.design)

    if args.design:
        fetch_design(company_dir, args.design)


def main():
    parser = argparse.ArgumentParser(
        description="PaperClip Orchestrator CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python paperclip.py init my-project --budget 500000
  python paperclip.py status my-project
  python paperclip.py task my-project "Add user auth" --type feature
  python paperclip.py budget my-project
  python paperclip.py heartbeat my-project --agent developer
  python paperclip.py setup my-project --pro
        """
    )
    sub = parser.add_subparsers(dest="command", help="Command")

    # init
    p_init = sub.add_parser("init", help="Create a new company")
    p_init.add_argument("name", help="Company name")
    p_init.add_argument("--budget", "-b", type=int, default=500000)
    p_init.add_argument("--output", "-o", default=".")
    p_init.add_argument("--mission", "-m", default="")
    p_init.add_argument("--design", "-d", default=None)

    # start
    p_start = sub.add_parser("start", help="Start heartbeats")
    p_start.add_argument("name", help="Company name")

    # status
    p_status = sub.add_parser("status", help="Show status dashboard")
    p_status.add_argument("name", help="Company name")

    # task
    p_task = sub.add_parser("task", help="Create and dispatch a task")
    p_task.add_argument("name", help="Company name")
    p_task.add_argument("title", help="Task title")
    p_task.add_argument("--type", "-t", default="feature",
                       choices=["feature","bug","review","design","deploy","test","docs","security","refactor"])
    p_task.add_argument("--priority", "-p", default="normal",
                       choices=["high", "normal", "low"])
    p_task.add_argument("--description", "-d", default="")
    p_task.add_argument("--tags", default="")

    # budget
    p_budget = sub.add_parser("budget", help="Show budget report")
    p_budget.add_argument("name", help="Company name")
    p_budget.add_argument("--format", "-f", default="summary",
                         choices=["summary", "json", "text"])

    # heartbeat
    p_hb = sub.add_parser("heartbeat", help="Run agent heartbeat")
    p_hb.add_argument("name", help="Company name")
    p_hb.add_argument("--agent", "-a", required=True, help="Agent ID")

    # pause
    p_pause = sub.add_parser("pause", help="Pause all heartbeats")
    p_pause.add_argument("name", help="Company name")

    # resume
    p_resume = sub.add_parser("resume", help="Resume heartbeats")
    p_resume.add_argument("name", help="Company name")

    # setup
    p_setup = sub.add_parser("setup", help="One-command setup")
    p_setup.add_argument("name", nargs="?", default="my-project", help="Company name")
    p_setup.add_argument("--pro", action="store_true", help="Enable Pro mode")
    p_setup.add_argument("--budget", "-b", type=int, default=500000)
    p_setup.add_argument("--output", "-o", default=".")
    p_setup.add_argument("--design", "-d", default=None)

    args = parser.parse_args()

    commands = {
        "init": cmd_init,
        "start": cmd_start,
        "status": cmd_status,
        "task": cmd_task,
        "budget": cmd_budget,
        "heartbeat": cmd_heartbeat,
        "pause": cmd_pause,
        "resume": cmd_resume,
        "setup": cmd_setup,
    }

    if args.command in commands:
        commands[args.command](args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
