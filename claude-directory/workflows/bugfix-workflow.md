# Bugfix Workflow

这份文档说明前后端分离网页系统里，一个 bug 从“收到问题描述”到“形成可执行修复方案”的推荐流程。

它不是要求所有 bug 都走同样重的流程，而是给 `claude-directory` 里的 `command`、`skill`、`agent` 提供一个稳定的协作方式。

## 目标

一个好的修复流程，不只是尽快改代码，还应该做到：

- 先把问题说清楚
- 找到最可能的入口和传播链路
- 把 `apps/web`、`packages/contracts`、`apps/api`、数据库之间的关系理清
- 区分“已确认根因”和“高概率推断”
- 优先给出最小且安全的修复方案

## 推荐组合

- `fix-issue-orchestrator`
- `bug-triage`
- `frontend-reviewer`
- `backend-reviewer`
- `accessibility-reviewer`
- `e2e-reviewer`

## 推荐流程

### 阶段 1：重新表述问题

先把收到的问题描述重新说清楚：

- 预期行为是什么
- 实际行为是什么
- 影响范围大概在哪里
- 当前有哪些假设，哪些信息还缺失

### 阶段 2：找到入口

先查看最可能的入口位置：

- `apps/web` 中的页面或组件入口
- `packages/contracts` 中的请求或响应结构
- `apps/api` 中的 handler、service 和数据访问层
- 数据库与第三方集成层

### 阶段 3：问题收敛

由 `fix-issue-orchestrator` 调用 `bug-triage`，沿着链路做结构化分析：

- 先复述问题
- 找出最可能的入口
- 沿前端、共享契约、后端和数据层追踪
- 列出最可能的根因
- 给出最小安全修复方案
- 建议最小回归测试

### 阶段 4：按问题类型调对应 reviewer

如果问题偏前端：

- 调用 `frontend-reviewer`

如果问题偏接口、权限、数据库、服务端逻辑：

- 调用 `backend-reviewer`

如果问题涉及语义结构、焦点、键盘交互：

- 调用 `accessibility-reviewer`

如果问题在关键用户链路上：

- 调用 `e2e-reviewer`

### 阶段 5：输出修复结论

最后统一输出：

- 最可能根因
- 证据链或推断链
- 最小修复方案
- 建议补充的测试
- 风险点和未验证项

## 工作流示意

```text
User Bug Report
  -> fix-issue-orchestrator (command)
  -> bug-triage (skill)
  -> frontend-reviewer / backend-reviewer / accessibility-reviewer / e2e-reviewer
  -> Repair Summary
```

## 总结

这个 workflow 的核心价值，不是把修 bug 变慢，而是降低“跨前后端和共享契约误判根因后继续放大改动”的概率。
