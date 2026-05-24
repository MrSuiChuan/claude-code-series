---
paths:
  - "apps/web/src/**/*.tsx"
---

# 组件模式规则

- 优先编写职责清晰的小组件。
- 只有多个子组件真的需要共享时，才提升 state。
- 组件 props 要明确，并保持收敛的类型边界。
- 不要写那种只是在机械透传大量 props、却没有增加价值的 wrapper component。
- 优先复用设计系统中的共享 token 和 variant，不要随手分叉出一次性样式。
