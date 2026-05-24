---
paths:
  - "apps/api/src/**/*.ts"
  - "apps/api/src/**/*.tsx"
---

# API 设计规则

- 所有请求输入都要用 Zod schema 或等价运行时校验方式处理。
- 不同 route 的响应结构要保持一致。
- 使用明确的 HTTP status code 和稳定的错误 payload。
- 认证和授权要在进入业务逻辑前完成。
- 优先复用 `packages/contracts` 中的共享契约，不要在前后端各写一套接口形状。
- 对公开接口和敏感写接口做好限流。
