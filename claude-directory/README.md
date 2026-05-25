# claude-directory

一套面向前后端分离网页系统 monorepo 的 Claude Code 工程化目录模板。

它的目标不是只给你几个 prompt，而是给你一套可维护的项目级结构，让 `CLAUDE.md`、`rules`、`commands`、`skills`、`agents`、`hooks`、`settings` 可以各司其职，长期演进。

它强调的是目录结构、职责边界和工作流分层，不强绑定某一套默认技术栈。

仓库里的 rules、commands 和 skills 会围绕前端、后端、共享契约、数据访问和测试这些常见工程问题来组织，你可以直接替换成自己的框架、语言、校验机制和测试工具。

## 这个目录解决什么问题

很多团队在使用 Claude Code 时，容易遇到这些问题：

- 所有规则都堆进一个很长的 `CLAUDE.md`
- command、agent、skill 职责重叠
- 项目里没有稳定的高频工作流入口
- hooks 和 settings 只有零散技巧，没有成体系的组织
- 新同事拿到 `.claude` 目录后，不知道每一层该怎么改

`claude-directory` 想解决的就是这些工程化问题。

它提供的不是“万能提示词”，而是一套项目模板：

- `CLAUDE.md` 放项目级总约定
- `.claude/rules/` 放专题规则
- `.claude/commands/` 放高频任务入口
- `.claude/skills/` 放可复用任务模板
- `.claude/agents/` 放角色化评审能力
- `.claude/agent-memory/` 放角色长期经验
- `.claude/hooks/` 放自动化辅助动作
- `.claude/settings.json` 放团队共享运行配置

## 快速开始

### 1. 复制模板

把 [`project-root/`](./project-root) 下的内容复制到你的项目根目录，再按你的实际技术栈做裁剪。

### 2. 先改这几个文件

优先调整：

- `CLAUDE.md`
- `.claude/settings.json`
- `.mcp.json`
- `.worktreeinclude`

如果你的项目边界、工具链或目录命名和这里不同，就同步删改相关规则、skill、命令和路径约定。

### 3. 先跑通一个 workflow

推荐先从一个高频任务入口开始，而不是一上来同时改所有文件。

建议优先体验：

- `review-ui`
- `fix-issue`
- `workflows/ship-page`
- `workflows/add-endpoint-orchestrator`

### 4. 再按团队习惯逐步演进

先让它可用，再让它完整。
不要一开始就把所有 rules、hooks、agents 都堆满。

## 目录结构

```text
claude-directory/
  README.md
  docs/
    architecture-overview.md
    commands-vs-agents-vs-skills.md
    command-and-skill-frontmatter.md
    global-vs-project-scope.md
    memory-and-rules.md
    settings-and-hooks.md
    task-system-and-agent-teams.md
  workflows/
    page-shipping-workflow.md
    api-route-workflow.md
    bugfix-workflow.md
  project-root/
    CLAUDE.md
    .mcp.json
    .worktreeinclude
    .claude/
      settings.json
      settings.local.json
      rules/
      commands/
        workflows/
      skills/
      agents/
      agent-memory/
      hooks/
        README.md
        config/
        scripts/
      output-styles/
    apps/
      web/
        CLAUDE.md
        src/
      api/
        CLAUDE.md
        src/
        database/
          CLAUDE.md
    packages/
      contracts/
        CLAUDE.md
    tests/
      e2e/
        CLAUDE.md
```

其中这一套目录的默认职责是：

- `apps/web/`：前端应用
- `apps/api/`：后端接口和数据访问
- `packages/contracts/`：前后端共享契约、结构定义和类型
- `tests/e2e/`：跨前后端关键链路回归测试

## 每一层是干什么的

### `CLAUDE.md`

monorepo 总约定。

适合放：

- 项目形态
- 技术栈
- 架构边界
- 工作方式
- 编码和测试总原则

不适合放：

- 所有专题规则
- 某个局部页面的临时要求
- 所有高频任务的完整流程

