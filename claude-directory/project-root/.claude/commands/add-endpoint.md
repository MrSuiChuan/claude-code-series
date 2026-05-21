---
argument-hint: <feature-or-route-name>
---

为 $ARGUMENTS 设计并实现一个新的 API endpoint。

检查清单：

1. 确认 route 所在位置，以及请求和响应结构
2. 用 Zod 完成输入校验
3. 按需要补上 auth 和权限检查
4. 实现 handler 和领域逻辑
5. 新增或更新测试
6. 总结是否还需要补 schema、文档或客户端改动
