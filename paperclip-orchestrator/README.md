# 🖇️ PaperClip Orchestrator

> 把 AI Agent 组织成一支"虚拟公司"——有组织架构、角色分工、任务队列、预算管控和心跳调度。
> 所有状态以 JSON 文件存储在 `.paperclip/` 下，**零数据库依赖**。

---

## 目录

- [5 分钟快速开始](#5-分钟快速开始)
- [核心概念](#核心概念)
- [两种使用模式](#两种使用模式)
- [完整实战：搭建一个全栈项目](#完整实战搭建一个全栈项目)
- [Agent 角色说明](#agent-角色说明)
- [任务生命周期](#任务生命周期)
- [心跳系统](#心跳系统)
- [预算与治理](#预算与治理)
- [文件结构参考](#文件结构参考)
- [常见问题](#常见问题)

---

## 5 分钟快速开始

### 第一步：初始化公司

```bash
# 方式 A：Python CLI（推荐）
pip install pyyaml
python scripts/paperclip.py init my-project --budget 500000

# 方式 B：手动模式（Python 不可用时）
# 直接让 Claude 帮你创建，说：
#   "用 PaperClip 初始化 my-project，预算 500000"
```

初始化后得到：

```
my-project/
├── company.yaml       # 公司配置（可编辑）
├── agents.yaml        # 5 个角色定义（可编辑）
├── rules.yaml         # 治理规则（可编辑）
└── .paperclip/        # 运行时状态（自动管理）
    ├── company.json
    ├── budget.json
    ├── audits.jsonl
    ├── agents/        # 每个 Agent 一个 JSON
    └── tasks/         # 每个任务一个 JSON
```

### 第二步：启动心跳

告诉 Claude：**"启动心跳"**。Claude 会为 5 个 Agent 注册 CronCreate 定时任务。

每个 Agent 每 15 分钟唤醒一次，检查是否有分配给自己的任务。

### 第三步：创建任务

告诉 Claude：**"创建任务 '搭建用户登录' --type feature"**

任务会自动分派给能力最匹配的 Agent。

### 第四步：让 Agent 工作

Agent 会在心跳时自动签出任务。你也可以手动触发：

> **"开始"** 或 **"继续"** — Claude 扮演当前有待办任务的 Agent 角色执行工作。

---

## 核心概念

| PaperClip 概念 | 实际机制 | 说明 |
|---------------|---------|------|
| **Company** | 一个目录 + YAML 配置 | 项目的组织容器 |
| **Org Chart** | `agents.yaml` 中的角色定义 | 5 个预设角色，可自定义 |
| **Agent** | Claude 扮演的 AI 角色 | 按角色 prompt 执行任务 |
| **Heartbeat** | CronCreate 定时任务 | 每 15 分钟自动唤醒 |
| **Task** | `.paperclip/tasks/*.json` | 自动分派 + 状态追踪 |
| **Budget** | `budget.json` | 每日 token 上限管控 |
| **Audit** | `audits.jsonl` | 不可变审计日志 |

### 5 个默认角色

```
┌────────────┐
│   Board    │  ← 你（人类决策者）
└─────┬──────┘
      │
┌─────▼──────┐
│ 🏗️ 架构师  │  设计架构、拆解任务、分派工作     (25% 预算)
└─────┬──────┘
      │
      ├──→ 💻 开发者   实现代码、修 Bug          (40% 预算)
      ├──→ 🔍 审查者   代码审查、安全检查          (20% 预算)
      ├──→ 🧪 测试者   编写测试、报告缺陷          (5% 预算)
      └──→ ⚙️ 运维者   部署、监控、自动化          (10% 预算)
```

---

## 两种使用模式

### 模式 A：Python CLI（自动模式）

如果你能运行 Python：

```bash
# 初始化
python scripts/paperclip.py init my-project --budget 500000

# 启动心跳
python scripts/paperclip.py start my-project

# 创建任务（自动分派）
python scripts/paperclip.py task my-project "实现登录功能" --type feature

# 查看状态
python scripts/paperclip.py status my-project

# 查看预算
python scripts/paperclip.py budget my-project

# 暂停/恢复
python scripts/paperclip.py pause my-project
python scripts/paperclip.py resume my-project
```

### 模式 B：手动模式（Python 不可用时）

当 Python 在 Claude Code 的 Bash 环境中无法执行时，直接通过自然语言操作：

| 你想做什么 | 对 Claude 说 |
|-----------|-------------|
| 初始化公司 | `用 PaperClip 初始化 <项目名> --budget 500000` |
| 启动心跳 | `启动心跳` |
| 创建任务 | `创建任务 "任务标题" --type feature` |
| 手动执行 | `开始` 或 `继续` |
| 查看状态 | `查看公司状态` |
| 暂停心跳 | `暂停心跳` |

Claude 会直接读写 `.paperclip/` 下的 JSON 文件来管理所有状态，完全不依赖 Python 脚本。

---

## 完整实战：搭建一个全栈项目

以下是一次真实的 PaperClip 运行记录，展示完整的 **架构 → 开发 → 审查 → 修复 → 测试** 闭环。

### 回合 1：初始化 + 架构

```
用户: init my-project --budget 500000
      → 创建 company.yaml + agents.yaml + rules.yaml + .paperclip/

用户: 启动心跳
      → 注册 5 个 CronCreate（每 15 分钟）

用户: 创建任务 "搭建项目基础架构" --type design
      → task_001 自动分派给 🏗️ 架构师 (匹配分数 10)

用户: 开始
      → 🏗️ 架构师签出 task_001，产出：
        • docs/ARCHITECTURE.md（技术选型 + 模块划分）
        • shared/types/index.ts（ApiResponse, User）
        • server/config + middleware/errorHandler
        • 拆解为 3 个子任务 → task_002, 003, 004
        → task_001 → in_review
```

### 回合 2：开发

```
用户: 开始
      → 💻 开发者一口气签出 3 个任务

      task_002: 搭建后端服务骨架
        • server/package.json, tsconfig.json
        • Express 入口 + auth/health 路由
        • JWT 认证服务 + Prisma 集成
        → in_review

      task_003: 搭建前端项目骨架
        • client/package.json, vite.config.ts
        • React Router + Layout + 4 个页面
        • axios API 层 + Zustand authStore
        → in_review

      task_004: 数据库 Schema
        • prisma/schema.prisma (User 表)
        • seed.ts + PrismaClient 单例
        → in_review
```

### 回合 3：审查 + 发现问题

```
用户: 是的
      → 🔍 审查者审查全部 4 个任务

      审查报告：
      ✅ task_001 架构设计 → approved
      🟡 task_002 后端     → approved (缺 helmet、body limit)
      🟡 task_003 前端     → approved (401 硬刷新、session 丢失)
      ✅ task_004 数据库   → approved

      → 创建修复子任务：
        task_005 🔴 修复安全问题 (高优先)
        task_006 🟡 修复前端状态 (常规)
```

### 回合 4：修复

```
用户: 继续
      → 💻 开发者修复：
        • helmet 安全头 + 1mb body limit + 密码强度校验 + 优雅退出
        • 401 改用 React Router navigate + localStorage 恢复 user
        → task_005, 006 → in_review
```

### 回合 5：再审查 + 测试

```
用户: 继续
      → 🔍 审查者确认全部修复正确 → task_005, 006 → done

用户: 测试
      → 🧪 测试者编写 16 个测试用例：
        • auth.service (5) — 密码校验/注册/登录
        • errorHandler (4) — AppError/生产模式
        • authStore (7) — login/logout/restoreSession/容错
        → task_007 → in_review
```

### 最终成果

```
7/7 任务全部 done ✅

my-project/
├── client/    15 文件   React+Vite+Router+Zustand+axios
├── server/    12 文件   Express+helmet+JWT+Prisma+优雅退出
├── prisma/    2 文件    Schema+Seed
├── shared/    1 文件    共享 TypeScript 类型
├── docs/      1 文件    系统架构文档
└── .paperclip/         完整审计追踪

Agent 绩效:
  💻 开发者  5 完成  🥇 最高产出
  🔍 审查者  6 审查  🥈 两轮审查
  🏗️ 架构师  1 完成  🥉 架构+拆解
  🧪 测试者  1 完成  16 测试用例
```

---

## Agent 角色说明

### 修改角色

编辑 `agents.yaml` 即可自定义：

```yaml
roles:
  # 添加新角色
  data_engineer:
    display_name: "数据工程师"
    level: "execution"
    reports_to: "architect"
    capabilities:
      - data_pipeline
      - sql_optimization
      - etl_development
    budget_share: 0.15
    max_autonomous_tokens: 50000
    agent_prompt: |
      你是数据工程师。职责：
      1. 设计和维护数据管道
      2. 优化 SQL 查询
      3. 开发 ETL 流程
```

### 能力标签

任务通过能力标签自动匹配 Agent：

| 任务类型 | 自动匹配 | 加分 |
|---------|---------|------|
| `design` | architect | +10 |
| `feature` | developer | +8 |
| `bug` | developer | +8 |
| `review` | reviewer | +10 |
| `test` | tester | +10 |
| `deploy` | operator | +10 |
| `security` | reviewer | +8 |
| `refactor` | developer | +8 |
| `docs` | developer / architect | +5 |

---

## 任务生命周期

```
todo → in_progress → in_review → done
  ↑                      │
  └──────────────────────┘ (审查不通过，打回)
```

每个任务文件 （`.paperclip/tasks/task_NNN.json`） 包含完整历史：

```json
{
  "task_id": "task_001",
  "title": "搭建项目基础架构",
  "type": "design",
  "priority": "high",
  "status": "done",
  "assignee": "architect",
  "history": [
    {"event": "created", "timestamp": "..."},
    {"event": "dispatched", "assignee": "architect", "score": 10},
    {"event": "status_change", "from": "todo", "to": "in_progress"},
    {"event": "completed", "summary": "..."},
    {"event": "reviewed", "verdict": "approved"}
  ]
}
```

---

## 心跳系统

### 如何工作

1. **CronCreate** 为每个 Agent 注册定时唤醒
2. 到达预定时间 → Claude 收到心跳 prompt
3. Claude 扮演该 Agent 角色：
   - 读取 `agents/<role>.json` 查看状态
   - 读取 `tasks/` 目录查找待办任务
   - 签出任务（status → in_progress）
   - 执行工作，写代码
   - 更新任务和 Agent 状态
   - 追加审计日志

### 调度策略

| Agent | 频率 | 说明 |
|-------|------|------|
| 全部 | 每 15 分钟 | 错开 4 分钟避免冲突 |
| 可按需调整 | `*/5 * * * *` | 高频 Agent |
| 可按需调整 | `7 * * * *` | 低频 Agent |

### 手动触发

心跳是自动的，但你随时可以手动触发：

```
"开始"      → 执行当前有待办任务的 Agent
"继续"      → 继续上一个未完成的流程
"测试"      → 触发测试者
```

### 暂停与恢复

```
"暂停心跳"   → 删除所有 CronCreate 任务
"恢复心跳"   → 重新注册
```

> ⚠️ 心跳任务 **7 天后自动过期**，届时需要重新启动。

---

## 预算与治理

### 预算管控

| 阈值 | 行为 |
|------|------|
| < 75% | 正常运行 |
| 75-90% | 警告通知 |
| 90-95% | 自动降频 |
| > 95% | 暂停所有 Agent |
| 100% | 硬停止 |

### 治理规则

编辑 `rules.yaml` 控制：

- **需要审批的操作**：超预算、生产部署、数据变更、外部 API 调用
- **自动批准的操作**：代码审查、测试执行
- **自主权限制**：Leadership 级 80k tokens/次，Execution 级 50k

---

## 文件结构参考

```
my-project/                        # ← 你的项目（一个"公司"）
│
├── company.yaml                   # 公司配置（可编辑）
│   ├── company.name               #   项目名
│   ├── budget.daily_limit         #   每日预算
│   ├── governance                 #   审批规则
│   └── milestones                 #   里程碑
│
├── agents.yaml                    # 角色定义（可编辑）
│   └── roles.<name>               #   每个角色的 prompt + 能力
│
├── rules.yaml                     # 治理规则（可编辑）
│   ├── budget_enforcement         #   预算执行
│   ├── approval_workflows         #   审批流
│   ├── quality_gates              #   质量门
│   └── autonomy_limits            #   自主权限制
│
├── .paperclip/                    # 运行时状态（自动管理，零数据库）
│   ├── company.json               #   公司信息 + heartbeat ID
│   ├── budget.json                #   预算追踪
│   ├── audits.jsonl               #   追加式审计日志
│   ├── agents/                    #   每个 Agent 一个 JSON
│   │   ├── architect.json         #     {status, current_task, ...}
│   │   ├── developer.json
│   │   ├── reviewer.json
│   │   ├── tester.json
│   │   └── operator.json
│   ├── tasks/                     #   每个任务一个 JSON
│   │   ├── task_001.json
│   │   ├── task_002.json
│   │   └── ...
│   └── design/                    #   DESIGN.md 缓存（可选）
│
├── client/                        # ← 你的实际项目代码
├── server/
├── docs/
└── ...
```

---

## 常见问题

### Q: Python 脚本跑不了怎么办？

A: 完全没关系。PaperClip 的核心是 **JSON 文件读写**，不是 Python。直接对 Claude 说操作指令即可，Claude 会直接操作文件。

### Q: Agent 真的是独立进程吗？

A: 不是。Agent 就是 **Claude 扮演的角色**。心跳触发后，Claude 读取该角色的 prompt，按照角色的职责行事。所有 Agent 共享同一个 Claude 上下文。

### Q: 多个 Agent 同时操作会冲突吗？

A: 不会。每个 Agent 只写自己的 `<role>.json` 文件，任务文件通过 `status` 字段实现乐观锁（先到先得）。

### Q: 心跳太频繁会不会烧 token？

A: Agent 唤醒后如果没有任务，只读一个 JSON 文件就退出（< 100 tokens）。有任务时才消耗预算。建议设置合理的 `daily_limit`。

### Q: 如何添加自定义角色？

A: 编辑 `agents.yaml`，在 `roles:` 下添加新角色，然后创建对应的 `.paperclip/agents/<role>.json` 状态文件。

### Q: 如何迁移/备份？

A: 复制整个项目目录即可。所有状态都在 `.paperclip/` 的 JSON 文件中，零数据库依赖。

### Q: Pro 模式是什么？

A: Pro 模式额外集成：
- **Matt Pocock 工程技能**：`/tdd`、`/code-review`、`/diagnose`、`/triage`
- **Taste 设计技能**：前端反 slop、设计风格
- **awesome-design-md**：58+ 品牌 DESIGN.md 规范

```bash
python scripts/paperclip.py setup my-project --pro --design vercel
```

---

## 相关文档

| 文档 | 内容 |
|------|------|
| [SKILL.md](SKILL.md) | Claude Code 技能定义 |
| [任务生命周期](references/task-lifecycle.md) | 状态机 + 分派规则 |
| [心跳系统](references/heartbeat-system.md) | Cron 模式 + 协议 |
| [多 Agent 工作流](references/workflow-patterns.md) | Pipeline / Parallel / Master-Worker 等 6 种模式 |
| [预算与治理](references/budget-governance.md) | 预算追踪 + 审批规则 |
| [Agent 角色库](references/agent-roles.md) | 角色定义 + 能力标签 |
| [公司结构](references/company-structure.md) | 配置文件 Schema |
| [技能矩阵](references/skill-matrix.md) | Pro 模式技能映射 |
