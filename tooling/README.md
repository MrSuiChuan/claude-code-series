# Claude Code Tooling

这一套工具用于管理 Claude Code 的完整生命周期，包括安装、更新、卸载、迁移、诊断、自检和报告生成。文档里的环境名称统一按真实终端环境来写，不再把 `bash` 或 `shell` 当成环境名。

## 包含内容

- `scripts/install_claude_code.ps1`
  Windows PowerShell 入口

- `scripts/install_claude_code.cmd`
  Windows CMD 入口

- `scripts/install_claude_code.sh`
  macOS Terminal、Linux Terminal、WSL Terminal 入口

- `docs/usage.md`
  完整命令清单、枚举值说明、按环境拆分的示例

- `docs/report-example.md`
  `report` 输出示例

## 环境与入口

- `Windows CMD`
  使用 `tooling\scripts\install_claude_code.cmd`

- `Windows PowerShell`
  使用 `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1"`

- `macOS Terminal`
  使用 `bash ./tooling/scripts/install_claude_code.sh`

- `Linux Terminal`
  使用 `bash ./tooling/scripts/install_claude_code.sh`

- `WSL Terminal`
  使用 `bash ./tooling/scripts/install_claude_code.sh`

## 主要能力

- `install`
- `update`
- `uninstall`
- `status`
- `doctor`
- `migrate`
- `self-test`
- `report`

## 环境差异

- `report` 目前只在 `Windows CMD` 和 `Windows PowerShell` 入口提供。
- `winget` 只在 Windows 场景下有意义。
- `homebrew` 只在 macOS 场景下有意义。
- `apt` 适用于 Debian / Ubuntu 及大多数基于它们的 WSL 发行版。
- `dnf` 适用于 Fedora / RHEL / CentOS Stream 一类发行版。
- `apk` 适用于 Alpine Linux。
- `WSL Terminal` 下如果脚本检测到 PATH 里是 Windows 版本的 `claude`，会明确提示优先改用 Windows 入口管理。

## 快速开始

### Windows CMD

```bat
REM 先诊断当前环境和安装状态
tooling\scripts\install_claude_code.cmd doctor
REM 再跑一遍脚本自检，确认主流程正常
tooling\scripts\install_claude_code.cmd self-test
REM 生成一份可分享的环境报告
tooling\scripts\install_claude_code.cmd report
```

### Windows PowerShell

```powershell
# 先诊断当前环境和安装状态
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor
# 再跑一遍脚本自检，保留结构化输出
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json
# 生成一份可分享的环境报告
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report
```

### macOS Terminal

```bash
# 先诊断当前环境和安装状态
bash ./tooling/scripts/install_claude_code.sh doctor
# 再跑一遍脚本自检，保留结构化输出
bash ./tooling/scripts/install_claude_code.sh self-test --json
```

### Linux Terminal

```bash
# 先诊断当前环境和安装状态
bash ./tooling/scripts/install_claude_code.sh doctor
# 再跑一遍脚本自检，保留结构化输出
bash ./tooling/scripts/install_claude_code.sh self-test --json
```

### WSL Terminal

```bash
# 先诊断当前环境和安装状态
bash ./tooling/scripts/install_claude_code.sh doctor
# 再跑一遍脚本自检，保留结构化输出
bash ./tooling/scripts/install_claude_code.sh self-test --json
```

## 命令枚举值

### Windows CMD / Windows PowerShell

- 动作枚举：`install` `update` `uninstall` `status` `doctor` `migrate` `self-test` `report`
- `-Method` 枚举：`auto` `native` `winget` `homebrew` `npm`
- `-FromMethod` 枚举：`auto` `native` `winget` `homebrew` `npm`
- `-Target` 枚举：`stable` `latest` `VERSION`
- 开关参数：`-Force` `-Yes` `-DryRun` `-SkipVerify` `-Json` `-Fix` `-Status`

### macOS Terminal / Linux Terminal / WSL Terminal

- 动作枚举：`install` `update` `uninstall` `status` `doctor` `migrate` `self-test`
- `--method` 枚举：`auto` `native` `homebrew` `npm` `apt` `dnf` `apk`
- `--from` 枚举：`auto` `native` `homebrew` `npm` `apt` `dnf` `apk`
- `--target` 枚举：`stable` `latest` `VERSION`
- 开关参数：`--force` `--yes` `--dry-run` `--skip-verify` `--json` `--fix` `--status`

其中 `VERSION` 表示明确的版本号，例如 `2.1.63`。

## 输出说明

- 普通终端模式下，脚本会输出中文提示，并在关键阶段显示进度信息。
- `-Json` 或 `--json` 模式下，脚本会保留机器可读输出，不额外插入普通提示和进度条。

## 继续查看

- 详细命令说明见 [docs/usage.md](./docs/usage.md)
- `report` 示例见 [docs/report-example.md](./docs/report-example.md)
