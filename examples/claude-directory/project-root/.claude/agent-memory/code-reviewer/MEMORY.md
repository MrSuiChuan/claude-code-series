# code-reviewer 记忆

## 已观察到的项目模式
- 除非交互确实需要，否则优先使用 server component，而不是 `"use client"`
- route handler 会在进入业务逻辑前完成输入校验
- 共享领域逻辑集中放在 `src/lib`
- Prisma 访问需要保持明确类型和收敛查询范围

## 高频问题
- 新页面缺少 loading 或 empty state
- 不同 API route 的错误 payload 不一致
- auth 检查放得太靠后，已经进入了请求处理逻辑
- 测试对边界场景缺少回归覆盖
