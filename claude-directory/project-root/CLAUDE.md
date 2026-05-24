# 前后端分离单仓项目约定

## 项目形态
- 这是一个基于 TypeScript 的现代网页系统 monorepo。
- 默认结构为 `apps/web`、`apps/api`、`packages/contracts` 和 `tests/e2e`。
- 前端默认使用 React，后端默认使用 Node.js + TypeScript，运行时校验使用 Zod，数据库访问使用 Prisma，测试使用 Playwright 和 Vitest。
- 优先沿用现有项目模式，不轻易引入新的抽象层。

## 主要工作方式
- 修改前先看清楚相关模块的现有实现。
- 改动尽量小、尽量集中，方便评审和回滚。
- 实现完成后，先跑最小范围的有效验证，再按需要扩大验证范围。
- 如果任务会跨多个区域，先给出一个简短计划再动手。

## 常用命令
- 安装依赖：`pnpm install`
- 启动开发环境：`pnpm dev`
- 运行类型检查：`pnpm typecheck`
- 运行 lint：`pnpm lint`
- 运行单元测试：`pnpm test`
- 运行 E2E 测试：`pnpm test:e2e`
- 构建生产包：`pnpm build`
- 在开发环境执行数据库迁移：`pnpm --filter api prisma migrate dev`

## 架构边界
- `apps/web` 只负责页面、组件、浏览器交互和前端状态编排。
- `apps/api` 只负责请求边界、auth、业务逻辑、数据库访问和第三方集成。
- `packages/contracts` 放前后端共享的 schema、DTO 和类型，是接口契约的单一事实来源。
- 数据库 schema 和 migration 放在 `apps/api/prisma`。
- 端到端流程测试放在 `tests/e2e`。

## 编码规则
- 优先使用 named export。
- 对外暴露的函数、接口边界和共享工具优先写清楚显式类型。
- 新增 helper 之前，先复用现有工具函数。
- 副作用逻辑尽量放在系统边界附近。
- 不要把只适合服务端运行的代码混进前端应用。
- 除非项目已经在用，或当前需求确实需要，否则不要新增依赖。

## 数据与 API 规则
- 所有不可信输入都要用 Zod 或等价 schema 做校验。
- API 返回结构和错误处理方式保持一致。
- auth、权限校验和限流逻辑要清晰地放在后端请求边界上。
- 契约变更时，同时检查前端调用方、共享 schema 和后端实现。
- 不要把关键业务逻辑藏在 UI 组件内部。

## 测试规则
- 只要可行，行为变化都应补充或更新测试。
- 领域逻辑优先使用单元测试或集成测试，关键用户链路优先使用 Playwright。
- 测试名称要能准确描述场景和预期结果。
- 修复 bug 时，补上能证明修复生效的最小回归测试。

## 评审检查项
- 这次改动是否遵循了附近文件已有的实现模式？
- loading、error 和 empty state 是否都处理到了？
- auth 和权限校验是否仍然正确？
- 类型、校验和测试是否与行为变化保持一致？
- 契约变更是否同步检查了 `apps/web`、`packages/contracts` 和 `apps/api`？
- 有没有更简单、涉及更少环节的实现方式？
