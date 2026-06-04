# 🖇️ PaperClip Orchestrator

> 把 AI Agent 组织成一支"虚拟公司"——有组织架构、角色分工、任务队列、预算管控和心跳调度。
> 所有状态以 JSON 文件存储在 `.paperclip/` 下，**零数据库依赖**。

---

## 前置条件

### 第一步：添加插件市场

PaperClip 来自 **sui-chuan-tools** 第三方市场。首次使用需要注册市场：

编辑 Claude Code 配置文件（`.claude/settings.json` 或 `.claude/settings.local.json`）：

```json
{
  "extraKnownMarketplaces": {
    "sui-chuan-tools": {
      "source": {
        "source": "git",
        "url": "git@github.com:MrSuiChuan/claude-code-series.git"
      }
    }
  },
  "enabledPlugins": {
    "paperclip-orchestrator@sui-chuan-tools": true
  }
}
```

| 字段 | 说明 |
|------|------|
| `extraKnownMarketplaces` | 注册 `sui-chuan-tools` 市场，指向 GitHub 仓库 |
| `enabledPlugins` | 在该市场中启用 `paperclip-orchestrator` 插件 |

### 第二步：加载插件

在 Claude Code 会话中输入：

```
/paperclip-orchestrator:paperclip-orchestrator
```

Claude Code 会自动从市场拉取插件文件，缓存到本地。**不需要 pip install，不需要 npm install。**

### 架构总览

```
settings.json
  ├── extraKnownMarketplaces
  │     └── sui-chuan-tools → git@github.com:MrSuiChuan/claude-code-series.git
  │                              └── paperclip-orchestrator/  ← 插件本体
  └── enabledPlugins
        └── paperclip-orchestrator@sui-chuan-tools: true  ← 启用
```

### 🆕 v2.0 亮点：原生子代理 + 自动化钩子

PaperClip v2.0 从"YAML 配置 + 角色扮演"升级为**真正利用 Claude Code 插件系统能力**：

| 新特性 | 说明 | 效果 |
|--------|------|------|
| **6 个原生子代理** | `agents/*.md` — 每个角色有独立上下文窗口 | `/agents` 可发现，模型独立选择，权限隔离 |
| **3 个自动化钩子** | `hooks/hooks.json` — 审计、心跳、仪表盘自动化 | 不再手动写 audit log，不再手动更新心跳时间 |

```
v1.0:  agents.yaml → Claude 读配置 → 临时扮演角色 → 手动收尾
v2.0:  agents.yaml + agents/*.md → Claude 调用子代理 → hooks 自动收尾
v2.1:  agents/*.md paperclip: → 角色定义唯一来源，agents.yaml 不再生成
```

### 你可能不需要的

| 误区 | 真相 |
|------|------|
| ❌ `pip install pyyaml` 不是在安装插件 | PyYAML 只是一个 Python 库。插件通过市场下载，不需要 pip |
| ❌ 不需要数据库 | 所有状态用 JSON 文件存储 |
| ❌ 不需要启动服务 | v2.0 Agent 是原生子代理，有独立上下文，但仍是 Claude 在执行 |

### 两种使用模式，选一种即可

| 模式 | 在哪操作 | 额外依赖 | 适合 |
|------|---------|---------|------|
| **A: Python CLI** | 终端（会话外） | Python 3 + `pip install pyyaml` | 喜欢命令行，Python 可用 |
| **B: 自然语言** | Claude Code 对话（会话内） | 无 | Python 不可用，或更习惯对话 |

> **大多数情况下，模式 B 就够了。** 插件的核心是读写 JSON 文件，Python 脚本只是辅助。

---

## 目录

