---
argument-hint: <user-action-or-endpoint>
---

追踪 $ARGUMENTS 的端到端请求链路。

需要包含：

1. UI 或 route 层的入口位置
2. 校验和 auth 检查
3. service 或领域逻辑
4. 数据库读写路径
5. 错误处理和日志记录
6. 覆盖这条链路的测试