### `.claude/rules/`

专题规则和局部规则。

适合放：

- 前端 UI 规则
- API 设计规则
- 安全规则
- 数据库规则
- 测试规则

### `.claude/commands/`

用户高频任务入口。

适合放：

- `review-ui`
- `fix-issue`
- `trace-request`
- `add-endpoint`
- `workflows/*`

### `.claude/skills/`

可复用的任务模板。

适合放：

- 页面搭建
- API 脚手架
- bug 收敛
- 安全检查
- 数据库变更评审
- UI 质量检查

### `.claude/agents/`

角色化、稳定视角的评审能力。

适合放：

- `frontend-reviewer`
- `backend-reviewer`
- `accessibility-reviewer`
- `e2e-reviewer`
- `code-reviewer`

### `.claude/agent-memory/`

某个 agent 的长期经验和项目观察。
它不是项目总规则库，而更像角色工作笔记。

### `.claude/hooks/`

自动化辅助动作。

适合放：

- 编辑后自动格式化
- 特定文件变化时提醒
- 会话辅助动作

### `.claude/settings.json`

团队共享运行配置。

适合放：

- permissions
- hooks
- worktree 配置
- 团队统一接受的自动化行为

### `apps/web/`

前端应用。

适合放：

- 页面、路由、组件
- 浏览器交互和状态编排
- 面向用户的 UI 和 loading / empty / error state

### `apps/api/`

后端应用。

适合放：

- 请求入口或接口入口
- 认证、授权、限流
- 业务逻辑、数据访问、数据库迁移

### `packages/contracts/`

前后端共享契约层。

适合放：

- 契约 schema 或结构定义
- 请求和响应 DTO
- 共享类型
- 前后端都要依赖的接口约束

## 推荐工作流

这个模板不只是提供单点命令，也推荐把高频任务组织成稳定 workflow。

### 页面交付

推荐组合：

- `workflows/ship-page`
- `scaffold-page`
- `ui-review`
- `accessibility-reviewer`

说明文档见：

- [`workflows/page-shipping-workflow.md`](./workflows/page-shipping-workflow.md)

### 接口交付

推荐组合：

- `workflows/add-endpoint-orchestrator`
- `scaffold-api-route`
- `security-review`
- `db-migration-review`
- `backend-reviewer`

说明文档见：

- [`workflows/api-route-workflow.md`](./workflows/api-route-workflow.md)

### Bug 修复

推荐组合：

- `workflows/fix-issue-orchestrator`
- `bug-triage`
- `frontend-reviewer`
- `backend-reviewer`
- `e2e-reviewer`

说明文档见：

- [`workflows/bugfix-workflow.md`](./workflows/bugfix-workflow.md)

## 建议先读哪几份文档

如果你第一次接触这套目录，推荐按这个顺序看：

1. [`docs/architecture-overview.md`](./docs/architecture-overview.md)
2. [`docs/commands-vs-agents-vs-skills.md`](./docs/commands-vs-agents-vs-skills.md)
3. [`docs/global-vs-project-scope.md`](./docs/global-vs-project-scope.md)
4. [`docs/memory-and-rules.md`](./docs/memory-and-rules.md)
5. [`docs/command-and-skill-frontmatter.md`](./docs/command-and-skill-frontmatter.md)
6. [`docs/settings-and-hooks.md`](./docs/settings-and-hooks.md)
7. [`docs/task-system-and-agent-teams.md`](./docs/task-system-and-agent-teams.md)
8. [`workflows/page-shipping-workflow.md`](./workflows/page-shipping-workflow.md)

## 文档地图

如果你是按主题阅读，推荐这样理解：

### 核心篇

- [`docs/architecture-overview.md`](./docs/architecture-overview.md)
  先看整体分层和目录职责
- [`docs/commands-vs-agents-vs-skills.md`](./docs/commands-vs-agents-vs-skills.md)
  再看 command、agent、skill 的边界
