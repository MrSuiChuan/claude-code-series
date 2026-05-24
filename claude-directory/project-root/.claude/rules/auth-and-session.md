---
paths:
  - "apps/web/src/**/*auth*.ts"
  - "apps/web/src/**/*auth*.tsx"
  - "apps/web/src/**/*session*.ts"
  - "apps/web/src/**/*session*.tsx"
  - "apps/api/src/**/*auth*.ts"
  - "apps/api/src/**/*auth*.tsx"
  - "apps/api/src/**/*session*.ts"
  - "apps/api/src/**/*session*.tsx"
---

# Auth 与 Session 规则

- auth 和 session 相关代码默认按安全敏感代码处理。
- login、logout、refresh 和权限检查链路要容易追踪。
- 前端会话状态和后端访问控制要保持语义一致，不要只在一侧修补。
- 避免会削弱访问控制的静默兜底逻辑。
- secret 和 token 不能进入源码仓库。
- 过期、未授权访问和边界状态切换都要补测试。
