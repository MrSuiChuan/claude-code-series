#!/usr/bin/env python3
"""
PaperClip Company Initializer
==============================
Interactive wizard to create a new PaperClip-managed company/project.

Usage:
    python init_company.py [--name NAME] [--output DIR]
    python init_company.py --interactive
"""

import os
import sys
import yaml
import json
import argparse
from datetime import datetime
from pathlib import Path

TEMPLATE_DIR = Path(__file__).parent.parent / "assets" / "company_template"


def create_company(name, output_dir, mission="", daily_budget=500000):
    """Create a new company configuration from template."""
    company_dir = Path(output_dir) / name
    company_dir.mkdir(parents=True, exist_ok=True)

    # Load and customize company.yaml
    with open(TEMPLATE_DIR / "company.yaml", "r", encoding="utf-8") as f:
        company_config = yaml.safe_load(f)

    company_config["company"]["name"] = name
    company_config["company"]["display_name"] = name
    company_config["company"]["mission"] = mission or f"使用 AI 代理管理 {name} 项目"
    company_config["company"]["created_at"] = datetime.now().strftime("%Y-%m-%d")
    company_config["budget"]["daily_limit"] = daily_budget

    with open(company_dir / "company.yaml", "w", encoding="utf-8") as f:
        yaml.dump(company_config, f, allow_unicode=True, default_flow_style=False)

    # Copy agents.yaml (can be customized later)
    with open(TEMPLATE_DIR / "agents.yaml", "r", encoding="utf-8") as f:
        agents_config = f.read()
    with open(company_dir / "agents.yaml", "w", encoding="utf-8") as f:
        f.write(agents_config)

    # Copy rules.yaml
    with open(TEMPLATE_DIR / "rules.yaml", "r", encoding="utf-8") as f:
        rules_config = f.read()
    with open(company_dir / "rules.yaml", "w", encoding="utf-8") as f:
        f.write(rules_config)

    # Create state directory for runtime data
    state_dir = company_dir / ".paperclip"
    state_dir.mkdir(exist_ok=True)

    # Create design directory (for Layer 4)
    design_dir = state_dir / "design"
    design_dir.mkdir(exist_ok=True)

    # Initialize state files
    state = {
        "company": name,
        "created_at": datetime.now().isoformat(),
        "agents": {},
        "tasks": {},
        "budget": {
            "total_allocated": daily_budget,
            "spent": 0,
            "daily_reset": datetime.now().strftime("%Y-%m-%d"),
        },
        "heartbeats": {},
        "audit_log": [],
    }
    with open(state_dir / "state.json", "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

    return company_dir


def fetch_design(company_dir, brand):
    """Fetch DESIGN.md for the given brand and place in company's .paperclip/design/."""
    # Import design_fetcher
    script_dir = Path(__file__).parent
    sys.path.insert(0, str(script_dir))
    from design_fetcher import fetch_brand, BRANDS

    if brand == "interactive":
        print("\n  Available design brands:")
        from design_fetcher import list_brands
        brands = list_brands()
        categories = {}
        for key, info in brands:
            cat = info["category"]
            if cat not in categories:
                categories[cat] = []
            categories[cat].append((key, info))

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


def print_summary(name, company_dir, daily_budget, design_brand=None):
    """Print company creation summary."""
    design_line = ""
    if design_brand:
        design_line = f"\n  Design:     {design_brand}"
    print(f"""
  PaperClip Company Created!
  ============================
  Name:       {name}
  Location:   {company_dir}
  Budget:     {daily_budget:,} tokens/day
  Agents:     5 roles (architect, developer, reviewer,
              operator, tester){design_line}
  ============================
  Next: /paperclip {name} --start
""")


def interactive_wizard():
    """Interactive setup wizard."""
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
                       help="Design brand from awesome-design-md (e.g. vercel, stripe). Use 'interactive' to browse.")
    parser.add_argument("--interactive", "-i", action="store_true", help="Interactive mode")

    args = parser.parse_args()

    if args.interactive:
        company_dir = interactive_wizard()
        if args.design:
            fetch_design(company_dir, args.design)
    elif args.name:
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
