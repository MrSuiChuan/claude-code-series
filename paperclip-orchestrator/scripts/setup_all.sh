#!/bin/bash
# ============================================================
# PaperClip Pro — Full Setup (All Skills)
# ============================================================
# Installs all three skill layers:
#   Layer 1: PaperClip Orchestrator (编排)
#   Layer 2: Matt Pocock Skills (工程质量)
#   Layer 3: Taste-Skill (设计品味)
#
# Usage:
#   bash setup_all.sh <company-name> [budget]
# ============================================================

set -e

COMPANY_NAME="${1:-my-project}"
BUDGET="${2:-500000}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "========================================="
echo "  PaperClip Pro — Full Setup"
echo "========================================="
echo "  Company: $COMPANY_NAME"
echo "  Budget:  $BUDGET tokens/day"
echo "========================================="
echo ""

# Layer 1: PaperClip Core
echo "[1/4] Initializing PaperClip company..."
python3 "$SKILL_DIR/scripts/init_company.py" \
    --name "$COMPANY_NAME" \
    --budget "$BUDGET" \
    --output "." 2>&1

# Layer 2: Matt Pocock Skills
echo "[2/4] Installing Matt Pocock engineering skills..."
if command -v npx &> /dev/null; then
    npx skills@latest add mattpocock/skills 2>&1 || \
        echo "  [WARN] npx skills failed. Install Node.js and retry."
else
    echo "  [WARN] npx not found. Run: npx skills@latest add mattpocock/skills"
fi

# Layer 3: Taste-Skill
echo "[3/5] Installing Taste-Skill (anti-slop frontend)..."
if command -v npx &> /dev/null; then
    npx skills add https://github.com/Leonxlnx/taste-skill 2>&1 || \
        echo "  [WARN] npx skills failed. Install Node.js and retry."
else
    echo "  [WARN] npx not found. Run: npx skills add https://github.com/Leonxlnx/taste-skill"
fi

# Layer 4: DESIGN.md (Design System)
echo "[4/5] Setting up design system (Layer 4)..."
COMPANY_DIR="./${COMPANY_NAME}"
echo "  Available brands from awesome-design-md:"
python3 "$SKILL_DIR/scripts/design_fetcher.py" list 2>&1 | head -20 || \
    echo "  [INFO] Run: python scripts/design_fetcher.py list"
echo ""
echo "  To fetch a brand: python scripts/design_fetcher.py fetch <brand> --output $COMPANY_DIR"

# Activate PRO agents (4-layer integration)
echo "[5/5] Activating PRO agent roles (4-layer)..."
if [ -d "$COMPANY_DIR" ]; then
    cp "$SKILL_DIR/assets/company_template/agents_pro.yaml" \
       "$COMPANY_DIR/agents.yaml"
    echo "  [OK] PRO agents activated for $COMPANY_NAME"
else
    echo "  [WARN] Company directory not found at $COMPANY_DIR"
fi

echo ""
echo "========================================="
echo "  PaperClip Pro — Setup Complete!"
echo "========================================="
echo ""
echo "  4-Layer Agent Architecture:"
echo ""
echo "  Layer 1 (编排):      PaperClip Orchestrator"
echo "  Layer 2 (工程质量):   Matt Pocock Skills"
echo "  Layer 3 (设计品味):   Taste-Skill"
echo "  Layer 4 (设计规范):   awesome-design-md"
echo ""
echo "  Next steps:"
echo "    python scripts/design_fetcher.py search 'dark saas'"
echo "    python scripts/design_fetcher.py fetch vercel --output $COMPANY_DIR"
echo "    /paperclip start $COMPANY_NAME --pro"
echo "========================================="
