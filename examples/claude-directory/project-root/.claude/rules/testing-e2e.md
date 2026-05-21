---
paths:
  - "tests/e2e/**/*.ts"
  - "tests/e2e/**/*.tsx"
---

# E2E 测试规则

- 优先使用用户可见的 selector，再考虑 test id。
- 测试流程要能承受时间波动和轻微 UI 改动。
- 复用 fixture、auth 初始化和 helper，减少重复。
- 避免大范围 sleep，尽量等待稳定信号。
- 新增回归测试时，要把失败场景写清楚。
