---
name: paperclip-status
description: 查看 PaperClip 公司实时仪表盘。显示所有 Agent 状态、任务分布、预算使用。
---

# PaperClip 状态仪表盘

快速查看当前 PaperClip 公司的运行状态。

## 执行步骤

1. 检测当前目录下是否存在 `.paperclip/` 目录
2. 如果不存在，提示用户先运行 `/paperclip-orchestrator init`
3. 如果存在：
   - 读取 `.paperclip/agents/*.json` 统计各 agent 状态和完成数
   - 读取 `.paperclip/tasks/*.json` 统计各状态任务数量
   - 读取 `.paperclip/budget.json` 获取预算使用情况
4. 以表格形式输出仪表盘，包含建议的下一步操作
