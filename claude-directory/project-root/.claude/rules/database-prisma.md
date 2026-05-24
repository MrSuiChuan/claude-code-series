---
paths:
  - "apps/api/prisma/**/*"
  - "apps/api/src/**/*prisma*.ts"
  - "apps/api/src/**/*db*.ts"
---

# 数据库与 Prisma 规则

- 修改 schema、migration 和 seed 前要先认真评审。
- 相比破坏性重写，优先做增量 migration 和明确的数据回填。
- 查询要保持明确类型和收敛范围，只选择调用方真正需要的数据。
- 新增访问路径时，要顺手检查事务安全、N+1 和缺失索引问题。
- 不要硬编码凭据或连接串。
