#!/bin/bash
# ============================================================
# PaperClip Pro Setup
# ============================================================
# One-click setup: installs Matt Pocock skills + PaperClip
# orchestrator, then initializes a company with pro agents.
#
# Usage:
#   bash setup_pro.sh <company-name> [budget]
#   bash setup_pro.sh my-project 500000
# ============================================================

set -e

COMPANY_NAME="${1:-my-project}"
BUDGET="${2:-500000}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "========================================="
echo "  PaperClip Pro Setup"
echo "========================================="
echo "  Company: $COMPANY_NAME"
echo "  Budget:  $BUDGET tokens/day"
echo "========================================="
echo ""

# Step 1: Install Matt Pocock skills
echo "[1/3] Installing Matt Pocock skills..."
if command -v npx &> /dev/null; then
    npx skills@latest add mattpocock/skills 2>&1 || echo "  [WARN] npx skills failed - you may need Node.js. Skipping."
else
    echo "  [WARN] npx not found. Install Node.js first, then run:"
    echo "         npx skills@latest add mattpocock/skills"
fi

# Step 2: Initialize company with PRO config
echo "[2/3] Initializing company with PRO agent config..."
python3 "$SKILL_DIR/scripts/init_company.py" \
    --name "$COMPANY_NAME" \
    --budget "$BUDGET" \
    --output "." 2>&1

# Step 3: Replace default agents.yaml with pro version
echo "[3/3] Activating PRO agent roles..."
COMPANY_DIR="./${COMPANY_NAME}"
if [ -d "$COMPANY_DIR" ]; then
    cp "$SKILL_DIR/assets/company_template/agents_pro.yaml" \
       "$COMPANY_DIR/agents.yaml"
    echo "  [OK] PRO agents activated for $COMPANY_NAME"
else
    echo "  [WARN] Company directory not found at $COMPANY_DIR"
fi

echo ""
echo "========================================="
echo "  PaperClip Pro Setup Complete!"
echo "========================================="
echo ""
echo "  Next steps:"
echo "    /paperclip start $COMPANY_NAME --pro"
echo ""
echo "  Available skills per role:"
echo "    Architect: /grill-me, /to-prd, /to-issues"
echo "    Developer: /tdd, /diagnose, /prototype"
echo "    Reviewer:  /triage, /code-review, /diagnose"
echo "    Tester:    /tdd, /diagnose"
echo "    Operator:  /diagnose, /triage, /handoff"
echo ""
echo "========================================="
