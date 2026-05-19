---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
---

# 测试规则

- 测试名要完整表达场景和预期结果
- 优先 mock 外部依赖，不要 mock 内部实现
- 在 `afterEach` 中清理副作用
