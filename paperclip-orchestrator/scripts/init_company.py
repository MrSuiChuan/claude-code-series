#!/usr/bin/env python3
"""
PaperClip Company Initializer
==============================
Creates a new PaperClip-managed company with file-based runtime state.

Usage:
    python init_company.py --name my-project [--budget 500000] [--design vercel]
    python init_company.py --interactive
"""

import os
import sys
import json
import argparse
from datetime import datetime
from pathlib import Path

CURRENT_SCHEMA_VERSION = 1

TEMPLATE_DIR = Path(__file__).parent.parent / "assets" / "company_template"


def ensure_yaml():
    """Check that PyYAML is available, give friendly error if not."""
    try:
        import yaml  # noqa: F401
    except ImportError:
        print(
            "[ERROR] PyYAML is required. Install it with:\n"
            "        pip install pyyaml\n"
            "        or: pip install -r requirements.txt"
        )
        sys.exit(1)


def create_company(name, output_dir, mission="", daily_budget=500000):
    """Create a new company configuration and runtime state directory."""
    ensure_yaml()
    import yaml

    company_dir = Path(output_dir) / name
    paperclip_dir = company_dir / ".paperclip"

    # ---- Config files (user-editable) ----
    company_dir.mkdir(parents=True, exist_ok=True)

    with open(TEMPLATE_DIR / "company.yaml", "r", encoding="utf-8") as f:
        company_config = yaml.safe_load(f)

    company_config["company"]["name"] = name
    company_config["company"]["display_name"] = name
    company_config["company"]["mission"] = mission or f"使用 AI 代理管理 {name} 项目"
    company_config["company"]["created_at"] = datetime.now().strftime("%Y-%m-%d")
    company_config["budget"]["daily_limit"] = daily_budget

    with open(company_dir / "company.yaml", "w", encoding="utf-8") as f:
        yaml.dump(company_config, f, allow_unicode=True, default_flow_style=False)

    for filename in ["agents.yaml", "rules.yaml"]:
        with open(TEMPLATE_DIR / filename, "r", encoding="utf-8") as f:
            content = f.read()
        with open(company_dir / filename, "w", encoding="utf-8") as f:
            f.write(content)

    # ---- Runtime state directory (.paperclip/) ----
    paperclip_dir.mkdir(exist_ok=True)
    for sub in ["agents", "tasks", "design"]:
        (paperclip_dir / sub).mkdir(exist_ok=True)

    # company.json — company-level runtime info + schema version
    company_json = {
        "schema_version": CURRENT_SCHEMA_VERSION,
        "company": name,
        "created_at": datetime.now().isoformat(),
        "heartbeats": {},
    }
    with open(paperclip_dir / "company.json", "w", encoding="utf-8") as f:
        json.dump(company_json, f, indent=2, ensure_ascii=False)

    # budget.json — budget tracking (only cost_reporter writes this)
    budget_json = {
        "total_allocated": daily_budget,
        "spent": 0,
        "daily_reset": datetime.now().strftime("%Y-%m-%d"),
        "alert_threshold": company_config["budget"].get("alert_threshold", 0.8),
        "per_task_limit": company_config["budget"].get("per_task_limit", 100000),
    }
    with open(paperclip_dir / "budget.json", "w", encoding="utf-8") as f:
        json.dump(budget_json, f, indent=2, ensure_ascii=False)

    # agents/*.json — one file per role, agent writes only its own
    agents_config = yaml.safe_load(
        (TEMPLATE_DIR / "agents.yaml").read_text(encoding="utf-8")
    )
    for role_id, role_def in agents_config["roles"].items():
        agent_state = {
            "role": role_id,
            "display_name": role_def.get("display_name", role_id),
            "status": "idle",
            "tokens_spent": 0,
            "tasks_completed": 0,
            "current_task": None,
            "budget_share": role_def.get("budget_share", 0.2),
            "max_autonomous_tokens": role_def.get("max_autonomous_tokens", 50000),
            "last_heartbeat": None,
        }
        with open(paperclip_dir / "agents" / f"{role_id}.json", "w", encoding="utf-8") as f:
            json.dump(agent_state, f, indent=2, ensure_ascii=False)

    # audits.jsonl — empty, append-only
    (paperclip_dir / "audits.jsonl").touch()

    return company_dir


