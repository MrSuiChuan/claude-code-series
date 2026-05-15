# Usage

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

## 枚举值

### Windows CMD / Windows PowerShell 动作枚举

- `install`
- `update`
- `uninstall`
- `status`
- `doctor`
- `migrate`
- `self-test`
- `report`

### Windows CMD / Windows PowerShell 参数枚举

- `-Method`: `auto` `native` `winget` `homebrew` `npm`
- `-FromMethod`: `auto` `native` `winget` `homebrew` `npm`
- `-Target`: `stable` `latest` `VERSION`
- `-Force`
- `-Yes`
- `-DryRun`
- `-SkipVerify`
- `-Json`
- `-Fix`
- `-Status`

### macOS Terminal / Linux Terminal / WSL Terminal 动作枚举

- `install`
- `update`
- `uninstall`
- `status`
- `doctor`
- `migrate`
- `self-test`

### macOS Terminal / Linux Terminal / WSL Terminal 参数枚举

- `--method`: `auto` `native` `homebrew` `npm` `apt` `dnf` `apk`
- `--from`: `auto` `native` `homebrew` `npm` `apt` `dnf` `apk`
- `--target`: `stable` `latest` `VERSION`
- `--force`
- `--yes`
- `--dry-run`
- `--skip-verify`
- `--json`
- `--fix`
- `--status`

### 补充说明

- `VERSION` 表示具体版本号，例如 `2.1.63`。
- `report` 只在 `Windows CMD` 和 `Windows PowerShell` 提供。
- `winget` 只适用于 Windows。
- `homebrew` 只适用于 macOS。
- `apt` 适用于 Debian / Ubuntu 及大多数基于它们的 WSL 发行版。
- `dnf` 适用于 Fedora / RHEL / CentOS Stream 一类发行版。
- `apk` 适用于 Alpine Linux。
- 普通终端模式下会输出中文提示和进度信息。
- `-Json` 或 `--json` 模式下会保留机器可读输出，不额外插入普通提示和进度条。

## Windows CMD

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

## Windows PowerShell

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

## macOS Terminal

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

## Linux Terminal

### Debian / Ubuntu

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

### Fedora / RHEL / CentOS Stream

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

### Alpine Linux

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

## WSL Terminal

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

## 推荐顺序

### Windows CMD

1. `tooling\scripts\install_claude_code.cmd doctor`：先诊断环境，确认当前安装状态和建议动作。
2. `tooling\scripts\install_claude_code.cmd doctor -Fix -DryRun`：先预演低风险修复，确认脚本准备怎么修。
3. `tooling\scripts\install_claude_code.cmd self-test`：跑一遍内置自检，确认脚本主流程正常。
4. `tooling\scripts\install_claude_code.cmd report`：生成一份适合分享或留档的环境摘要。
5. `tooling\scripts\install_claude_code.cmd install -Yes`：确认环境没问题后，再按默认推荐方式直接安装。

### Windows PowerShell

1. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor`：先诊断环境，确认当前安装状态和建议动作。
2. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Fix -DryRun`：先预演低风险修复，确认脚本准备怎么修。
3. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json`：跑一遍内置自检，并保留结构化输出。
4. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report`：生成一份适合分享或留档的环境摘要。
5. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" install -Yes`：确认环境没问题后，再按默认推荐方式直接安装。

### macOS Terminal / Linux Terminal / WSL Terminal

1. `bash ./tooling/scripts/install_claude_code.sh doctor`：先诊断环境，确认当前安装状态和建议动作。
2. `bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run`：先预演低风险修复，确认脚本准备怎么修。
3. `bash ./tooling/scripts/install_claude_code.sh self-test --json`：跑一遍内置自检，并保留结构化输出。
4. 再根据你的真实环境选择 `homebrew`、`apt`、`dnf`、`apk` 或 `npm` 去执行安装、更新、卸载、迁移。

## 高风险动作说明

- `doctor -Fix` 或 `doctor --fix` 不会自动做安装来源迁移。
- 多来源安装时，脚本只会给出建议，不会直接删改。
- 真实执行更新、卸载、迁移前，建议先跑同一条命令的预演版本，再去掉 `-DryRun` 或 `--dry-run`。
- 如果你机器上已经有旧的 `npm` 安装，优先先看迁移预演：
  Windows CMD：`tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes`
  Windows PowerShell：`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes`
  macOS Terminal / Linux Terminal / WSL Terminal：`bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes`
