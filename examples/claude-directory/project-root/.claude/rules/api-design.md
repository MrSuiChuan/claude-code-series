---
paths:
  - "src/api/**/*.ts"
---

# API 设计规则

- 所有接口都用 Zod schema 校验输入
- 返回结构统一为 `{ data: T }` 或 `{ error: string }`
- 对外公开接口必须限流
