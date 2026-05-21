# claude-directory 样例

这个目录按 `claude-directory` 的目录结构整理了两套样例：

- `project-root/`：模拟业务仓库根目录下的项目级配置
- `user-home/`：模拟用户主目录下的全局配置

其中 `project-root/` 这套样例已经按网页系统开发场景补充完善，默认假设技术栈为 `React + Next.js App Router + TypeScript + pnpm + Tailwind CSS + Zod + Prisma + Vitest + Playwright`。

`project-root/` 里重点包含这些内容：

- `CLAUDE.md`：项目级总约定
- `.claude/rules/`：按主题和目录拆分的规则文件
- `.claude/commands/`：高频任务入口
- `.claude/skills/`：页面搭建、接口实现、缺陷排查、数据库评审等任务模板
- `.claude/agents/` 与 `.claude/agent-memory/`：前端、后端、可访问性、E2E 等评审角色
- `.claude/settings.json`：团队共享的 permissions、hooks、worktree 示例
- `.claude/hooks/`：编辑后自动格式化等项目级 hook 脚本示例
- `.mcp.json`：GitHub 与只读 Postgres 的 MCP 样例
- `.worktreeinclude`：为 worktree 复制本地运行所需的 gitignored 文件

使用时建议先复制 `project-root/` 里的目录结构，再按你的实际技术栈删改规则、命令和技能文件。`settings.local.json` 适合放个人机器专用配置，`user-home/` 适合放跨项目的全局偏好。若项目不用 `Prettier`，可以直接删除 `.claude/hooks/format-edited-file.mjs` 或改成你自己的格式化命令。`settings.json` 里的 `worktree.baseRef` 也需要按你的默认分支名调整，例如 `main` 或 `master`。

这里的 `skills/` 仅指样例配置文件，用来演示目录结构和写法，不包含本机本地 skill，也不包含文章文档。
