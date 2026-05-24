# API Route Workflow

这份文档说明网页系统中一个接口从“提出需求”到“可以交付评审”的推荐流程。

它描述的是 `claude-directory` 这套 `command`、`skill`、`agent` 配置如何配合完成一次接口交付，而不是在替代团队自己的开发规范。

## 目标

一个可交付的接口，不只是“能返回数据”，还应该满足：

- route 位置合理
- 请求边界清楚
- 输入校验完整
- 返回结构和错误处理一致
- 认证、授权、限流等边界明确
- 核心业务逻辑可复用
- 测试和风险说明足够清楚

## 参与构件

推荐组合如下：

- `add-endpoint-orchestrator`
- `scaffold-api-route`
- `backend-reviewer`
- `security-review`
- `db-migration-review`

其中：

- `command` 负责组织完整交付流程
- `skill` 负责接口搭建和专项检查
- `agent` 负责从后端评审视角检查实现质量

## 推荐流程

### 阶段 1：理解附近接口模式

在动手实现前，先看附近已有实现：

- 相邻 route handler 或 server action
- 项目里常见的请求和响应结构
- 校验、错误处理、认证方式
- 共享逻辑通常下沉到哪里
- 第三方集成一般放在哪一层

这一步的目标，是避免做出一个“功能可用但风格脱节”的接口。

### 阶段 2：生成接口骨架

由 `add-endpoint-orchestrator` 调用 `scaffold-api-route`，完成第一版接口骨架。

这一步应该优先保证：

- route 或 action 放在正确位置
- 输入输出边界清楚
- 不可信输入得到校验
- 业务逻辑不直接堆在入口文件里
- 类型和运行时校验尽量保持一致

### 阶段 3：检查边界完整性

接口骨架出来以后，优先检查边界，而不是急着追求实现细节。

至少要显式考虑：

- 参数是否合法
- 错误返回是否一致
- 是否需要 auth 或授权
- 是否需要限流
- 是否需要日志或观测性
- 第三方依赖失败时怎么处理

如果这些边界没想清楚，接口通常还不算可交付。

### 阶段 4：专项检查

根据接口特征，补充专项检查。

如果涉及数据库 schema、migration、数据一致性：

- 调用 `db-migration-review`

如果涉及权限、敏感信息、外部输入、安全边界：

- 调用 `security-review`

这一步的目标，是在通用实现检查之外，把高风险领域单独看一遍。

### 阶段 5：后端评审

由 `add-endpoint-orchestrator` 调用 `backend-reviewer`，重点检查：

- 请求边界是否清楚
- 逻辑是否正确下沉
- 错误处理是否稳定
- 类型与校验是否一致
- 是否偏离附近实现模式
- 是否留下了明显的可维护性问题

### 阶段 6：输出交付总结

最后由 workflow 统一输出：

- 接口入口文件
- 请求和响应结构摘要
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

也可以理解为：

```text
需求
  -> 看附近接口实现
  -> 生成接口骨架
  -> 补全校验、错误处理、权限边界
  -> 做安全或数据库专项检查
  -> 做后端评审
  -> 输出交付总结
```

## 什么时候适合用这个 workflow

以下场景很适合：

- 新增 API route
- 新增 server action
- 重构一个旧接口
- 把业务逻辑从页面或组件里抽到服务端边界
- 在上线前对接口做一次结构化检查

## 什么时候可以简化

以下场景不一定要完整走一遍：

- 只改一个非常局部的字段映射
- 只修一个极小的参数处理 bug
- 只是临时验证某个返回结构
- 只是重命名一个已有字段，不改变行为

这时可以直接用更小粒度的 command 或 skill。

## 推荐实践

- 入口负责边界，业务逻辑尽量下沉
- 所有不可信输入都要校验
- 先复用附近模式，再决定是否抽象
- 涉及安全和数据库时，优先单独做专项检查
- 输出时要明确写出未验证项，不要假装已经完全闭环

## 总结

这个 workflow 的核心价值，是让接口开发从一开始就围绕“边界完整、可维护、可评审”展开，而不是只追求快速返回结果。

如果把职责压缩成一句话：

- `add-endpoint-orchestrator` 负责组织完整交付流程
- `scaffold-api-route` 负责把接口搭出来
- `security-review` 和 `db-migration-review` 负责专项风险检查
- `backend-reviewer` 负责从后端视角判断它是否真的像这个项目自己的接口
