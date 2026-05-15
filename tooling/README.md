# Claude Code Tooling

这一套工具用于管理 Claude Code 的安装生命周期，目标是把常见操作收敛成一组尽量短、尽量稳的命令。

## 包含内容

- `scripts/install_claude_code.ps1`
  Windows 优先入口

- `scripts/install_claude_code.cmd`
  Windows 便捷入口

- `scripts/install_claude_code.sh`
  macOS、Linux、WSL 的 shell 入口

- `docs/usage.md`
  用法说明

- `docs/report-example.md`
  `report` 输出示例

## 主要能力

- `install`
- `update`
- `uninstall`
- `status`
- `doctor`
- `doctor fix`
- `self-test`
- `report`

## 命令枚举值

### PowerShell / CMD 动作枚举

- `install`
- `update`
- `uninstall`
- `status`
- `doctor`
- `migrate`
- `self-test`
- `report`

### PowerShell / CMD `-Method` 枚举

- `auto`
- `native`
- `winget`
- `homebrew`
- `npm`

### PowerShell / CMD `-FromMethod` 枚举

- `auto`
- `native`
- `winget`
- `homebrew`
- `npm`

### shell 动作枚举

- `install`
- `update`
- `uninstall`
- `status`
- `doctor`
- `migrate`
- `self-test`

### shell `--method` 枚举

- `auto`
- `native`
- `homebrew`
- `npm`
- `apt`
- `dnf`
- `apk`

### shell `--from` 枚举

- `auto`
- `native`
- `homebrew`
- `npm`
- `apt`
- `dnf`
- `apk`

### 通用目标版本枚举

- `stable`
- `latest`
- `VERSION`

其中 `VERSION` 表示明确的版本号，例如 `2.1.63`。

### PowerShell / CMD 开关参数

- `-Force`
- `-Yes`
- `-DryRun`
- `-SkipVerify`
- `-Json`
- `-Fix`
- `-Status`

### shell 开关参数

- `--force`
- `--yes`
- `--dry-run`
- `--skip-verify`
- `--json`
- `--fix`
- `--status`

## 入口差异

- `report` 目前是 PowerShell / CMD 入口提供的动作。
- shell 入口当前不包含 `report` 动作，文档中的 shell 示例只覆盖它已经实现的动作。
- `homebrew` 只在 macOS 场景下有意义，`winget` 只在 Windows 场景下有意义。
- `apt`、`dnf`、`apk` 只在对应 Linux 发行版下有意义。

## 完整命令清单

### Windows

```bat
tooling\scripts\install_claude_code.cmd status
tooling\scripts\install_claude_code.cmd doctor
tooling\scripts\install_claude_code.cmd doctor -Fix -DryRun
tooling\scripts\install_claude_code.cmd self-test
tooling\scripts\install_claude_code.cmd report
tooling\scripts\install_claude_code.cmd install -Yes
tooling\scripts\install_claude_code.cmd update -Method npm -DryRun -Yes
tooling\scripts\install_claude_code.cmd uninstall -Method npm -DryRun -Yes
tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes
```

### PowerShell

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" status
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Fix -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" install -Yes
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" update -Method npm -DryRun -Yes
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" uninstall -Method npm -DryRun -Yes
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes
```

### shell

```bash
bash ./tooling/scripts/install_claude_code.sh status
bash ./tooling/scripts/install_claude_code.sh doctor
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
bash ./tooling/scripts/install_claude_code.sh install --yes
bash ./tooling/scripts/install_claude_code.sh update --method npm --dry-run --yes
bash ./tooling/scripts/install_claude_code.sh uninstall --method npm --dry-run --yes
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
bash ./tooling/scripts/install_claude_code.sh self-test --json
```

## 说明

- Windows CMD 默认推荐先跑 `tooling\scripts\install_claude_code.cmd doctor`
- PowerShell 默认推荐先跑 `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor`
- shell 默认推荐先跑 `bash ./tooling/scripts/install_claude_code.sh doctor`
- Windows CMD 自动化校验推荐使用 `tooling\scripts\install_claude_code.cmd self-test`
- PowerShell 自动化校验推荐使用 `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json`
- shell 自动化校验推荐使用 `bash ./tooling/scripts/install_claude_code.sh self-test --json`
- 需要生成可分享摘要时，使用 `tooling\scripts\install_claude_code.cmd report` 或 `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report`
- 多来源安装时，优先先跑 `tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes`、`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes` 或 `bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes`
