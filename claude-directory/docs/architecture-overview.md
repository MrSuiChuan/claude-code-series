# Architecture Overview

这份文档解释 `claude-directory` 的整体设计方式。

它不聚焦某一个 command、agent 或 skill，而是回答几个更基础的问题：

- 为什么这套目录要拆成这些层？
- 前端、后端和共享契约应该放在哪里？
- `CLAUDE.md`、rules、commands、skills、agents、hooks 分别负责什么？

如果把整个 `claude-directory` 看成一个项目级 Claude Code 系统，它的核心目标有两个：

1. 让高频任务有稳定入口
2. 让长期规则、共享契约和角色经验可以分层沉淀

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
- 前端应用层
- 后端应用层
- 共享契约层

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
  apps/
    web/
      CLAUDE.md
      src/
    api/
      CLAUDE.md
      src/
      prisma/
        CLAUDE.md
  packages/
    contracts/
      CLAUDE.md
  tests/
    e2e/
      CLAUDE.md
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

Application Boundaries
  -> apps/web
  -> packages/contracts
  -> apps/api
  -> tests/e2e
```

这四层的关系可以简单理解为：

- `apps/web` 负责页面、交互和前端状态
- `packages/contracts` 负责前后端共享的 schema、DTO 和类型
- `apps/api` 负责接口、业务逻辑、权限和数据访问
- `tests/e2e` 负责把关键用户链路按真实集成方式串起来验证

## 第一层：项目总约定层

### `CLAUDE.md`

这是整个 monorepo 的总说明。

它负责提供：

- 项目是什么
- 默认技术栈是什么
- 前端、后端、契约层怎么分
- 工作方式和编码原则是什么
- 测试和评审的大方向是什么

它解决的是“进入项目后，首先应该知道什么”。

## 第二层：专题规则层

### `.claude/rules/`

这层负责把项目级规范拆成专题。

例如：

- 前端 UI
- API 设计
- 表单和校验
- 数据库和 Prisma
- 共享契约
- 测试
- 安全
- 性能和缓存

这一层解决的是：

- 某类问题在这个项目里通常怎么做
- 哪些模式应该优先复用
- 哪些常见风险应该提前避免

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
- `workflows/ship-page`
- `workflows/fix-issue-orchestrator`
- `workflows/add-endpoint-orchestrator`

## 第四层：复用能力层

### `.claude/skills/`

这层负责沉淀“可复用做法”。

例如：

- `scaffold-page`
- `scaffold-api-route`
- `bug-triage`
- `security-review`
- `ui-review`
- `db-migration-review`

skill 的重点不是角色，而是方法：

- 页面怎么搭
- 接口怎么收边界
- bug 怎么收敛链路
- 数据库和安全怎么专项检查

## 第五层：角色评审层

### `.claude/agents/`

这层负责提供稳定视角。

例如：

- `frontend-reviewer`
- `backend-reviewer`
- `accessibility-reviewer`
- `e2e-reviewer`
- `code-reviewer`

这一层解决的是：

- 从哪个专业视角来判断问题
- 哪些风险要优先关注
- 哪类改动最可能出什么问题

## 第六层：长期经验层

### `.claude/agent-memory/`

这层负责积累角色经验。

它不应该替代规则，也不应该承担项目总约定。
它更像每个 reviewer 的项目工作笔记。

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

## 第八层：自动化辅助层

### `.claude/hooks/`

这层负责自动执行一些重复、机械、稳定的辅助动作。

例如：

- 编辑后自动格式化
- 特定文件变化后提醒检查
- 会话启动时做轻量辅助动作

## 第九层：前端应用层

### `apps/web/`

这是前端应用边界。

它负责：

- 页面和路由
- 组件和交互
- 浏览器状态编排
- 对后端 API 的调用

它不负责：

- 直接访问数据库
- 绕过契约层定义请求和响应结构
- 把后端业务逻辑硬塞进前端

## 第十层：后端应用层

### `apps/api/`

这是后端应用边界。

它负责：

- 请求边界
- auth 和授权
- 业务逻辑
- 第三方集成
- 数据库访问

它不应该：

- 在 handler 里堆满全部逻辑
- 与前端各自维护漂移的接口结构

## 第十一层：共享契约层

### `packages/contracts/`

这是前后端共享契约层。

它负责：

- Zod schema
- 共享 DTO
- 请求和响应结构
- 共享类型

它的目标是：

- 让前端和后端依赖同一套接口事实来源
- 降低“前端以为是 A，后端实现成 B”的漂移风险

## 一次任务是怎么流动的

一个典型任务通常沿这条链路流动：

```text
1. 用户通过 command 发起任务
2. command 读取项目总约定和相关 rules
3. command 决定调用 skill 或 agent
4. 如果涉及页面，优先落到 apps/web
5. 如果涉及接口，优先落到 apps/api
6. 如果涉及请求或响应结构，同时检查 packages/contracts
7. settings 和 hooks 决定运行边界与自动辅助行为
8. 如果任务反复暴露同类问题，经验再沉淀到 agent-memory
```

## 推荐演进顺序

如果你是第一次搭项目级 `.claude` 目录，推荐按这个顺序演进：

1. 先写好根 `CLAUDE.md`
2. 再明确 `apps/web`、`apps/api`、`packages/contracts` 的边界
3. 再拆出 4 到 6 个核心 `rules`
4. 再补 2 到 4 个高频 `commands`
5. 再把重复任务下沉成 `skills`
6. 再为关键评审视角建立 `agents`
7. 最后再逐步补 `agent-memory`、`hooks` 和更完整的运行配置

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

Application Boundaries
  -> apps/web
  -> packages/contracts
  -> apps/api
  -> tests/e2e
```

当这些层分工清楚时，`claude-directory` 就不只是一个目录样例，而是一套真正可维护、可扩展、可协作的前后端分离单仓模板。
