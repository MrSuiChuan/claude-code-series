---
paths:
  - "apps/**/*.{ts,tsx}"
  - "apps/api/database/**/*"
  - "packages/contracts/**/*.{ts,tsx}"
  - ".env*"
---

# 安全与 Secret 规则

- 不要把 secret、token、API key 或私有凭据提交进仓库。
- 不可信输入在进入命令、查询或模板前都要先校验和清洗。
- 文件上传、redirect 和外部 fetch 都要仔细评审。
- 优先使用最小权限原则，并显式写出权限检查。
- 总结和评审时，要单独标出安全敏感改动。
