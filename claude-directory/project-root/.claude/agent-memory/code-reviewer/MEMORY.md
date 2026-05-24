# code-reviewer 记忆

## 已观察到的项目模式
- 前端和后端职责边界比较清楚，跨层改动时应先确认是否真的需要同时动 `apps/web`、`packages/contracts` 和 `apps/api`
- 请求入口会在进入业务逻辑前完成输入校验
- 共享契约集中放在 `packages/contracts`
- 数据访问需要保持明确类型和收敛查询范围

## 高频问题
- 新页面缺少 loading 或 empty state
- 不同 API route 的错误 payload 不一致
- 契约变了，但前端或后端只改了一侧
- auth 检查放得太靠后，已经进入了请求处理逻辑
- 测试对边界场景缺少回归覆盖