- [`docs/global-vs-project-scope.md`](./docs/global-vs-project-scope.md)
  再看哪些能力适合放项目层，哪些更适合放全局层
- [`docs/memory-and-rules.md`](./docs/memory-and-rules.md)
  再看规则和 memory 怎么沉淀
- [`docs/command-and-skill-frontmatter.md`](./docs/command-and-skill-frontmatter.md)
  最后看文件头字段怎么写得更稳定

### 配置篇

- [`docs/settings-and-hooks.md`](./docs/settings-and-hooks.md)
  解释项目运行边界和自动化动作

### 进阶篇

- [`docs/task-system-and-agent-teams.md`](./docs/task-system-and-agent-teams.md)
  解释 task system、agent teams 和项目模板之间的边界

### 示例篇

- [`workflows/page-shipping-workflow.md`](./workflows/page-shipping-workflow.md)
- [`workflows/api-route-workflow.md`](./workflows/api-route-workflow.md)
- [`workflows/bugfix-workflow.md`](./workflows/bugfix-workflow.md)

## 如何按项目结构裁剪

这套模板偏网页系统，但结构本身是通用的。

### 如果你的前端目录边界不同

- 调整 `apps/web` 下的页面和组件约束
- 把页面相关 skill 改成你的前端工程惯例

### 如果你的数据访问层结构不同

- 调整 `apps/api/database` 和 `database.md` 的路径约定
- 把数据库相关 skill 改成你的数据访问与迁移流程

### 如果你的端到端测试边界不同

- 调整测试规则
- 删除或弱化 `e2e-reviewer`

### 如果你的后端入口结构不同

- 保留 `apps/api` 的边界设计
- 改掉请求入口、业务模块、数据访问层的具体命名
- 把接口 skill 和后端规则切成你的项目惯例

## 设计原则

这个模板遵循几个简单原则：

- 项目总约定和专题规则分开
- 用户入口和复用套路分开
- 专家角色和执行模板分开
- 前后端职责边界清楚，契约层单独存在
- 默认先复用现有实现模式
- 改动尽量小、尽量集中、尽量可评审
- 先让 workflow 稳定，再让配置复杂

## 这套模板适合谁

适合：

- 想把 Claude Code 用成项目级工程工具的团队
- 想让 `.claude` 目录长期可维护的人
- 想把高频任务做成标准 workflow 的项目
- 想找一套前后端分离网页系统参考模板的人

不太适合：

- 只想临时写几个个人 prompt
- 还没有稳定项目结构的超早期实验仓库
- 不打算维护任何项目级配置的纯一次性使用场景

## 使用建议

先把它当成“项目模板”，不是“最终答案”。

推荐做法是：

- 先复制 `project-root/`
- 先保留最小可用的一组 rules 和 commands
- 先跑通 1 到 2 个高频 workflow
- 再根据团队真实使用情况补 agents、memory 和 hooks

当它开始承接真实任务后，再持续演化，效果会比一开始追求“大而全”更好。

## 相关文件

- [`project-root/`](./project-root)
- [`docs/commands-vs-agents-vs-skills.md`](./docs/commands-vs-agents-vs-skills.md)
- [`docs/architecture-overview.md`](./docs/architecture-overview.md)
- [`docs/global-vs-project-scope.md`](./docs/global-vs-project-scope.md)
- [`docs/memory-and-rules.md`](./docs/memory-and-rules.md)
- [`docs/command-and-skill-frontmatter.md`](./docs/command-and-skill-frontmatter.md)
- [`docs/settings-and-hooks.md`](./docs/settings-and-hooks.md)
- [`docs/task-system-and-agent-teams.md`](./docs/task-system-and-agent-teams.md)
- [`workflows/page-shipping-workflow.md`](./workflows/page-shipping-workflow.md)
- [`workflows/api-route-workflow.md`](./workflows/api-route-workflow.md)
- [`workflows/bugfix-workflow.md`](./workflows/bugfix-workflow.md)
