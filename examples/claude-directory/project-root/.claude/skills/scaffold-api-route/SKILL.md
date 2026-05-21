---
description: 为 TypeScript 网页系统创建或重构 API endpoint。适用于新增 route handler、server action 或 mutation 路径，并同时补上校验、auth 检查、稳定错误处理和测试的场景。
argument-hint: <route-or-action-name>
---

为 $ARGUMENTS 实现 API route 或 server action。

检查清单：

1. 确认正确的 route 位置
2. 定义请求和响应结构
3. 校验所有不可信输入
4. 在需要时补上 auth、授权和限流
5. 让业务逻辑可以从 `src/lib` 复用
6. 新增测试，或明确说明为什么跳过测试