- [🆕 v2.0 原生子代理](#-v20-原生子代理)
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

> 前置条件：已按上面步骤注册 `sui-chuan-tools` 市场并启用插件。

### 初始化公司

**模式 A — 终端执行：**

```bash
pip install pyyaml                    # 仅一次，安装 Python YAML 库
python scripts/paperclip.py init my-project --budget 500000
```

**模式 B — 对 Claude 说：**

```
用 PaperClip 初始化 my-project，预算 500000
```

> `pip install pyyaml` 安装的是 Python 解析 YAML 的库，不是插件本身。只在用终端命令时需要。

初始化后得到：

```
my-project/
├── company.yaml       # 公司配置（可编辑）
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
| **Org Chart** (v2.1) | `agents/*.md` `paperclip:` frontmatter | 每个子代理自带角色定义 |
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

## 🆕 v2.0 原生子代理

PaperClip v2.0 提供了 6 个原生 Claude Code 子代理。输入 `/agents` 可查看全部。

### 子代理一览

| 子代理 | 模型 | 最大轮次 | 触发场景 |
|--------|------|---------|---------|
| `paperclip-architect` | opus | 30 | design 任务、架构设计、任务拆解 |
| `paperclip-developer` | sonnet | 25 | feature/bug/refactor/docs 任务 |
| `paperclip-reviewer` | sonnet | 20 | review/security 任务、in_review 状态 |
| `paperclip-tester` | sonnet | 20 | test 任务、编写测试用例 |
| `paperclip-operator` | sonnet | 15 | deploy 任务、监控运维 |
| `paperclip-design-fetcher` | haiku | 10 | 初始化时获取品牌 DESIGN.md |

### 子代理 vs agents.yaml（v2.1 已废弃）

```
agents/*.md paperclip:   → 角色定义的唯一来源（能力标签、预算、prompt）
.paperclip/agents/*.json → 运行时状态（status、current_task、heartbeat）
```

v2.1 将 `agents.yaml` 中的角色信息内聚到各 agent.md 的 `paperclip:` frontmatter。新公司不再生成 `agents.yaml`，老公司的文件仍可使用。

### 自动化钩子

v2.0 的 3 个钩子消除了手动簿记工作：

| 钩子 | 触发事件 | 自动操作 |
|------|---------|---------|
| 仪表盘 | `SessionStart` | 检测到 `.paperclip/` 时自动展示公司状态 |
| 审计 | `PostToolUse` | 任务状态变更时自动追加 audits.jsonl |
| 心跳 | `SubagentStop` | 子代理结束时自动更新 last_heartbeat |

---

## 完整实战：搭建一个全栈项目

以下是一次真实的 PaperClip 运行记录（v1.0 模式），展示完整的 **架构 → 开发 → 审查 → 修复 → 测试** 闭环。

> v2.0 中，每个"回合"由对应的原生子代理执行，hooks 自动处理审计和时间戳。

### 回合 1：初始化 + 架构

```
用户: init my-project --budget 500000
      → 创建 company.yaml + rules.yaml + .paperclip/

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

编辑 `agents/<role>.md` 的 `paperclip:` frontmatter 即可自定义：

```yaml
# agents/data-engineer.md
---
name: paperclip-data-engineer
description: PaperClip 数据工程师。ETL 开发、数据管道维护、SQL 优化。
model: sonnet
maxTurns: 20
paperclip:
  role: data_engineer
  display_name: 数据工程师
  level: execution
  reports_to: architect
  capabilities:
    - data_pipeline
    - sql_optimization
    - etl_development
  budget_share: 0.15
  max_autonomous_tokens: 50000
---

你是 PaperClip 公司的数据工程师...
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

### Q: v2.1 中角色定义在哪里？

A: 全部在 `agents/*.md` 的 `paperclip:` frontmatter 中。每个子代理自带角色定义（名称、能力标签、预算配比、级别），不再需要单独的 `agents.yaml`。老项目已有的 `agents.yaml` 仍然可用不作修改。

### Q: 如何查看和调用子代理？

A: 输入 `/agents` 查看全部 6 个 paperclip 子代理。Claude 会根据任务上下文自动调用，你也可以手动指定——比如"让 paperclip-reviewer 审查 task_007"。

### Q: hooks 会自动处理什么？

A: 三个钩子完全自动化了原本手动的簿记工作——`SessionStart` 自动展示仪表盘，`PostToolUse` 自动追加审计日志，`SubagentStop` 自动更新心跳时间戳。

### Q: 如何添加自定义角色？

A: 1) 在 `agents/` 下创建 `.md` 子代理文件，添加 `paperclip:` frontmatter；2) 在 `plugin.json` 的 `agents` 数组中注册；3) 创建对应的 `.paperclip/agents/<role>.json` 状态文件。

### Q: 如何迁移/备份？

A: 复制整个项目目录即可。所有状态都在 `.paperclip/` 的 JSON 文件中，零数据库依赖。

### Q: 插件从哪个市场下载？

A: PaperClip 来自 **sui-chuan-tools** 第三方市场，不是 Claude Code 官方内置市场。市场源指向 GitHub 仓库 `MrSuiChuan/claude-code-series`，需要在 `settings.json` 的 `extraKnownMarketplaces` 中注册后才能使用。

### Q: 为什么不放在官方市场 `claude-plugins-official` 里？

A: 官方市场 `claude-plugins-official` 是 Anthropic 维护的集中式插件目录。第三方市场允许开发者自行维护和更新插件，不需要通过 Anthropic 审核。PaperClip 选择独立市场的方式发布。

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
