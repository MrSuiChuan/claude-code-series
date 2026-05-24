# claude-code-series

这个仓库用于沉淀 Claude Code 相关的可复用脚本和项目级配置模板，重点解决两类实际问题：

- Claude Code 的安装、更新、卸载、诊断和迁移不够顺手
- 项目里想把 `CLAUDE.md`、`.claude/`、rules、commands、skills 这些配置真正落下来，但缺少一套能直接改、能解释清楚、还能演示 workflow 的参考模板

仓库只放脚本、配置和样例文件，不放文章正文、翻译文档、公众号草稿，也不提交本机私有 skill。

## 仓库结构

- `tooling/`
  Claude Code 生命周期管理脚本，覆盖安装、更新、卸载、状态检查、诊断、自检、迁移和报告生成

- `claude-directory/`
  一套面向网页系统项目的 Claude Code 工程化模板，不只包含 `project-root/` 配置样例，也补了 `docs/` 说明层、`workflows/` 示例层，以及更完整的 command / skill / agent / hooks 组织方式

## 先看哪里

如果你的目标是管理 Claude Code 的安装与运维：

- 先看 [tooling/README.md](./tooling/README.md)
- 实际脚本入口在 [tooling/scripts](./tooling/scripts)

如果你的目标是给项目补一套可直接复用的 Claude Code 配置：

- 先看 [claude-directory/README.md](./claude-directory/README.md)
- 模板主体在 [claude-directory/project-root](./claude-directory/project-root)
- 结构说明在 [claude-directory/docs](./claude-directory/docs)
- workflow 示例在 [claude-directory/workflows](./claude-directory/workflows)

## 当前模板定位

`claude-directory/` 现在不只是一个 `.claude` 目录样例，而是一套更完整的项目模板，包含三层内容：

- `project-root/`
  可直接复制进业务仓库的项目级模板
- `docs/`
  解释 `CLAUDE.md`、rules、commands、skills、agents、memory、settings、hooks 应该如何分工
- `workflows/`
  演示页面交付、接口交付、bug 修复等高频任务该如何把 command、skill、agent 串成稳定流程

其中 `project-root/` 这套模板当前默认面向网页系统开发，示例技术栈为：

- `React`
- `Next.js App Router`
- `TypeScript`
- `pnpm`
- `Tailwind CSS`
- `Zod`
- `Prisma`
- `Vitest`
- `Playwright`

模板里已经补了这些内容：

- 项目级 `CLAUDE.md`
- `.claude/rules/`
- `.claude/commands/`
- `.claude/commands/workflows/`
- `.claude/skills/`
- `.claude/agents/`
- `.claude/agent-memory/`
- `.claude/settings.json`
- `.claude/settings.local.json`
- `.claude/hooks/`
- `.mcp.json`
- `.worktreeinclude`

这套模板适合直接复制到业务仓库里，再按你的技术栈和团队习惯做删改。

## 快速开始

### 1. 管理 Claude Code 安装

进入脚本目录：

```powershell
cd .\tooling\scripts
```

常见入口：

- `Windows CMD`：`install_claude_code.cmd`
- `Windows PowerShell`：`.\install_claude_code.ps1`
- `macOS Terminal` / `Linux Terminal` / `WSL Terminal`：`bash install_claude_code.sh`

想先检查环境：

```powershell
.\install_claude_code.ps1 doctor
```

```bash
bash install_claude_code.sh doctor
```

完整命令清单和各环境写法见 [tooling/README.md](./tooling/README.md)。

### 2. 复制项目模板

建议从这里开始看：

- [claude-directory/README.md](./claude-directory/README.md)
- [claude-directory/project-root/CLAUDE.md](./claude-directory/project-root/CLAUDE.md)
- [claude-directory/project-root/.claude/settings.json](./claude-directory/project-root/.claude/settings.json)
- [claude-directory/project-root/.claude/rules](./claude-directory/project-root/.claude/rules)

如果想先理解结构，再动手复制，推荐按这个顺序继续读：

1. [claude-directory/docs/commands-vs-agents-vs-skills.md](./claude-directory/docs/commands-vs-agents-vs-skills.md)
2. [claude-directory/docs/architecture-overview.md](./claude-directory/docs/architecture-overview.md)
3. [claude-directory/workflows/page-shipping-workflow.md](./claude-directory/workflows/page-shipping-workflow.md)

落地时通常只需要做三件事：

1. 把 `project-root/` 下的目录结构复制到你的业务仓库
2. 按项目实际技术栈删改 rules、commands、skills 和 agents
3. 调整 `settings.local.json`、`worktree.baseRef`、hooks 和 MCP 配置

## 适合谁用

- 想把 Claude Code 真正接入项目协作流程的人
- 想统一团队级 `CLAUDE.md` 和 `.claude/` 约束的人
- 想给 Claude Code 做一套更省事的安装与维护脚本的人
- 想找一套网页系统方向参考模板的人

## 说明

- `tooling/` 偏执行和运维
- `claude-directory/` 偏项目规范、目录设计和 workflow 落地
- 两部分可以单独使用，也可以配合使用

如果你只是想快速上手，优先从 [tooling/README.md](./tooling/README.md) 和 [claude-directory/README.md](./claude-directory/README.md) 这两个入口开始。
