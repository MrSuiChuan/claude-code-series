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

## 带注释完整命令清单

### Windows

```bat
REM 查看当前安装状态和检测到的安装来源
tooling\scripts\install_claude_code.cmd status
REM 诊断当前环境并给出后续建议
tooling\scripts\install_claude_code.cmd doctor
REM 预演低风险修复，不实际修改当前环境
tooling\scripts\install_claude_code.cmd doctor -Fix -DryRun
REM 运行内置自检，快速验证脚本主流程
tooling\scripts\install_claude_code.cmd self-test
REM 生成可分享的环境摘要报告
tooling\scripts\install_claude_code.cmd report
REM 按默认推荐方式直接安装 Claude Code
tooling\scripts\install_claude_code.cmd install -Yes
REM 预演通过 npm 更新，不实际执行更新
tooling\scripts\install_claude_code.cmd update -Method npm -DryRun -Yes
REM 通过 npm 真实执行更新
tooling\scripts\install_claude_code.cmd update -Method npm -Yes
REM 预演通过 npm 卸载，不实际执行卸载
tooling\scripts\install_claude_code.cmd uninstall -Method npm -DryRun -Yes
REM 通过 npm 真实执行卸载
tooling\scripts\install_claude_code.cmd uninstall -Method npm -Yes
REM 预演从 npm 迁移到 native，不实际执行迁移
tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes
REM 从 npm 真实迁移到 native
tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -Yes
```

### PowerShell

```powershell
# 查看当前安装状态和检测到的安装来源
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" status
# 诊断当前环境并给出后续建议
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor
# 预演低风险修复，不实际修改当前环境
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Fix -DryRun
# 运行内置自检，并以 JSON 输出检查结果
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json
# 生成可分享的环境摘要报告
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report
# 按默认推荐方式直接安装 Claude Code
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" install -Yes
# 预演通过 npm 更新，不实际执行更新
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" update -Method npm -DryRun -Yes
# 通过 npm 真实执行更新
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" update -Method npm -Yes
# 预演通过 npm 卸载，不实际执行卸载
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" uninstall -Method npm -DryRun -Yes
# 通过 npm 真实执行卸载
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" uninstall -Method npm -Yes
# 预演从 npm 迁移到 native，不实际执行迁移
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes
# 从 npm 真实迁移到 native
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -Yes
```

### shell

```bash
# 查看当前安装状态和检测到的安装来源
bash ./tooling/scripts/install_claude_code.sh status
# 诊断当前环境并给出后续建议
bash ./tooling/scripts/install_claude_code.sh doctor
# 预演低风险修复，不实际修改当前环境
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
# 按默认推荐方式直接安装 Claude Code
bash ./tooling/scripts/install_claude_code.sh install --yes
# 预演通过 npm 更新，不实际执行更新
bash ./tooling/scripts/install_claude_code.sh update --method npm --dry-run --yes
# 通过 npm 真实执行更新
bash ./tooling/scripts/install_claude_code.sh update --method npm --yes
# 预演通过 npm 卸载，不实际执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method npm --dry-run --yes
# 通过 npm 真实执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method npm --yes
# 预演从 npm 迁移到 native，不实际执行迁移
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
# 从 npm 真实迁移到 native
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --yes
# 运行内置自检，并以 JSON 输出检查结果
bash ./tooling/scripts/install_claude_code.sh self-test --json
```

## 说明

- Windows CMD 默认推荐先跑 `tooling\scripts\install_claude_code.cmd doctor`
- PowerShell 默认推荐先跑 `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor`
- shell 默认推荐先跑 `bash ./tooling/scripts/install_claude_code.sh doctor`
- Windows CMD 自动化校验推荐使用 `tooling\scripts\install_claude_code.cmd self-test`
- PowerShell 自动化校验推荐使用 `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json`
- shell 自动化校验推荐使用 `bash ./tooling/scripts/install_claude_code.sh self-test --json`
- 如果你已经确认预演结果没问题，去掉 Windows PowerShell / CMD 里的 `-DryRun` 或 shell 里的 `--dry-run`，就是对应的真实执行命令
- 需要生成可分享摘要时，使用 `tooling\scripts\install_claude_code.cmd report` 或 `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report`
- 多来源安装时，优先先跑 `tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes`、`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes` 或 `bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes`
