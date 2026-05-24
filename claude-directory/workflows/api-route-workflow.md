# API Route Workflow

这份文档说明前后端分离网页系统中，一个接口从“提出需求”到“可以交付评审”的推荐流程。

它描述的是 `claude-directory` 这套 `command`、`skill`、`agent` 配置如何配合完成一次接口交付。

## 目标

一个可交付的接口，不只是“能返回数据”，还应该满足：

- 入口位置合理
- 请求边界清楚
- 输入校验完整
- 返回结构和错误处理一致
- 认证、授权、限流等边界明确
- 核心业务逻辑可复用
- 与 `packages/contracts` 保持同步
- 测试和风险说明足够清楚

## 推荐组合

- `workflows/add-endpoint-orchestrator`
- `scaffold-api-route`
- `security-review`
- `db-migration-review`
- `backend-reviewer`

## 推荐流程

### 阶段 1：理解附近接口模式

先看清楚：

- `apps/api` 中相邻 handler 或控制器入口
- 既有输入校验和错误处理模式
- 是否已经有对应的 `packages/contracts` 定义
- 认证、授权和限流方式

### 阶段 2：生成接口骨架

由 `add-endpoint-orchestrator` 调用 `scaffold-api-route`，完成第一版接口骨架。

这一步应该优先保证：

- 入口放在正确位置
- 请求和响应结构优先复用共享契约
- 不可信输入得到校验
- 业务逻辑不直接堆在入口文件里

### 阶段 3：检查边界完整性

至少要显式考虑：

- 参数是否合法
- 错误返回是否一致
- 是否需要 auth 或授权
- 是否需要限流
- 是否需要日志或观测性
- 前端调用方是否会受契约变化影响

### 阶段 4：专项检查

如果涉及数据库 schema、migration、数据一致性：

- 调用 `db-migration-review`

如果涉及权限、敏感信息、外部输入、安全边界：

- 调用 `security-review`

### 阶段 5：后端评审

由 `add-endpoint-orchestrator` 调用 `backend-reviewer`，重点检查：

- 输入校验和响应结构
- 共享契约复用情况
- auth 和授权
- 数据库安全性、查询形态和事务边界
- 错误处理和可观测性缺口

### 阶段 6：输出交付总结

最后统一输出：

- 接口入口文件
- 契约定义位置
- 主要业务逻辑位置
- 需要补的测试
- 安全点、权限点、未验证项

## 工作流示意

```text
User Request
  -> add-endpoint-orchestrator (command)
  -> scaffold-api-route (skill)
  -> security-review / db-migration-review (skill, when needed)
  -> backend-reviewer (agent)
  -> Delivery Summary
```

## 总结

这个 workflow 的核心价值，是让接口开发从一开始就围绕“边界完整、契约稳定、可维护、可评审”展开，而不是只追求快速返回结果。
