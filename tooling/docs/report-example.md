# Report Example

下面是 `report` 的典型输出结构。

```markdown
# Claude Code 环境报告

- 生成时间：2026-05-15 19:53:54 +08:00
- 系统：windows
- 架构：x64
- 版本：2.1.63
- 诊断结论：正常
- 推荐安装方式：npm
- 自检结果：通过

## 安装方式
- 可用：native
- 可用：winget
- 可用：npm
- 已检测到：npm

## Claude Paths
- `C:\Users\example\AppData\Roaming\npm\claude`

## 建议
- install_claude_code.cmd update -Method npm -DryRun -Yes
- install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes

## 自检项
- 状态信息检查：通过
- 环境诊断检查：通过
- 诊断修复预演检查：通过
- 更新计划预演检查：通过
- 卸载计划预演检查：通过
```

如果你要把这份输出贴到 README、Issue、文章或内部文档里，建议优先用 Markdown 版本。
