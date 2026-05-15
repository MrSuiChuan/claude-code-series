# Report Example

下面是 `report` 的典型输出结构。

```markdown
# Claude Code Environment Report

- Generated: 2026-05-15 19:53:54 +08:00
- System: windows
- Architecture: x64
- Version: 2.1.63
- Summary: healthy
- Preferred install method: npm
- Self-test: passed

## Install Methods
- Available: native
- Available: winget
- Available: npm
- Detected: npm

## Claude Paths
- `C:\Users\example\AppData\Roaming\npm\claude`

## Recommendations
- install_claude_code.cmd update -Method npm -DryRun -Yes
- install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes

## Self-Test Checks
- status-state: ok
- doctor-state: ok
- doctor-fix-dryrun: ok
- update-dryrun-plan: ok
- uninstall-dryrun-plan: ok
```

如果你要把这份输出贴到 README、Issue、文章或内部文档里，建议优先用 Markdown 版本。
