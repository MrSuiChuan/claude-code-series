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

## 按环境完整命令清单

### Windows CMD

```bat
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
REM 预演从 npm 迁移到 native，不实际执行迁移
tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes
REM 从 npm 真实迁移到 native
tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -Yes
```

### Windows PowerShell

```powershell
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
# 查看当前安装状态和检测到的安装来源
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" status
# 诊断当前环境并给出后续建议
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor
# 预演低风险修复，不实际修改当前环境
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Fix -DryRun
# 运行内置自检，并保留 JSON 结构化结果
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json
# 生成可分享的环境摘要报告
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report
# 预演从 npm 迁移到 native，不实际执行迁移
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes
# 从 npm 真实迁移到 native
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -Yes
```

### macOS Terminal

```bash
# 按默认推荐方式直接安装 Claude Code
bash ./tooling/scripts/install_claude_code.sh install --yes
# 预演通过 homebrew 更新，不实际执行更新
bash ./tooling/scripts/install_claude_code.sh update --method homebrew --dry-run --yes
# 通过 homebrew 真实执行更新
bash ./tooling/scripts/install_claude_code.sh update --method homebrew --yes
# 预演通过 homebrew 卸载，不实际执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method homebrew --dry-run --yes
# 通过 homebrew 真实执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method homebrew --yes
# 查看当前安装状态和检测到的安装来源
bash ./tooling/scripts/install_claude_code.sh status
# 诊断当前环境并给出后续建议
bash ./tooling/scripts/install_claude_code.sh doctor
# 预演低风险修复，不实际修改当前环境
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
# 运行内置自检，并保留 JSON 结构化结果
bash ./tooling/scripts/install_claude_code.sh self-test --json
# 预演从 npm 迁移到 native，不实际执行迁移
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
# 从 npm 真实迁移到 native
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --yes
```

当前 `macOS Terminal` 入口不支持 `report`。如果你的 macOS 环境不是通过 `homebrew` 安装，而是通过 `npm` 安装，把上面命令里的 `--method homebrew` 改成 `--method npm` 即可。

### Linux Terminal

#### Debian / Ubuntu

```bash
# 按默认推荐方式直接安装 Claude Code
bash ./tooling/scripts/install_claude_code.sh install --yes
# 预演通过 apt 更新，不实际执行更新
bash ./tooling/scripts/install_claude_code.sh update --method apt --dry-run --yes
# 通过 apt 真实执行更新
bash ./tooling/scripts/install_claude_code.sh update --method apt --yes
# 预演通过 apt 卸载，不实际执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method apt --dry-run --yes
# 通过 apt 真实执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method apt --yes
# 查看当前安装状态和检测到的安装来源
bash ./tooling/scripts/install_claude_code.sh status
# 诊断当前环境并给出后续建议
bash ./tooling/scripts/install_claude_code.sh doctor
# 预演低风险修复，不实际修改当前环境
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
# 运行内置自检，并保留 JSON 结构化结果
bash ./tooling/scripts/install_claude_code.sh self-test --json
# 预演从 npm 迁移到 native，不实际执行迁移
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
# 从 npm 真实迁移到 native
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --yes
```

#### Fedora / RHEL / CentOS Stream

```bash
# 按默认推荐方式直接安装 Claude Code
bash ./tooling/scripts/install_claude_code.sh install --yes
# 预演通过 dnf 更新，不实际执行更新
bash ./tooling/scripts/install_claude_code.sh update --method dnf --dry-run --yes
# 通过 dnf 真实执行更新
bash ./tooling/scripts/install_claude_code.sh update --method dnf --yes
# 预演通过 dnf 卸载，不实际执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method dnf --dry-run --yes
# 通过 dnf 真实执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method dnf --yes
# 查看当前安装状态和检测到的安装来源
bash ./tooling/scripts/install_claude_code.sh status
# 诊断当前环境并给出后续建议
bash ./tooling/scripts/install_claude_code.sh doctor
# 预演低风险修复，不实际修改当前环境
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
# 运行内置自检，并保留 JSON 结构化结果
bash ./tooling/scripts/install_claude_code.sh self-test --json
# 预演从 npm 迁移到 native，不实际执行迁移
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
# 从 npm 真实迁移到 native
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --yes
```

#### Alpine Linux

```bash
# 按默认推荐方式直接安装 Claude Code
bash ./tooling/scripts/install_claude_code.sh install --yes
# 预演通过 apk 更新，不实际执行更新
bash ./tooling/scripts/install_claude_code.sh update --method apk --dry-run --yes
# 通过 apk 真实执行更新
bash ./tooling/scripts/install_claude_code.sh update --method apk --yes
# 预演通过 apk 卸载，不实际执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method apk --dry-run --yes
# 通过 apk 真实执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method apk --yes
# 查看当前安装状态和检测到的安装来源
bash ./tooling/scripts/install_claude_code.sh status
# 诊断当前环境并给出后续建议
bash ./tooling/scripts/install_claude_code.sh doctor
# 预演低风险修复，不实际修改当前环境
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
# 运行内置自检，并保留 JSON 结构化结果
bash ./tooling/scripts/install_claude_code.sh self-test --json
# 预演从 npm 迁移到 native，不实际执行迁移
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
# 从 npm 真实迁移到 native
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --yes
```

当前 `Linux Terminal` 入口不支持 `report`。

### WSL Terminal

```bash
# 按默认推荐方式在 WSL 内安装 Claude Code
bash ./tooling/scripts/install_claude_code.sh install --method apt --yes
# 预演通过 apt 更新，不实际执行更新
bash ./tooling/scripts/install_claude_code.sh update --method apt --dry-run --yes
# 通过 apt 真实执行更新
bash ./tooling/scripts/install_claude_code.sh update --method apt --yes
# 预演通过 apt 卸载，不实际执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method apt --dry-run --yes
# 通过 apt 真实执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method apt --yes
# 查看当前安装状态和检测到的安装来源
bash ./tooling/scripts/install_claude_code.sh status
# 诊断当前环境并给出后续建议
bash ./tooling/scripts/install_claude_code.sh doctor
# 预演低风险修复，不实际修改当前环境
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
# 运行内置自检，并保留 JSON 结构化结果
bash ./tooling/scripts/install_claude_code.sh self-test --json
# 预演从 npm 迁移到 native，不实际执行迁移
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
# 从 npm 真实迁移到 native
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --yes
```

当前 `WSL Terminal` 入口不支持 `report`。如果 `WSL Terminal` 里检测到的是 Windows 版本的 `claude`，请改用 `Windows CMD` 或 `Windows PowerShell` 命令管理它，不要在 WSL 里直接卸载或迁移 Windows 安装。

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
