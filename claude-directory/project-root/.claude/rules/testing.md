---
paths:
  - "apps/**/*.test.ts"
  - "apps/**/*.test.tsx"
  - "apps/**/*.spec.ts"
  - "apps/**/*.spec.tsx"
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
---

# 测试规则

- 测试名称要能描述场景和预期结果。
- 优先测试行为，而不是实现细节。
- 优先 mock 外部服务，再考虑 mock 内部模块。
- 在 `afterEach` 中清理副作用。
- 契约变更时，要同步检查前端和后端测试是否都需要调整。
- 修复 bug 时，补上能证明修复生效的最小回归测试。
