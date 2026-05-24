# Settings and Hooks

这份文档解释 `claude-directory` 里的 `settings` 和 `hooks` 应该分别承担什么职责，以及项目里为什么需要把它们单独设计出来。

`settings` 负责定义 Claude Code 在项目里的运行边界。
`hooks` 负责在特定事件发生时自动执行一些辅助动作。

两者结合起来，目标不是“让配置更复杂”，而是让团队协作时的行为更稳定、更可预测。

## Settings 解决什么问题

`.claude/settings.json` 主要解决 4 类问题：

- 哪些命令可以直接执行
- 哪些操作应该先确认
- 哪些自动化行为要在项目里统一开启
- worktree 或本地运行环境要怎么配合

在团队项目里，`settings` 更像“运行规则”，而不是普通的提示词。

## 建议的配置分层

推荐把设置分成两层：

### 1. `.claude/settings.json`

这是团队共享配置，应该进入版本库。

适合放这里的内容：

- `permissions.allow`
- `permissions.ask`
- `permissions.deny`
- 团队约定的 hooks
- worktree 相关默认配置
- 团队统一接受的自动化行为

这类配置应该满足一个原则：

- 换一台机器、换一个同事，行为仍然基本一致

### 2. `.claude/settings.local.json`

这是个人本地配置，不应该进入版本库。

适合放这里的内容：

- 本机专用路径
- 临时禁用 hooks
- 个人实验性配置
- 只适用于自己电脑的本地工具设置

这层配置的目标不是改变团队规则，而是在不影响他人的前提下做本地个性化调整。

## Permissions 怎么设计

`permissions` 最容易失控，所以建议始终按 3 类来拆：

- `allow`
- `ask`
- `deny`

### allow

适合放低风险、高频、可预期的命令。

例如：

- `pnpm --filter web lint`
- `pnpm --filter api typecheck`
- `pnpm --filter contracts test`
- `pnpm -r test`
- `git status`
- `git diff *`

这些命令通常不会直接破坏环境，且经常需要重复执行。

### ask

适合放有副作用、但又经常合理发生的命令。

例如：

- `pnpm add *`
- `pnpm remove *`
- `npx *`
- `git push *`

这类命令不一定危险，但值得在执行前停一下，确认当前上下文是否真的需要。

### deny

适合放明显高风险、在项目中不应默认出现的命令。

例如：

- `rm -rf /`
- `git push --force *`
- `git reset --hard *`

这部分的原则很简单：

- 不是“Claude 能不能做”
- 而是“这个项目应不应该默认允许它做”

## Worktree 配置为什么重要

如果团队会用 worktree 跑并行任务，那么 `.claude/settings.json` 里最好把这块写清楚。

worktree 配置主要解决两个问题：

- Claude 在隔离分支上工作时，默认基于哪个分支创建
- 哪些目录或依赖需要复用或特殊处理

在样例里，`node_modules` 被作为 `symlinkDirectories` 使用，就是在减少重复安装成本。
对于这个前后端分离模板，`.worktreeinclude` 还可以顺手复制一些本地运行必需但不进版本库的文件，例如 `apps/api/prisma/dev.db`。

如果团队真的会依赖 worktree，建议同时维护：

- `.claude/settings.json`
- `.worktreeinclude`

前者描述 Claude 的 worktree 行为，后者描述本地运行所需的 gitignored 文件如何复制。

## Hooks 解决什么问题

hooks 的目标不是制造“魔法”，而是把那些重复、机械、稳定的动作自动化。

典型场景包括：

- 编辑后自动格式化
- 只针对 `apps/web` 或 `apps/api` 下的变更触发对应工具链
- 会话开始时加载项目上下文
- 特定文件变化后提醒重新检查环境变量
- 任务结束后输出统一提示

判断一个动作该不该做成 hook，可以问两个问题：

1. 这个动作是不是重复出现？
2. 这个动作是不是几乎总是应该发生？

如果两个答案都是“是”，它就很适合做成 hook。

## 当前模板里的 hook 设计

当前模板已经提供了一个很实用的例子：

- 编辑文件后自动格式化

这个例子背后的设计思路其实很好：

- 只处理受支持的文件类型
- 只处理项目目录内文件
- 优先尝试项目已有工具链
- 找不到 formatter 时安静退出，不要打断主流程

这类 hook 的价值在于：

- 它不会改变你的任务目标
- 但会持续减少低价值收尾工作

## 什么样的 hook 值得保留

值得保留的 hook 往往具备这些特征：

- 触发条件清晰
- 副作用有限
- 失败时可以安全退出
- 不会频繁打断主任务
- 对团队大多数成员都成立

例如：

- 格式化编辑文件
- 在关键配置文件变化时发出提醒
- 在会话开始时加载少量项目上下文

## 什么样的 hook 不建议默认启用

以下类型更适合谨慎使用，或者只放在本地配置里：

- 自动执行耗时很长的命令
- 每次编辑都跑大范围测试
- 依赖个人本机路径的脚本
- 会频繁修改工作区内容的脚本
- 失败时会阻塞主流程的脚本

一个实用原则是：

- hook 应该辅助主流程
- 不应该接管主流程

## 推荐的 hooks 组织方式

如果后续要扩展 hooks，建议采用这种结构：

```text
.claude/hooks/
  README.md
  format-edited-file.mjs
  config/
    hooks-config.json
    hooks-config.local.example.json
  scripts/
    dispatch.mjs
```

这样做的好处是：

- 单个脚本职责更清楚
- 团队配置和本地覆盖分离
- 后续想加新 hook 时不会把所有逻辑塞进一个文件

## 什么时候应该改 settings

以下情况通常值得更新 `.claude/settings.json`：

- 团队新增了一类高频命令
- 某类命令的风险级别判断变了
- 项目开始稳定使用 worktree
- 某个 hook 已经被团队证明长期有价值
- 本地开发工具链发生明显变化

不建议因为一次临时需求就立刻改团队共享配置。
如果只是个人短期试验，优先放到 `settings.local.json`。

## 推荐实践

- 团队规则优先放到 `.claude/settings.json`
- 本机特例优先放到 `.claude/settings.local.json`
- 只把高频、稳定、低风险的动作做成默认 hook
- hook 要尽量小、可理解、可静默失败
- 配置的目标是减少摩擦，而不是增加惊喜

## 总结

可以把这两者简单理解为：

- `settings` 决定 Claude 在项目里“允许怎么行动”
- `hooks` 决定在关键事件发生时“顺手自动做什么”

当它们分工清楚时，项目级 `.claude` 配置才更像工程系统，而不是散落的技巧集合。
