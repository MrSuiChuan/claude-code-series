# Prisma 与数据库规则

- `apps/api/prisma` 下的 schema、migration 和 seed 都按高风险改动评审。
- 相比破坏性重写，优先做增量 migration、明确的数据回填和可恢复方案。
- 查询范围保持收敛，只选择调用方真正需要的数据。
- 调整数据流时，要顺手检查事务边界、N+1 和索引问题。
- 除非任务明确要求，否则避免破坏性 migration。
