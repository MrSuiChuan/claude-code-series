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
tooling\scripts\install_claude_code.cmd install -Yes
tooling\scripts\install_claude_code.cmd update -Method npm -DryRun -Yes
tooling\scripts\install_claude_code.cmd uninstall -Method npm -DryRun -Yes
tooling\scripts\install_claude_code.cmd status
tooling\scripts\install_claude_code.cmd doctor
tooling\scripts\install_claude_code.cmd doctor -Fix -DryRun
tooling\scripts\install_claude_code.cmd self-test
tooling\scripts\install_claude_code.cmd report
tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes
```

### PowerShell

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" install -Yes
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" update -Method npm -DryRun -Yes
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" uninstall -Method npm -DryRun -Yes
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" status
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Json
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes
```

## shell

```bash
bash ./tooling/scripts/install_claude_code.sh install --yes
bash ./tooling/scripts/install_claude_code.sh update --method npm --dry-run --yes
bash ./tooling/scripts/install_claude_code.sh uninstall --method npm --dry-run --yes
bash ./tooling/scripts/install_claude_code.sh status
bash ./tooling/scripts/install_claude_code.sh doctor
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
bash ./tooling/scripts/install_claude_code.sh self-test --json
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
```

## 推荐顺序

### Windows CMD

1. `tooling\scripts\install_claude_code.cmd doctor`
2. `tooling\scripts\install_claude_code.cmd doctor -Fix -DryRun`
3. `tooling\scripts\install_claude_code.cmd self-test`
4. `tooling\scripts\install_claude_code.cmd report`
5. `tooling\scripts\install_claude_code.cmd install -Yes`、`tooling\scripts\install_claude_code.cmd update -Method npm -DryRun -Yes`、`tooling\scripts\install_claude_code.cmd uninstall -Method npm -DryRun -Yes` 或 `tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes`

### PowerShell

1. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Fix -DryRun`
3. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json`
4. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report`
5. `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" install -Yes`、`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" update -Method npm -DryRun -Yes`、`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" uninstall -Method npm -DryRun -Yes` 或 `powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes`

### shell

1. `bash ./tooling/scripts/install_claude_code.sh doctor`
2. `bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run`
3. `bash ./tooling/scripts/install_claude_code.sh self-test --json`
4. `bash ./tooling/scripts/install_claude_code.sh install --yes`、`bash ./tooling/scripts/install_claude_code.sh update --method npm --dry-run --yes`、`bash ./tooling/scripts/install_claude_code.sh uninstall --method npm --dry-run --yes` 或 `bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes`

## 高风险动作说明

- `tooling\scripts\install_claude_code.cmd doctor -Fix`、`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Fix` 和 `bash ./tooling/scripts/install_claude_code.sh doctor --fix` 都不会自动执行安装来源迁移
- 多来源安装只会给出建议，不会直接删改
- 如果你机器上已有旧的 npm 安装，优先先看 `tooling\scripts\install_claude_code.cmd migrate -FromMethod npm -Method native -DryRun -Yes`、`powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" migrate -FromMethod npm -Method native -DryRun -Yes` 或 `bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes`
