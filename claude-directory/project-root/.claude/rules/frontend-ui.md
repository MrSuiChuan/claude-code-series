---
paths:
  - "apps/web/src/**/*.tsx"
  - "apps/web/src/**/*.ts"
---

# 前端 UI 规则

- 在新增视觉模式前，先复用现有 layout 和 UI 基础组件。
- 样式组织要保持可读，重复模式要提取到组件或 helper 中。
- loading、empty、success 和 error state 都要显式处理。
- 不要把只适用于服务端的逻辑泄露到 client component。
- 同时兼顾桌面端和移动端的响应式表现。
