---
description: 评审数据库 schema 或 migration 改动的安全性和可运维性。适用于检查 Prisma schema 变更、自动生成的 migration、数据回填或 seed 调整中的破坏性步骤、事务风险和上线风险。
argument-hint: <migration-or-schema-path>
---

评审 $ARGUMENTS 的数据库改动。

重点检查：

1. 是否存在破坏性 migration 步骤
2. 是否需要数据回填
3. 事务和锁风险
4. 对索引的影响
5. 回滚或恢复风险
6. 测试环境或预发验证需求
