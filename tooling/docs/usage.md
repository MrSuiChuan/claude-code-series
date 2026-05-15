# Usage

## Windows

### CMD

```bat
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
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" doctor -Json
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" self-test -Json
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tooling\scripts\install_claude_code.ps1" report
```

## shell

```bash
bash ./tooling/scripts/install_claude_code.sh status
bash ./tooling/scripts/install_claude_code.sh doctor
bash ./tooling/scripts/install_claude_code.sh doctor --fix --dry-run
bash ./tooling/scripts/install_claude_code.sh self-test --json
bash ./tooling/scripts/install_claude_code.sh migrate --from npm --method native --dry-run --yes
```

## 推荐顺序

1. `doctor`
2. `doctor fix --dry-run`
3. `self-test`
4. `report`
5. 需要时再执行真实的 `install / update / uninstall / migrate`

## 高风险动作说明

- 安装来源迁移不会在 `doctor fix` 里自动执行
- 多来源安装只会给出建议，不会直接删改
- 如果你机器上已有旧的 npm 安装，优先先看 `migrate ... -DryRun`
