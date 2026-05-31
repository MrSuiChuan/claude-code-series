# Skill-Role Matrix (Pro Edition — 3-Layer)

## Overview

This matrix maps all skills across three layers to PaperClip agent roles.

## Complete Matrix (21 Engineering + 8 Design Skills)

### Engineering Skills (Matt Pocock)

| Skill | Architect | Developer | Reviewer | Tester | Operator | Priority |
|-------|:---------:|:---------:|:--------:|:------:|:--------:|----------|
| `/grill-me` | **P** | - | S | - | - | 需求澄清 |
| `/grill-with-docs` | S | - | - | - | - | 领域对齐 |
| `/to-prd` | **P** | - | - | - | - | 设计输出 |
| `/to-issues` | **P** | - | - | - | - | 任务拆解 |
| `/zoom-out` | S | - | S | - | - | 高层理解 |
| `/write-a-skill` | S | - | - | - | - | 知识沉淀 |
| `/improve-codebase-architecture` | S | - | S | - | - | 架构优化 |
| `/tdd` | - | **P** | - | **P** | - | 质量保证 |
| `/diagnose` | - | **P** | S | S | **P** | 问题定位 |
| `/prototype` | - | S | - | - | - | 方案验证 |
| `/caveman` | - | S | - | - | - | 效率优化 |
| `/handoff` | - | S | - | - | S | 知识传递 |
| `/triage` | - | - | **P** | S | S | 优先级排序 |
| `/code-review` | - | - | **P** | - | - | 质量门禁 |

### Design Skills (Taste-Skill)

| Skill | Architect | Developer | Reviewer | Tester | Operator | Priority |
|-------|:---------:|:---------:|:--------:|:------:|:--------:|----------|
| `taste-skill` | - | **P** | **P** | - | - | 反模板化前端 |
| `output-skill` | - | **P** | S | - | - | 完整代码输出 |
| `image-to-code-skill` | - | S | - | - | - | 图片→代码 |
| `soft-skill` | - | S | - | - | - | 柔和高端 UI |
| `minimalist-skill` | - | S | - | - | - | 编辑风格 UI |
| `redesign-skill` | S | S | - | - | - | 重设计审查 |
| `imagegen-frontend-web` | S | - | - | - | - | Web 视觉稿 |
| `brandkit` | S | - | - | - | - | 品牌识别板 |

**Legend**: **P** = Primary (强制), S = Secondary (按需), - = Not assigned

## Task Type → Skill Selection

| Task Type | Role | Layer 2 (Engineering) | Layer 3 (Design) |
|-----------|------|----------------------|-----------------|
| `feature` | Developer | `/tdd` | - |
| `frontend` | Developer | `/tdd` | `taste-skill` → `output-skill` |
| `bug` | Developer | `/diagnose` | - |
| `ui-bug` | Developer | `/diagnose` | `taste-skill` (visual fix) |
| `review` | Reviewer | `/triage` → `/code-review` | - |
| `frontend-review` | Reviewer | `/code-review` | `taste-skill` (design check) |
| `design` | Architect | `/grill-me` → `/to-prd` | `imagegen-frontend-web` |
| `deploy` | Operator | `/diagnose` | - |
| `test` | Tester | `/tdd` | - |
| `brand` | Architect | `/to-prd` | `brandkit` |

### Design System Skills (Layer 4 — awesome-design-md)

| Skill | Architect | Developer | Reviewer | Tester | Operator | Priority |
|-------|:---------:|:---------:|:--------:|:------:|:--------:|----------|
| `design_fetcher (select)` | **P** | - | - | - | - | 品牌选择 |
| `DESIGN.md (read/audit)` | **P** | **P** | **P** | - | - | 规范读取 |
| `DESIGN.md (implement)` | - | **P** | - | - | - | 品牌实现 |
| `DESIGN.md (verify)` | - | - | **P** | - | - | 品牌审查 |

## Taste Dials Configuration

For frontend tasks, the developer sets these dials:

```yaml
# Default (recommended)
DESIGN_VARIANCE: 7    # Creative but not chaotic
MOTION_INTENSITY: 6   # Engaging but not distracting
VISUAL_DENSITY: 5     # Balanced information density

# Per-style overrides
soft-skill:        { DESIGN_VARIANCE: 4, MOTION_INTENSITY: 7, VISUAL_DENSITY: 3 }
minimalist-skill:  { DESIGN_VARIANCE: 3, MOTION_INTENSITY: 2, VISUAL_DENSITY: 2 }
```
