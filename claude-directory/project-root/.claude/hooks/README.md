# Hooks

这个目录放项目级 hook 示例。

当前模板默认启用的 hook 很克制，只演示一个高价值、低风险的场景：

- 编辑文件后自动格式化

对应脚本是：

- `format-edited-file.mjs`

这个脚本的设计目标是：

- 只处理项目目录内文件
- 只处理受支持的文本类型
- 优先使用项目现有格式化工具链
- 找不到 formatter 时安静退出，不阻塞主流程

## 为什么这里只放轻量 hook

模板仓库的目标是“能直接抄到项目里”，而不是默认接管所有自动化行为。

因此这里优先展示：

- 副作用小
- 团队接受度高
- 失败时容易安全退出

的 hook。

## 目录说明

```text
.claude/hooks/
  README.md
  format-edited-file.mjs
  config/
    hooks-config.json
    hooks-config.local.example.json
  scripts/
    dispatch.mjs
```

其中：

- `format-edited-file.mjs`
  当前已启用的格式化 hook
- `config/hooks-config.json`
  团队共享的 hook 配置示例
- `config/hooks-config.local.example.json`
  本地覆盖配置示例，供个人机器参考
- `scripts/dispatch.mjs`
  一个可选的统一分发入口示例，方便后续扩展更多 hook

## 建议的扩展方式

如果项目后续要增加更多 hook，建议继续遵守下面这些原则：

- 先确认这个动作是否高频且稳定
- 先确认失败时是否可以安全退出
- 先确认它是否真的适合团队共享
- 不要让 hook 默认执行过重的命令

比较适合继续扩展的例子：

- 配置文件变化时提醒检查环境变量
- 轻量级上下文初始化
- 与格式化类似的低风险代码整理动作

不建议默认直接启用的例子：

- 每次改文件都跑整套测试
- 强依赖个人本机路径的脚本
- 会频繁改动大量文件的自动化

## 配置建议

团队共享规则优先放到：

- `.claude/settings.json`
- `config/hooks-config.json`

个人机器专用差异优先放到：

- `.claude/settings.local.json`
- `config/hooks-config.local.example.json` 的本地副本

这样可以让 hook 行为保持可解释、可维护，而不是越用越像黑盒。
