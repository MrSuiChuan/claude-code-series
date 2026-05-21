# frontend-reviewer 记忆

## 已观察到的项目模式
- UI 在新增视觉模式前，应先复用共享基础组件
- 可访问性问题常出现在 dialog、表单和自定义按钮上
- 可以使用 Tailwind class，但重复模式应提取到组件中

## 高频问题
- 明明 server component 足够，却新增了 client component
- 缺少 loading、empty 或 error state
- 类似页面之间的响应式间距不一致
