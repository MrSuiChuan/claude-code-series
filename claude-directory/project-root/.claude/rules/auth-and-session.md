---
paths:
  - "src/**/*auth*.ts"
  - "src/**/*auth*.tsx"
  - "src/**/*session*.ts"
  - "src/**/*session*.tsx"
---

# Auth 与 Session 规则

- auth 和 session 相关代码默认按安全敏感代码处理。
- login、logout、refresh 和权限检查链路要容易追踪。
- 避免会削弱访问控制的静默兜底逻辑。
- secret 和 token 不能进入源码仓库。
- 过期、未授权访问和边界状态切换都要补测试。
