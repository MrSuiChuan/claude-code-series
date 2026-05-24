---
argument-hint: <user-action-or-endpoint>
---

追踪 $ARGUMENTS 的端到端请求链路。

需要包含：

1. `apps/web` 中的页面、组件或交互入口
2. `packages/contracts` 中涉及的请求或响应契约
3. `apps/api` 中的校验、auth 和 handler 入口
4. service、领域逻辑和第三方集成路径
5. 数据库读写路径
6. 错误处理、日志记录和覆盖这条链路的测试
