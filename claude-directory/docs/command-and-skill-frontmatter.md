# Command and Skill Frontmatter

这份文档解释在 Claude Code 生态里，`command`、`skill`、`agent` 这类文件头部的 frontmatter 应该怎么设计。

它不聚焦某个具体项目的业务逻辑，而是回答：

- 哪些字段通常值得写
- 哪些字段应该保持克制
- 什么信息适合放 frontmatter，什么不适合

## 为什么要重视 frontmatter

frontmatter 的价值不是“让文件看起来更正式”，而是让能力边界更稳定。

写得好的 frontmatter 能帮助 Claude 更快判断：

- 这个文件是干什么的
- 适合在哪种场景触发
- 需要什么输入
- 是否要限制工具边界

写得不好的 frontmatter 往往会导致：

- 能力描述过宽
- 入口和职责混乱
- 调用方不知道怎么传参数
- 同一类能力出现重复或重叠

## `description`

这是最基础、也最重要的字段。

应该写清楚：

- 这个能力的主要用途
- 它适合解决什么场景
- 它的边界在哪里

好的写法通常是：

- 先说动作
- 再说适用场景
- 最后补一句边界或约束

应该避免：

- 只写很短的标题
- 写成抽象口号
- 什么都能做、没有边界

## `argument-hint`

如果这是一个需要输入参数的 command，建议写清楚参数提示。

适合写：

- `<issue-id>`
- `<route-or-screen-name>`
- `<feature-or-task-name>`

它的目标不是定义完整语法，而是降低第一次使用时的理解成本。

如果一个 command 不需要参数，就不要为了形式硬加。

## `paths`

如果规则、skill 或辅助能力天然只面向某些目录，`paths` 很有价值。

它适合表达：

- 这个能力主要关注哪些目录
- 哪些文件变化时这条规则最相关

典型场景：

- 前端规则只看 `apps/web`
- 数据库规则只看 `apps/api/database`
- 契约规则只看 `packages/contracts`

不建议把 `paths` 写得过宽，否则它就失去筛选意义。

## 什么时候应该限制工具边界

有些能力适合明确限制工具范围。

例如：

- reviewer 型 agent 只需要 `Read`、`Grep`、`Glob`
- 某些分析型能力不应该默认拥有写权限
- 某些 command 只负责编排，不直接执行重操作

限制工具边界的目的不是“更严格”，而是：

- 让角色边界更清楚
- 降低能力漂移
- 减少不必要的副作用

## 什么内容不适合放 frontmatter

这些内容通常更适合正文，而不是 frontmatter：

- 长篇执行步骤
- 详细检查清单
- 复杂业务规则
- 任务背景解释
- 例外处理分支

frontmatter 适合放“元信息”，不适合承担完整说明书。

## Command 的 frontmatter 重点

对 `command` 来说，最值得优先写清楚的是：

- 它是不是一个用户入口
- 它需要什么参数
- 它大致解决什么任务

`command` 的正文则更适合写：

- 执行顺序
- 什么时候调用 skill
- 什么时候调用 agent
- 输出结构要求

## Skill 的 frontmatter 重点

对 `skill` 来说，最值得优先写清楚的是：

- 它是哪类可复用方法
- 它适用于什么任务
- 它不适用于什么任务

`skill` 的正文则更适合写：

- 固定步骤
- 检查项
- 执行原则

## Agent 的 frontmatter 重点

对 `agent` 来说，最值得优先写清楚的是：

- 它代表什么视角
- 它主要评审什么
- 它是否需要严格工具边界

`agent` 的正文则更适合写：

- 优先关注的风险
- 输出格式
- 每个问题都要附修复建议这类约束

## 一个简单判断表

| 内容 | 更适合放哪里 |
|---|---|
| 用途简介 | frontmatter |
| 参数提示 | frontmatter |
| 目录作用范围 | frontmatter |
| 详细步骤 | 正文 |
| 检查清单 | 正文 |
| 长篇背景说明 | 正文 |

## 推荐实践

- `description` 保持具体，不写空话
- `argument-hint` 只在确实需要参数时添加
- `paths` 只在有明确目录边界时添加
- frontmatter 只放元信息，复杂逻辑放正文
- 同一类文件保持同一套写法风格

## 和本模板的关系

这个模板里的：

- `commands/`
- `skills/`
- `agents/`
- `rules/`

都适合遵循一套稳定的 frontmatter 约定。

这样做的好处是：

- 新增能力时更容易照着写
- 目录整体更整齐
- Claude 更容易根据结构理解边界

如果你准备新增一个 command 或 skill，建议先读：

- [`commands-vs-agents-vs-skills.md`](./commands-vs-agents-vs-skills.md)
- 再读这份 frontmatter 文档

前者解决“该放哪一层”，后者解决“这一层的文件头该怎么写”。
