# Architecture Overview

这份文档解释 `claude-directory` 的整体设计方式。

它不聚焦某一个 command、agent 或 skill，而是回答一个更基础的问题：

- 为什么这套目录要拆成这些层？
- 这些层之间怎么协作？
- 信息应该沉淀在哪一层，而不是哪一层？

如果把整个 `claude-directory` 看成一个项目级 Claude Code 系统，它的核心目标有两个：

1. 让高频任务有稳定入口
2. 让长期规则和长期经验可以分层沉淀

## 总体思路

这套结构不是把所有指令塞进一个文件，而是按职责拆成几层：

- 项目总约定层
- 专题规则层
- 用户入口层
- 复用能力层
- 角色评审层
- 长期经验层
- 运行配置层
- 自动化辅助层

这些层一起工作时，Claude Code 在项目里就更像一个“可维护系统”，而不是一组散乱 prompt。

## 目录结构视图

```text
project-root/
  CLAUDE.md
  .mcp.json
  .worktreeinclude
  .claude/
    settings.json
    settings.local.json
    rules/
    commands/
    skills/
    agents/
    agent-memory/
    hooks/
    output-styles/
```

可以把它压缩理解成下面这张图：

```text
User Request
  -> commands
  -> skills
  -> agents
  -> output

Long-lived Guidance
  -> CLAUDE.md
  -> rules
  -> agent-memory

Runtime Behavior
  -> settings.json
  -> hooks
  -> mcp
  -> worktreeinclude
```

## 第一层：项目总约定层

### `CLAUDE.md`

这是整个项目的总说明。

它负责提供：

- 项目是什么
- 默认技术栈是什么
- 架构边界大概怎么分
- 工作方式和编码原则是什么
- 测试和评审的大方向是什么

它解决的是“进入项目后，首先应该知道什么”。

这一层应该尽量稳定、简洁、长期有效。

## 第二层：专题规则层

### `.claude/rules/`

这层负责把项目级规范拆成专题。

例如：

- 前端 UI
- API 设计
- 表单和校验
- 数据库和 Prisma
- 测试
- 安全
- 性能和缓存

这一层解决的是：

- 某类问题在这个项目里通常怎么做
- 哪些模式应该优先复用
- 哪些常见风险应该提前避免

如果 `CLAUDE.md` 是项目总章程，那 `rules/` 就像专题规范手册。

## 第三层：用户入口层

### `.claude/commands/`

这层负责“用户怎么发起任务”。

一个好的 command，不是简单重复规则，而是：

- 理解任务目标
- 组织执行顺序
- 决定是否调用 skill 或 agent
- 要求稳定输出结构

典型命令包括：

- `review-ui`
- `fix-issue`
- `trace-request`
- `add-endpoint`

如果进一步做工程化，还可以在这层引入 workflow 型 command：

- `workflows/ship-page`
- `workflows/fix-issue-orchestrator`
- `workflows/add-endpoint-orchestrator`

这一层解决的是“任务从哪里开始”。

## 第四层：复用能力层

### `.claude/skills/`

这层负责沉淀“可复用做法”。

skill 的重点不是角色，而是方法。

例如：

- `scaffold-page`
- `scaffold-api-route`
- `bug-triage`
- `security-review`
- `ui-review`
- `db-migration-review`

这一层解决的是：

- 某类事一般按什么步骤处理
- 哪些检查清单值得复用
- 哪些任务套路不必每次重新组织

如果 command 是任务入口，skill 就是任务工具箱。

## 第五层：角色评审层

### `.claude/agents/`

这层负责提供稳定视角。

它的价值不在于“更强”，而在于“更专”。

例如：

- `frontend-reviewer`
- `backend-reviewer`
- `accessibility-reviewer`
- `e2e-reviewer`
- `code-reviewer`

这一层解决的是：

- 从哪个专业视角来判断问题
- 哪些风险要优先关注
- 某类改动在这个项目里最可能出什么问题

如果 skill 关注的是“怎么做”，agent 更关注“怎么看”。

## 第六层：长期经验层

### `.claude/agent-memory/`

这层负责积累角色经验。

它不应该替代规则，也不应该承担项目总约定。
它更像每个 agent 的项目工作笔记。

