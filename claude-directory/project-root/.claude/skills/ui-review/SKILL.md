---
description: 评审 `apps/web` 中的前端实现质量。适用于在实现前后检查 UI 改动的一致性、可访问性、响应式表现、loading state 和多余客户端复杂度的场景。
argument-hint: <path-or-screen>
---

评审 $ARGUMENTS 的 UI 实现。

重点检查：

1. 布局和视觉一致性
2. 响应式表现
3. 可访问性和键盘支持
4. loading、empty 和 error state
5. 前端交互层是否承担了过多复杂度，或是否重复编排了视图逻辑

输出时先给问题，并附带具体修复建议。
