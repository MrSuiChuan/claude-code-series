---
paths:
  - "apps/web/src/**/*.{ts,tsx}"
  - "packages/contracts/**/*.{ts,tsx}"
---

# 状态与数据获取规则

- 只要可行，数据获取就放在前端页面边界或后端服务边界附近。
- 只有交互或实时更新确实需要时，才使用客户端获取数据。
- 前端请求优先通过共享契约和统一 API client 发往后端。
- cache key 和失效策略要保持一致。
- 不要在多个 store 里重复维护同一份获取结果。
- 在 UI 中把 loading 和 refetch state 清楚展示出来。
