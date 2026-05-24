---
description: 分析前后端分离网页系统中的 bug 报告，并收敛到最可能的根因。适用于需要复现问题、追踪 `apps/web`、`packages/contracts`、`apps/api` 和数据库链路，并给出最小安全修复方案的场景。
argument-hint: <bug-summary>
---

正在分析 bug：$ARGUMENTS

处理流程：

1. 先把 bug 描述重新说清楚
2. 找出最可能的入口位置
3. 沿着前端、共享契约、后端和数据层追踪链路
4. 列出最可能的根因
5. 给出最小且安全的修复方案
6. 建议补充一条回归测试
