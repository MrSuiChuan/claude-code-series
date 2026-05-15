# Usage

## 完整枚举值

### PowerShell / CMD 动作枚举

- `install`
- `update`
- `uninstall`
- `status`
- `doctor`
- `migrate`
- `self-test`
- `report`

### PowerShell / CMD 参数枚举

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

### shell 动作枚举

- `install`
- `update`
- `uninstall`
- `status`
- `doctor`
- `migrate`
- `self-test`

### shell 参数枚举

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
- `homebrew` 只适用于 macOS。
- `winget` 只适用于 Windows。
- `apt`、`dnf`、`apk` 只适用于对应的 Linux 发行版。
- shell 入口当前不包含 `report` 动作。

## Windows

### CMD

```bat
REM 按默认推荐方式直接安装 Claude Code
tooling\scripts\install_claude_code.cmd install -Yes
REM 预演通过 npm 更新，不实际执行更新
tooling\scripts\install_claude_code.cmd update -Method npm -DryRun -Yes
REM 预演通过 npm 卸载，不实际执行卸载
tooling\scripts\install_claude_code.cmd uninstall -Method npm -DryRun -Yes
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
```

### PowerShell

```powershell
# 按默认推荐方式直接安装 Claude Code
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" install -Yes
# 预演通过 npm 更新，不实际执行更新
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" update -Method npm -DryRun -Yes
# 预演通过 npm 卸载，不实际执行卸载
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" uninstall -Method npm -DryRun -Yes
# 查看当前安装状态和检测到的安装来源
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" status
# 诊断当前环境并给出后续建议
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Json
# 运行内置自检，并以 JSON 输出检查结果
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json
# 生成可分享的环境摘要报告
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report
# 预演从 npm 迁移到 native，不实际执行迁移
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes
```

## shell

```bash
# 按默认推荐方式直接安装 Claude Code
bash ./tooling/scripts/install_claude_code.sh install --yes
# 预演通过 npm 更新，不实际执行更新
bash ./tooling/scripts/install_claude_code.sh update --method npm --dry-run --yes
# 预演通过 npm 卸载，不实际执行卸载
bash ./tooling/scripts/install_claude_code.sh uninstall --method npm --dry-run --yes
# 查看当前安装状态和检测到的安装来源
bash ./tooling/scripts/install_claude_code.sh status
# 诊断当前环境并给出后续建议
bash ./tooling/scripts/install_claude_code.sh doctor
# 预演低风险修复，不实际修改当前环境
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
# 运行内置自检，并以 JSON 输出检查结果
bash ./tooling/scripts/install_claude_code.sh self-test --json
# 预演从 npm 迁移到 native，不实际执行迁移
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
```

## 推荐顺序

### Windows CMD

1. `tooling\scripts\install_claude_code.cmd doctor`：先诊断环境，确认当前安装状态和建议动作。
2. `tooling\scripts\install_claude_code.cmd doctor -Fix -DryRun`：先预演低风险修复，确认脚本准备怎么修。
3. `tooling\scripts\install_claude_code.cmd self-test`：跑一遍内置自检，确认脚本主流程正常。
4. `tooling\scripts\install_claude_code.cmd report`：生成一份适合分享或留档的环境摘要。
5. `tooling\scripts\install_claude_code.cmd install -Yes`：确认环境没问题后，按默认推荐方式直接安装。
6. `tooling\scripts\install_claude_code.cmd update -Method npm -DryRun -Yes`：先预演通过 npm 更新，避免直接改动。
7. `tooling\scripts\install_claude_code.cmd uninstall -Method npm -DryRun -Yes`：先预演通过 npm 卸载，确认删的是对的安装来源。
8. `tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes`：先预演从 npm 迁移到 native，确认迁移步骤正确。

### PowerShell

1. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor`：先诊断环境，确认当前安装状态和建议动作。
2. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Fix -DryRun`：先预演低风险修复，确认脚本准备怎么修。
3. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json`：跑一遍内置自检，并保留结构化输出。
4. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report`：生成一份适合分享或留档的环境摘要。
5. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" install -Yes`：确认环境没问题后，按默认推荐方式直接安装。
6. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" update -Method npm -DryRun -Yes`：先预演通过 npm 更新，避免直接改动。
7. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" uninstall -Method npm -DryRun -Yes`：先预演通过 npm 卸载，确认删的是对的安装来源。
8. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes`：先预演从 npm 迁移到 native，确认迁移步骤正确。

### shell

1. `bash ./tooling/scripts/install_claude_code.sh doctor`：先诊断环境，确认当前安装状态和建议动作。
2. `bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run`：先预演低风险修复，确认脚本准备怎么修。
3. `bash ./tooling/scripts/install_claude_code.sh self-test --json`：跑一遍内置自检，并保留结构化输出。
4. `bash ./tooling/scripts/install_claude_code.sh install --yes`：确认环境没问题后，按默认推荐方式直接安装。
5. `bash ./tooling/scripts/install_claude_code.sh update --method npm --dry-run --yes`：先预演通过 npm 更新，避免直接改动。
6. `bash ./tooling/scripts/install_claude_code.sh uninstall --method npm --dry-run --yes`：先预演通过 npm 卸载，确认删的是对的安装来源。
7. `bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes`：先预演从 npm 迁移到 native，确认迁移步骤正确。

## 高风险动作说明

- `tooling\scripts\install_claude_code.cmd doctor -Fix`、`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Fix` 和 `bash ./tooling/scripts/install_claude_code.sh doctor --fix` 都不会自动执行安装来源迁移
- 多来源安装只会给出建议，不会直接删改
- 如果你机器上已有旧的 npm 安装，优先先看 `tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes`、`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes` 或 `bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes`
