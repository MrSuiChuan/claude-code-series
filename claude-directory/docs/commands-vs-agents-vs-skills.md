# Commands vs Agents vs Skills

这份文档解释 `claude-directory` 里最核心的三类构件：`commands`、`agents` 和 `skills`。它们都能“指导 Claude 做事”，但职责不同。把边界分清楚，目录结构才会长期可维护。

## 一句话定义

- `Command`：用户入口，负责组织一次任务流程
- `Agent`：专家角色，负责从固定视角稳定输出
- `Skill`：可复用的方法模板或任务手册

一个简单判断方法是：

- 需要用户显式触发的入口，优先考虑 `command`
- 需要稳定专家视角的能力，优先考虑 `agent`
- 需要被多个入口复用的套路，优先考虑 `skill`

## Command 是什么

`command` 更像一个“任务入口”。用户通过 slash command 触发它，然后由它决定接下来要读什么、查什么、调哪些 agent 或 skill。

适合放进 `command` 的内容：

- 高频任务入口
- 需要先理解用户目标，再组织执行步骤的流程
- 需要串联多个角色或多个阶段的任务
- 需要固定输出结构的工作流

示例：

- `review-ui`
- `fix-issue`
- `trace-request`
- `workflows/ship-page`
- `workflows/fix-issue-orchestrator`

不适合放进 `command` 的内容：

- 只是一些长期规则
- 只是某个小任务的检查清单
- 没有入口价值、只会被其他流程复用的内容

## Agent 是什么

`agent` 更像一个“专家角色”。它不一定是用户直接触发的入口，而是为了在复杂任务里提供稳定的分析视角。

适合放进 `agent` 的内容：

- 需要角色化评审的任务
- 需要特定工具边界的能力
- 需要积累该角色的 memory 的场景
- 不同任务里都可能被反复调用的“审稿人”或“专家”

示例：

- `frontend-reviewer`
- `backend-reviewer`
- `accessibility-reviewer`
- `e2e-reviewer`

一个好的 agent，通常应该满足这几个条件：

- 角色边界清晰
- 关注点稳定
- 输出格式相对稳定
- 不试图包办所有事情

如果一个 agent 既负责搭页面、又负责改数据库、又负责做测试、又负责写总结，通常说明它太泛了。

## Skill 是什么

`skill` 更像一个“可复用任务模板”。它通常不强调角色，而强调步骤、清单和做法。

适合放进 `skill` 的内容：

- 可复用的任务套路
- 某类问题的固定处理方式
- 被多个 command 或 agent 共用的执行手册
- 需要稳定检查清单的工作

示例：

- `scaffold-page`
- `scaffold-api-route`
- `bug-triage`
- `security-review`
- `db-migration-review`
- `ui-review`

一个好的 skill，应该让 Claude 在面对相似任务时少走弯路，而不是重新从零组织思路。

## 推荐拆分方式

推荐按下面的顺序决定放哪一层：

1. 先问：这是用户会不会直接使用的入口？
   如果会，优先做成 `command`
2. 再问：它是不是一个稳定的专家视角？
   如果是，优先做成 `agent`
3. 再问：它是不是一个会被重复复用的方法模板？
   如果是，优先做成 `skill`

很多场景里，这三者会组合使用，而不是互相替代。

例如一个完整的页面交付流程可以是：

- `ship-page` 作为 `command`
- `scaffold-page` 和 `ui-review` 作为 `skills`
- `accessibility-reviewer` 作为 `agent`

如果这是一个前后端分离 monorepo 里的页面需求，`command` 还可以继续编排：

- 在 `apps/web` 搭建页面和状态
- 在 `packages/contracts` 对齐请求 / 响应契约
- 必要时联动 `apps/api` 补接口或补字段

也就是说：

- `command` 负责编排
- `skill` 负责执行套路
- `agent` 负责专家判断

## 在这个模板里的推荐职责

### Commands

建议放“任务入口”和“工作流入口”，尤其是跨 `apps/web`、`apps/api`、`packages/contracts` 的编排：

- 新增前端页面
- 新增后端接口
- 跟进一次契约变更
- 修复问题
- 评审 UI
- 跟踪请求链路

### Agents

建议放“角色化评审”和“稳定分析视角”：

- 前端评审（重点看 `apps/web`）
- 后端评审（重点看 `apps/api`）
- 可访问性评审
- E2E 评审（重点看 `tests/e2e` 是否覆盖关键链路）
- 通用代码评审

### Skills

建议放“中等粒度、可复用的任务模板”：

- 页面搭建（主要落到 `apps/web`）
- API 脚手架（主要落到 `apps/api`）
- 契约收边（主要落到 `packages/contracts`）
- bug 收敛
- 安全检查
- 数据库变更评审
- UI 质量检查

## 常见反模式

### 1. 把所有内容都塞进 `CLAUDE.md`

这样做的结果通常是：

- 文件太长，优先级混乱
- 长期规则和临时流程混在一起
- 某个局部任务的小规则会污染整个项目上下文

更好的做法是：

- `CLAUDE.md` 放项目总约定
- `rules/` 放专题规则
- `commands/` 放入口
- `agents/` 放角色
- `skills/` 放套路

### 2. 用一个全能 agent 处理所有任务

这通常会让 agent：

- 角色边界模糊
- 指令越来越长
- 很难维护
- 很难稳定复用

更好的做法是按视角拆分，例如：

- 一个前端 reviewer
- 一个后端 reviewer
- 一个 accessibility reviewer

### 3. command 和 skill 写成两份几乎重复的提示词

如果 `command` 只是把 `skill` 原样复制一遍，后续维护成本会很高。

更好的做法是：

- `command` 负责组织流程
- `skill` 负责具体套路
- 两者分工明确，避免重复

### 4. 把长期项目规则写进 agent memory

memory 更适合积累上下文、偏好、历史线索，不适合替代规则文件。

更好的做法是：

- 长期稳定规则放到 `CLAUDE.md` 或 `rules/`
- 可演化的任务经验再放到 memory

## 一个简单判断表

| 场景 | 更适合 |
|---|---|
| 用户要一个稳定的 slash command 入口 | `command` |
| 需要从固定角色视角做分析或评审 | `agent` |
| 需要一套可复用的方法步骤 | `skill` |
| 需要把多个阶段串成流程 | `command` |
| 需要被多个流程共用 | `skill` 或 `agent` |
| 需要长期角色化积累 | `agent` |

## 推荐实践

- 先把高频入口做成 command
- 再把复用性强的步骤下沉成 skill
- 再把需要独立视角的部分拆成 agent
- 保持每个文件职责单一，避免“什么都能做”
- 优先沿用现有目录和命名模式，不轻易发明新层级

## 总结

如果把这三者分工说得更直白一点：

- `command` 决定“这次任务怎么走”
- `agent` 决定“从谁的视角来看”
- `skill` 决定“这类事一般怎么做”

当它们的职责清楚时，项目级 `.claude` 配置会更像工程系统，而不是一堆互相重叠的 prompt。