适合沉淀的内容包括：

- 某类问题在项目里经常怎么出现
- 某些链路最容易断在哪里
- 某个 reviewer 反复观察到的高频风险

这一层解决的是：

- 哪些经验会随着任务推进不断出现
- 哪些信号值得被角色长期记住

## 第七层：运行配置层

### `.claude/settings.json`
### `.claude/settings.local.json`
### `.mcp.json`
### `.worktreeinclude`

这层负责让 Claude Code 在项目里“如何运行”变得稳定可控。

包括：

- 哪些命令允许直接执行
- 哪些命令要先确认
- hooks 怎么触发
- MCP 怎么接入
- worktree 如何配合本地环境

这一层解决的是：

- Claude 的运行边界
- 项目自动化的默认行为
- 团队共享配置与个人本地配置的分层

可以把它理解成“运行时基础设施”。

## 第八层：自动化辅助层

### `.claude/hooks/`

这层负责自动执行一些重复、机械、稳定的辅助动作。

例如：

- 编辑后自动格式化
- 特定文件变化后提醒检查
- 会话启动时做轻量辅助动作

它的目标不是替代主任务，而是减少低价值摩擦。

这一层解决的是：

- 哪些动作几乎每次都该做
- 哪些动作可以安全自动化
- 哪些动作不值得反复手工执行

## 一次任务是怎么流动的

可以把一次典型任务理解成下面的信息流：

```text
1. 用户通过 command 发起任务
2. command 读取项目总约定和相关 rules
3. command 选择调用 skill 或 agent
4. skill 提供可复用执行套路
5. agent 提供稳定专业视角
6. settings 和 hooks 决定运行边界与自动辅助行为
7. 如果任务反复暴露同类问题，经验再沉淀到 agent-memory
```

如果压缩成一句话：

- `CLAUDE.md` 和 `rules` 决定“这个项目通常怎么做”
- `commands` 决定“这次任务从哪里开始”
- `skills` 决定“这类事一般怎么做”
- `agents` 决定“从谁的视角来看”
- `agent-memory` 决定“这个角色在项目里学到了什么”
- `settings` 和 `hooks` 决定“系统怎么运行得更稳”

## 为什么要分这么多层

因为不同信息的生命周期不一样。

有些信息：

- 很稳定
- 面向整个项目
- 适合长期保留

有些信息：

- 只对某类任务有效
- 需要被反复复用
- 适合沉淀为 skill

有些信息：

- 更像角色经验
- 会随着时间逐步积累
- 不适合直接写成硬规则

如果不分层，最后常见结果是：

- `CLAUDE.md` 越写越长
- rules、commands、skills 内容重叠
- agent 变成万能角色
- memory 和 rules 混在一起
- 团队越来越难维护 `.claude` 目录

## 推荐演进顺序

如果你是第一次搭项目级 `.claude` 目录，推荐按这个顺序演进：

1. 先写好 `CLAUDE.md`
2. 再拆出 3 到 5 个核心 `rules`
3. 再补 2 到 4 个高频 `commands`
4. 再把重复任务下沉成 `skills`
5. 再为关键评审视角建立 `agents`
6. 最后再逐步补 `agent-memory`、`hooks` 和更完整的运行配置

这会比一开始追求“大而全”更稳。

## 适合这套架构的项目

这套结构特别适合：

- 有明确技术栈和目录边界的项目
- 需要多人协作的仓库
- 有重复开发和评审流程的团队
- 希望把 Claude Code 用成长期工程工具的项目

如果只是一次性实验、个人短期脚本仓库，完全没必要一开始就把所有层都搭满。

## 总结

这套架构的核心不是“文件越多越好”，而是让不同类型的信息各归其位。

可以把它压缩成一张职责图：

```text
Project Truth
  -> CLAUDE.md
  -> rules/

Task Entry
  -> commands/

Reusable Methods
  -> skills/

Expert View
  -> agents/

Accumulated Experience
  -> agent-memory/

Runtime Control
  -> settings.json
  -> hooks/
  -> mcp
  -> worktree
```

当这些层分工清楚时，`claude-directory` 就不只是一个目录样例，而是一套真正可维护、可扩展、可协作的项目级 Claude Code 结构。
