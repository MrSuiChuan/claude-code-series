---
description: 为 `apps/api` 创建或重构 API endpoint。适用于新增接口入口、动作路径或写操作路径，并同时补上共享契约、校验、auth 检查、稳定错误处理和测试的场景。
argument-hint: <route-or-action-name>
---

为 $ARGUMENTS 实现 `apps/api` 中的接口入口。

检查清单：

1. 确认正确的 route 位置
2. 优先复用或新增 `packages/contracts` 中的请求和响应结构
3. 校验所有不可信输入
4. 在需要时补上 auth、授权和限流
5. 让业务逻辑可以从服务层或共享模块复用
6. 新增测试，并明确前端调用方是否需要同步调整