def _audit(paperclip_dir, event, detail=""):
    """Append an event to the audit log (jsonl)."""
    entry = {
        "timestamp": datetime.now().isoformat(),
        "event": event,
        "detail": detail,
    }
    audit_file = Path(paperclip_dir) / "audits.jsonl"
    with open(audit_file, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def print_summary(name, company_dir, daily_budget, design_brand=None):
    design_line = f"\n  Design:     {design_brand}" if design_brand else ""
    print(f"""
  PaperClip Company Created!
  ============================
  Name:       {name}
  Location:   {company_dir}
  Budget:     {daily_budget:,} tokens/day
  Agents:     5 roles (architect, developer, reviewer,
              operator, tester){design_line}
  State:      .paperclip/ (JSON files, no database)
  ============================
  Next: paperclip start {name}
""")


def fetch_design(company_dir, brand):
    script_dir = Path(__file__).parent
    sys.path.insert(0, str(script_dir))
    from design_fetcher import fetch_brand, BRANDS

    if brand == "interactive":
        from design_fetcher import list_brands
        brands = list_brands()
        categories = {}
        for key, info in brands:
            cat = info["category"]
            categories.setdefault(cat, []).append((key, info))

        print("\n  Available design brands:")
        for cat, cat_brands in categories.items():
            print(f"\n  [{cat}]")
            for key, info in cat_brands:
                print(f"    {key:<18s} | {info['vibe']}")

        choice = input("\n  Enter brand key (or press Enter to skip): ").strip()
        if not choice:
            print("  [SKIP] No design brand selected.")
            return None
        brand = choice

    if brand and brand in BRANDS:
        result = fetch_brand(brand, str(company_dir))
        if result:
            print(f"  [OK] DESIGN.md fetched: {brand} ({BRANDS[brand]['name']})")
            print(f"       Vibe: {BRANDS[brand]['vibe']}")
            return result
    elif brand:
        print(f"  [WARN] Unknown brand: {brand}. Use 'list' to see available brands.")


def interactive_wizard():
    print("\n  PaperClip Company Setup Wizard\n  " + "=" * 34)
    name = input("  Company name (kebab-case): ").strip()
    if not name:
        print("  [ERROR] Company name is required.")
        sys.exit(1)

    mission = input("  Mission (optional): ").strip()
    budget_str = input("  Daily token budget [500000]: ").strip()
    daily_budget = int(budget_str) if budget_str else 500000

    output_str = input("  Output directory [.]: ").strip()
    output_dir = output_str if output_str else "."

    return create_company(name, output_dir, mission, daily_budget)


def main():
    parser = argparse.ArgumentParser(
        description="PaperClip Company Initializer",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python init_company.py --name my-project
  python init_company.py --name my-app --output ./companies --budget 1000000
  python init_company.py --interactive
        """
    )
    parser.add_argument("--name", "-n", help="Company name (kebab-case)")
    parser.add_argument("--output", "-o", default=".", help="Output directory")
    parser.add_argument("--mission", "-m", default="", help="Company mission statement")
    parser.add_argument("--budget", "-b", type=int, default=500000, help="Daily token budget")
    parser.add_argument("--design", "-d", default=None,
                       help="Design brand from awesome-design-md. Use 'interactive' to browse.")

    args = parser.parse_args()

    if args.name:
        company_dir = create_company(args.name, args.output, args.mission, args.budget)
        print_summary(args.name, company_dir, args.budget, args.design)
        if args.design:
            fetch_design(company_dir, args.design)
    else:
        company_dir = interactive_wizard()
        if args.design:
            fetch_design(company_dir, args.design)


if __name__ == "__main__":
    main()
