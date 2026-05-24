---
description: 为 `apps/web` 创建或重构页面与页面级组合。适用于新增页面、布局、loading state 或页面编排，同时遵循项目既有 UI、契约和数据加载约定的场景。
argument-hint: <route-or-screen-name>
---

为 $ARGUMENTS 构建新的前端页面或页面级组合。

执行规则：

1. 在新建内容前，先看 `apps/web` 附近已有的页面和布局
2. 页面涉及数据获取时，优先复用统一 API client 和 `packages/contracts`
3. 页面涉及数据获取时，要补上 loading、empty 和 error state
4. 复用现有 UI 基础组件和设计模式
5. 共享逻辑移到可复用组件或前端共享模块中
6. 总结页面入口、依赖的契约和建议补充的测试
