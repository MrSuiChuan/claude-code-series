---
argument-hint: <feature-or-route-name>
---

为 $ARGUMENTS 设计并实现一个新的 API endpoint。

检查清单：

1. 确认接口放在 `apps/api` 的正确位置，以及请求和响应结构
2. 用 Zod 完成输入校验
3. 优先复用 `packages/contracts` 的共享契约，必要时同步新增或更新
4. 按需要补上 auth、权限检查和限流
5. 实现 handler 和领域逻辑
6. 新增或更新测试，并说明前端调用方是否也要同步调整
