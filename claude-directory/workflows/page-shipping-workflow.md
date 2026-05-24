# Page Shipping Workflow

这份文档说明前后端分离网页系统里，一个页面从“提出需求”到“可以交付评审”的推荐流程。

它不是在替代项目自己的开发流程，而是在说明当前 `claude-directory` 这套 `command`、`agent`、`skill` 配置应该如何协作。

## 目标

页面交付不只是把 UI 结构拼出来，还包括：

- 沿用 `apps/web` 里的已有页面模式
- 通过共享契约和统一 API client 正确拿数
- 状态完整
- 响应式可用
- 可访问性不过关的地方尽量提前发现
- 输出结果足够容易进入后续评审和联调

## 推荐组合

- `workflows/ship-page`
- `scaffold-page`
- `ui-review`
- `accessibility-reviewer`

## 推荐流程

### 阶段 1：理解附近模式

先看清楚：

- `apps/web` 里相邻页面和 layout
- 现有组件组织方式
- 视觉和交互模式
- 是否已经有对应的共享契约和 API client

### 阶段 2：生成页面骨架

由 `ship-page` 调用 `scaffold-page`，完成页面的第一版结构。

这一步应该优先保证：

- 页面入口位置正确
- 复用现有布局和基础组件
- 数据请求优先走统一 API client 和 `packages/contracts`
- 不为单个页面发明新的架构层

### 阶段 3：补全页面状态

至少要显式考虑：

- loading state
- empty state
- error state
- 权限受限或未登录状态

### 阶段 4：做 UI 质量检查

由 `ship-page` 调用 `ui-review`，重点检查：

- 与附近页面的视觉一致性
- 响应式表现
- 过度客户端化的问题
- 重复视图逻辑
- 状态呈现是否完整

### 阶段 5：做可访问性检查

由 `ship-page` 调用 `accessibility-reviewer`，重点检查：

- 语义结构
- 键盘操作
- 焦点顺序
- 表单控件可读性
- 交互反馈是否足够明确

### 阶段 6：输出交付总结

最后统一输出：

- 页面入口和主要改动点
- 依赖的共享契约
- 还需要补的测试
- 仍未覆盖的风险

## 工作流示意

```text
User Request
  -> ship-page (command)
  -> scaffold-page (skill)
  -> ui-review (skill)
  -> accessibility-reviewer (agent)
  -> Delivery Summary
```

## 总结

这个 workflow 的核心价值，不是让页面开发“更复杂”，而是让页面从一开始就朝着“可交付”推进，并始终记得前端不是孤立存在的，而是依赖后端和共享契约协作。
