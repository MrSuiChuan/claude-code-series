---
description: 为 React/Next.js 风格的网页系统创建或重构页面与 route segment。适用于新增页面、layout、route segment、loading state 或页面级组合，同时遵循项目既有 UI 和数据加载约定的场景。
argument-hint: <route-or-screen-name>
---

为 $ARGUMENTS 构建新的页面或 route segment。

执行规则：

1. 在新建内容前，先看附近已有的 route 和 layout
2. 默认优先使用 server component
3. 页面涉及数据获取时，要补上 loading、empty 和 error state
4. 复用现有 UI 基础组件和设计模式
5. 共享逻辑移到 `src/lib` 或可复用组件中
6. 总结 route 入口和建议补充的测试
