param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "update", "uninstall", "status", "doctor", "migrate", "self-test", "report")]
    [string]$Action = "install",

    [ValidateSet("auto", "native", "winget", "homebrew", "npm")]
    [string]$Method = "auto",

    [ValidateSet("auto", "native", "winget", "homebrew", "npm")]
    [string]$FromMethod = "auto",

    [Alias("Channel")]
    [string]$Target = "latest",

    [switch]$Force,
    [switch]$Yes,
    [switch]$DryRun,
    [switch]$SkipVerify,
    [switch]$Json,
    [switch]$Fix,

    [switch]$Status
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($Status) {
    $Action = "status"
}

if ($Target -notmatch '^(stable|latest|\d+\.\d+\.\d+(\S+)?)$') {
    throw "不支持的目标版本：$Target。请使用 stable、latest，或类似 2.1.89 的具体版本号。"
}

function Get-ActionDisplayName {
    param([string]$Name)

    switch ($Name) {
        "install" { return "安装" }
        "update" { return "更新" }
        "uninstall" { return "卸载" }
        "status" { return "状态检查" }
        "doctor" { return "环境诊断" }
        "migrate" { return "安装来源迁移" }
        "self-test" { return "脚本自检" }
        "report" { return "环境报告" }
        default { return $Name }
    }
}

function Get-DoctorSummaryDisplayName {
    param([string]$Summary)

    switch ($Summary) {
        "healthy" { return "正常" }
        "warning" { return "需要关注" }
        "not_installed" { return "未安装" }
        default { return $Summary }
    }
}

function Get-SelfTestCheckDisplayName {
    param([string]$Name)

    switch ($Name) {
        "status-state" { return "状态信息检查" }
        "doctor-state" { return "环境诊断检查" }
        "doctor-fix-dryrun" { return "诊断修复预演检查" }
        "update-dryrun-plan" { return "更新计划预演检查" }
        "uninstall-dryrun-plan" { return "卸载计划预演检查" }
        "install-dryrun-plan" { return "安装计划预演检查" }
        "plan-generation" { return "执行计划生成检查" }
        default { return $Name }
    }
}

function Get-ProgressActivityText {
    param([string]$ActionName)

    return "Claude Code $(Get-ActionDisplayName -Name $ActionName)"
}

function Write-UiInfo {
    param([string]$Message)

    if (-not $Json) {
        Write-Host $Message
    }
}

function Write-UiWarning {
    param([string]$Message)

    if (-not $Json) {
        Write-Host "警告：$Message" -ForegroundColor Yellow
    }
}

function Write-UiSuccess {
    param([string]$Message)

    if (-not $Json) {
        Write-Host $Message -ForegroundColor Green
    }
}

function Write-UiProgress {
    param(
        [string]$ActionName,
        [string]$Status,
        [int]$Percent
    )

    if ($Json) {
        return
    }

    Write-Progress -Id 1 -Activity (Get-ProgressActivityText -ActionName $ActionName) -Status $Status -PercentComplete $Percent
}

function Complete-UiProgress {
    param([string]$ActionName)

    if ($Json) {
        return
    }

    Write-Progress -Id 1 -Activity (Get-ProgressActivityText -ActionName $ActionName) -Completed
}

function Get-NormalizedArchitecture {
    $raw = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    switch ($raw) {
        "x64" { return "x64" }
        "amd64" { return "x64" }
        "arm64" { return "arm64" }
        "x86" { return "x86" }
        default { return $raw }
    }
}

function Test-IsWsl {
    if ($env:WSL_INTEROP -or $env:WSL_DISTRO_NAME) {
        return $true
    }

    if (Test-Path "/proc/sys/kernel/osrelease") {
        try {
            $content = Get-Content "/proc/sys/kernel/osrelease" -Raw
            return $content.ToLowerInvariant().Contains("microsoft")
        } catch {
            return $false
        }
    }

    return $false
}

function Get-RuntimeInfo {
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        return @{
            System = "windows"
            Architecture = Get-NormalizedArchitecture
        }
    }

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
        return @{
            System = "macos"
            Architecture = Get-NormalizedArchitecture
        }
    }

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux) -and (Test-IsWsl)) {
        return @{
            System = "wsl"
            Architecture = Get-NormalizedArchitecture
        }
    }

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
        return @{
            System = "linux"
            Architecture = Get-NormalizedArchitecture
        }
    }

    throw "暂不支持当前系统。"
}

function Get-HomeDirectory {
    if ($env:USERPROFILE) {
        return $env:USERPROFILE
    }

    if ($env:HOME) {
        return $env:HOME
    }

    throw "无法确定当前用户的主目录。"
}

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-UniqueStrings {
    param([string[]]$Values)

    $seen = @{}
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($value in $Values) {
        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }
        if (-not $seen.ContainsKey($value)) {
            $seen[$value] = $true
            [void]$result.Add($value)
        }
    }
    return $result.ToArray()
}

function Add-UniqueItem {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    if (-not $List.Contains($Value)) {
        [void]$List.Add($Value)
    }
}

function Get-ClaudePaths {
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows) -and (Test-CommandExists "where.exe")) {
        $directories = @{}
        $result = New-Object System.Collections.Generic.List[string]
        try {
            $matches = & where.exe claude 2>$null
            foreach ($match in $matches) {
                if ([string]::IsNullOrWhiteSpace($match)) {
                    continue
                }
                $directory = Split-Path -Path $match -Parent
                if (-not $directories.ContainsKey($directory)) {
                    $directories[$directory] = $true
                    [void]$result.Add($match)
                }
            }
            return $result.ToArray()
        } catch {
        }
    }

    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($name in @("claude", "claude.cmd", "claude.exe", "claude.ps1")) {
        $matches = Get-Command $name -All -ErrorAction SilentlyContinue
        foreach ($match in $matches) {
            if ($match.Source) {
                Add-UniqueItem -List $paths -Value $match.Source
            }
        }
    }
    return $paths.ToArray()
}

function Get-NativePaths {
    param([hashtable]$Runtime)

    $userHomeDir = Get-HomeDirectory

    if ($Runtime.System -eq "windows") {
        return @{
            CommandPath = [System.IO.Path]::Combine($userHomeDir, ".local", "bin", "claude.exe")
            SharePath   = [System.IO.Path]::Combine($userHomeDir, ".local", "share", "claude")
            LegacyPath  = [System.IO.Path]::Combine($userHomeDir, ".claude", "local")
        }
    }

    return @{
        CommandPath = "$userHomeDir/.local/bin/claude"
        SharePath   = "$userHomeDir/.local/share/claude"
        LegacyPath  = "$userHomeDir/.claude/local"
    }
}

function Test-NativeInstallSupported {
    param([hashtable]$Runtime)

    if ($Runtime.System -eq "windows") {
        return $true
    }

    return (Test-CommandExists "bash") -and ((Test-CommandExists "curl") -or (Test-CommandExists "wget"))
}

function Get-SupportedMethods {
    param([hashtable]$Runtime)

    switch ($Runtime.System) {
        "windows" { return @("native", "winget", "npm") }
        "macos" { return @("native", "homebrew", "npm") }
        "linux" { return @("native", "npm") }
        "wsl" { return @("native", "npm") }
    }

    throw "暂不支持当前系统。"
}

function Get-AvailableInstallMethods {
    param([hashtable]$Runtime)

    $available = New-Object System.Collections.Generic.List[string]
    foreach ($candidate in Get-SupportedMethods -Runtime $Runtime) {
        switch ($candidate) {
            "native" {
                if (Test-NativeInstallSupported -Runtime $Runtime) {
                    Add-UniqueItem -List $available -Value "native"
                }
            }
            "winget" {
                if (Test-CommandExists "winget") {
                    Add-UniqueItem -List $available -Value "winget"
                }
            }
            "homebrew" {
                if (Test-CommandExists "brew") {
                    Add-UniqueItem -List $available -Value "homebrew"
                }
            }
            "npm" {
                if (Test-CommandExists "npm") {
                    Add-UniqueItem -List $available -Value "npm"
                }
            }
        }
    }

    return $available.ToArray()
}

function Get-HomebrewCask {
    param([hashtable]$Runtime)

    if ($Runtime.System -ne "macos" -or -not (Test-CommandExists "brew")) {
        return $null
    }

    try {
        & brew list --cask claude-code *> $null
        if ($LASTEXITCODE -eq 0) {
            return "claude-code"
        }
    } catch {
    }

    try {
        & brew list --cask 'claude-code@latest' *> $null
        if ($LASTEXITCODE -eq 0) {
            return "claude-code@latest"
        }
    } catch {
    }

    return $null
}

function Get-InstallationState {
    param([hashtable]$Runtime)

    $nativePaths = Get-NativePaths -Runtime $Runtime
    $claudePaths = Get-ClaudePaths
    $detectedMethods = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    $state = [ordered]@{
        NativePath          = $nativePaths.CommandPath
        NativeSharePath     = $nativePaths.SharePath
        LegacyLocalPath     = $nativePaths.LegacyPath
        NativeInstalled     = Test-Path $nativePaths.CommandPath
        LegacyLocalInstalled = Test-Path $nativePaths.LegacyPath
        ClaudePaths         = @($claudePaths)
        NpmInstalled        = $false
        WingetInstalled     = $false
        HomebrewCask        = Get-HomebrewCask -Runtime $Runtime
        DetectedMethods     = @()
        Warnings            = @()
    }

    if ($state.NativeInstalled) {
        Add-UniqueItem -List $detectedMethods -Value "native"
    }
    if ($state.WingetInstalled) {
        Add-UniqueItem -List $detectedMethods -Value "winget"
    }
    if ($state.HomebrewCask) {
        Add-UniqueItem -List $detectedMethods -Value "homebrew"
    }
    if ($state.NpmInstalled) {
        Add-UniqueItem -List $detectedMethods -Value "npm"
    }

    foreach ($path in $state.ClaudePaths) {
        if ($Runtime.System -eq "windows" -and $path -match '\\AppData\\Roaming\\npm\\claude(\.cmd|\.ps1)?$') {
            $state.NpmInstalled = $true
            Add-UniqueItem -List $detectedMethods -Value "npm"
        }
        if ($Runtime.System -eq "windows" -and $path -match '\\AppData\\Local\\Microsoft\\WinGet\\Links\\claude(\.exe)?$') {
            $state.WingetInstalled = $true
            Add-UniqueItem -List $detectedMethods -Value "winget"
        }
    }

    if ($state.LegacyLocalInstalled) {
        Add-UniqueItem -List $warnings -Value "检测到 .claude/local 下存在遗留文件。如果这是旧安装留下的内容，请确认后删除。"
    }

    if ($state.ClaudePaths.Count -gt 1) {
        Add-UniqueItem -List $warnings -Value "检测到 PATH 中存在多个 claude 命令。建议只保留一种安装方式，避免版本混用。"
    }

    if ($detectedMethods.Count -gt 1) {
        Add-UniqueItem -List $warnings -Value ("检测到多个安装来源：" + (($detectedMethods.ToArray() | Sort-Object) -join ", "))
    }

    $state.DetectedMethods = @($detectedMethods.ToArray() | Sort-Object)
    $state.Warnings = @($warnings.ToArray())
    return $state
}

function Resolve-Method {
    param(
        [hashtable]$Runtime,
        [string]$RequestedMethod,
        [string]$CurrentAction,
        [hashtable]$State
    )

    $supported = @{
        windows = @("auto") + (Get-SupportedMethods -Runtime $Runtime)
        macos   = @("auto") + (Get-SupportedMethods -Runtime $Runtime)
        linux   = @("auto") + (Get-SupportedMethods -Runtime $Runtime)
        wsl     = @("auto") + (Get-SupportedMethods -Runtime $Runtime)
    }

    if ($supported[$Runtime.System] -notcontains $RequestedMethod) {
        $available = ($supported[$Runtime.System] | Where-Object { $_ -ne "auto" }) -join " / "
        throw "$($Runtime.System) 暂不支持安装方式 $RequestedMethod。可用安装方式：$available"
    }

    if ($RequestedMethod -ne "auto") {
        return $RequestedMethod
    }

    if ($CurrentAction -in @("status", "doctor")) {
        $detectedMethods = @($State.DetectedMethods)
        if ($detectedMethods.Count -eq 1) {
            return $detectedMethods[0]
        }
    }

    if ($CurrentAction -in @("install", "status", "doctor")) {
        $availableInstallMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
        if ($availableInstallMethods.Count -gt 0) {
            return $availableInstallMethods[0]
        }

    throw "无法自动选择安装方式。请先安装缺失的依赖，或显式传入 -Method。"
    }

    $detectedMethods = @($State.DetectedMethods)

    if ($detectedMethods.Count -eq 1) {
        return $detectedMethods[0]
    }

    if ($detectedMethods.Count -gt 1) {
        throw "检测到多个安装来源（$($detectedMethods -join ', ')）。请重新执行并通过 -Method 指定要管理的安装方式。"
    }

    throw "未检测到受支持的 Claude Code 安装。请执行 install，或显式传入 -Method。"
}

function Test-MethodInstalled {
    param(
        [hashtable]$State,
        [string]$ResolvedMethod
    )

    switch ($ResolvedMethod) {
        "native" { return [bool]$State.NativeInstalled }
        "winget" { return [bool]$State.WingetInstalled }
        "homebrew" { return [bool]$State.HomebrewCask }
        "npm" { return [bool]$State.NpmInstalled }
        default { return $false }
    }
}

function Confirm-OrExit {
    param([string]$PromptText)

    if ($Yes) {
        return
    }

    if (-not [Environment]::UserInteractive) {
        throw "检测到当前环境为非交互模式。请重新执行并带上 -Yes。"
    }

    $answer = Read-Host "$PromptText [y/N]"
    if ($answer.ToLowerInvariant() -notin @("y", "yes")) {
        throw "操作已取消。"
    }
}

function Get-CurlOrWgetCommand {
    if (Test-CommandExists "curl") {
        return "curl"
    }

    if (Test-CommandExists "wget") {
        return "wget"
    }

    throw "缺少必要命令：curl 或 wget。"
}

function Get-NativeInstallPlan {
    param(
        [hashtable]$Runtime,
        [string]$InstallTarget
    )

    if ($Runtime.System -eq "windows") {
        if ($InstallTarget -eq "latest") {
            return @{
                Note = "执行官方 native 安装脚本"
                DisplayCommand = "irm https://claude.ai/install.ps1 | iex"
                Runner = {
                    irm https://claude.ai/install.ps1 | iex
                }
            }
        }

        return @{
            Note = "执行指定版本的官方 native 安装脚本"
            DisplayCommand = "& ([scriptblock]::Create((irm https://claude.ai/install.ps1))) $InstallTarget"
            Runner = {
                & ([scriptblock]::Create((irm https://claude.ai/install.ps1))) $InstallTarget
            }.GetNewClosure()
        }
    }

    if (-not (Test-CommandExists "bash")) {
        throw "缺少必要命令：bash。"
    }

    $downloader = Get-CurlOrWgetCommand
    $base = if ($downloader -eq "curl") {
        "curl -fsSL https://claude.ai/install.sh | bash"
    } else {
        "wget -qO- https://claude.ai/install.sh | bash"
    }

    $displayCommand = $base
    if ($InstallTarget -ne "latest") {
        $displayCommand = "$base -s $InstallTarget"
    }

    return @{
        Note = "执行官方 native 安装脚本"
        DisplayCommand = $displayCommand
        Runner = {
            & bash -lc $displayCommand
        }.GetNewClosure()
    }
}

function Get-NativeUpdatePlan {
    param(
        [hashtable]$State,
        [string]$UpdateTarget
    )

    $runnerPath = if ($State.NativeInstalled) { $State.NativePath } else { "claude" }

    if ($UpdateTarget -eq "latest") {
        return @{
            Note = "更新 native 安装"
            DisplayCommand = "$runnerPath update"
            Runner = {
                & $runnerPath update
            }.GetNewClosure()
        }
    }

    return @{
        Note = "把 native 安装切换到指定版本"
        DisplayCommand = "$runnerPath install $UpdateTarget"
        Runner = {
            & $runnerPath install $UpdateTarget
        }.GetNewClosure()
    }
}

function Get-NativeUninstallPlan {
    param([hashtable]$State)

    return @{
        Note = "删除 native 二进制和版本文件"
        DisplayCommand = "Remove-Item -Path `"$($State.NativePath)`" -Force; Remove-Item -Path `"$($State.NativeSharePath)`" -Recurse -Force"
        Runner = {
            if (Test-Path $State.NativePath) {
                Remove-Item -LiteralPath $State.NativePath -Force
            }
            if (Test-Path $State.NativeSharePath) {
                Remove-Item -LiteralPath $State.NativeSharePath -Recurse -Force
            }
        }.GetNewClosure()
    }
}

function Get-WingetPlan {
    param(
        [string]$CurrentAction,
        [string]$SelectedTarget
    )

    if ($SelectedTarget -ne "latest") {
        throw "当前封装里的 WinGet 仅支持默认发布流。请使用 -Target latest。"
    }

    if (-not (Test-CommandExists "winget")) {
        throw "缺少必要命令：winget。"
    }

    switch ($CurrentAction) {
        "install" {
            return @{
                Note = "使用 WinGet 安装 Claude Code"
                DisplayCommand = "winget install Anthropic.ClaudeCode"
                Runner = { & winget install Anthropic.ClaudeCode }
            }
        }
        "update" {
            return @{
                Note = "使用 WinGet 更新 Claude Code"
                DisplayCommand = "winget upgrade Anthropic.ClaudeCode"
                Runner = { & winget upgrade Anthropic.ClaudeCode }
            }
        }
        "uninstall" {
            return @{
                Note = "使用 WinGet 卸载 Claude Code"
                DisplayCommand = "winget uninstall Anthropic.ClaudeCode"
                Runner = { & winget uninstall Anthropic.ClaudeCode }
            }
        }
    }

    throw "WinGet 不支持当前动作：$CurrentAction"
}

function Get-HomebrewCaskForTarget {
    param(
        [hashtable]$State,
        [string]$SelectedTarget
    )

    if ($State.HomebrewCask) {
        return $State.HomebrewCask
    }

    if ($SelectedTarget -eq "stable") {
        return "claude-code"
    }

    if ($SelectedTarget -eq "latest") {
        return "claude-code@latest"
    }

    throw "当前封装里的 Homebrew 仅支持 stable 或 latest。"
}

function Get-HomebrewPlan {
    param(
        [hashtable]$State,
        [string]$CurrentAction,
        [string]$SelectedTarget
    )

    if (-not (Test-CommandExists "brew")) {
        throw "缺少必要命令：brew。"
    }

    $caskName = Get-HomebrewCaskForTarget -State $State -SelectedTarget $SelectedTarget

    switch ($CurrentAction) {
        "install" {
            return @{
                Note = "使用 Homebrew 安装 Claude Code"
                DisplayCommand = "brew install --cask $caskName"
                Runner = {
                    & brew install --cask $caskName
                }.GetNewClosure()
            }
        }
        "update" {
            return @{
                Note = "使用 Homebrew 更新 Claude Code"
                DisplayCommand = "brew upgrade $caskName"
                Runner = {
                    & brew upgrade $caskName
                }.GetNewClosure()
            }
        }
        "uninstall" {
            return @{
                Note = "使用 Homebrew 卸载 Claude Code"
                DisplayCommand = "brew uninstall --cask $caskName"
                Runner = {
                    & brew uninstall --cask $caskName
                }.GetNewClosure()
            }
        }
    }

    throw "Homebrew 不支持当前动作：$CurrentAction"
}

function Get-NpmPlan {
    param(
        [string]$CurrentAction,
        [string]$SelectedTarget
    )

    if (-not (Test-CommandExists "npm")) {
        throw "缺少必要命令：npm。"
    }

    if ($SelectedTarget -eq "stable") {
        throw "当前封装里的 npm 支持 latest 或具体版本号，不支持 stable。"
    }

    switch ($CurrentAction) {
        "install" {
            $packageSpec = if ($SelectedTarget -eq "latest") { "@anthropic-ai/claude-code" } else { "@anthropic-ai/claude-code@$SelectedTarget" }
            return @{
                Note = "使用 npm 安装 Claude Code"
                DisplayCommand = "npm install -g $packageSpec"
                Runner = {
                    & npm install -g $packageSpec
                }.GetNewClosure()
            }
        }
        "update" {
            $packageSpec = if ($SelectedTarget -eq "latest") { "@anthropic-ai/claude-code@latest" } else { "@anthropic-ai/claude-code@$SelectedTarget" }
            return @{
                Note = "使用 npm 更新 Claude Code"
                DisplayCommand = "npm install -g $packageSpec"
                Runner = {
                    & npm install -g $packageSpec
                }.GetNewClosure()
            }
        }
        "uninstall" {
            return @{
                Note = "使用 npm 卸载 Claude Code"
                DisplayCommand = "npm uninstall -g @anthropic-ai/claude-code"
                Runner = {
                    & npm uninstall -g @anthropic-ai/claude-code
                }
            }
        }
    }

    throw "npm 不支持当前动作：$CurrentAction"
}

function Get-ActionPlan {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [string]$ResolvedMethod,
        [string]$CurrentAction
    )

    switch ($ResolvedMethod) {
        "native" {
            switch ($CurrentAction) {
                "install" { return Get-NativeInstallPlan -Runtime $Runtime -InstallTarget $Target }
                "update" { return Get-NativeUpdatePlan -State $State -UpdateTarget $Target }
                "uninstall" { return Get-NativeUninstallPlan -State $State }
            }
        }
        "winget" {
            return Get-WingetPlan -CurrentAction $CurrentAction -SelectedTarget $Target
        }
        "homebrew" {
            return Get-HomebrewPlan -State $State -CurrentAction $CurrentAction -SelectedTarget $Target
        }
        "npm" {
            return Get-NpmPlan -CurrentAction $CurrentAction -SelectedTarget $Target
        }
    }

    throw "无法为安装方式 $ResolvedMethod 生成执行计划。"
}

function New-StatusObject {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [string]$ResolvedMethod,
        [hashtable]$Plan
    )

    return [ordered]@{
        action = $Action
        system = $Runtime.System
        architecture = $Runtime.Architecture
        requestedMethod = $Method
        resolvedMethod = $ResolvedMethod
        target = $Target
        installed = ($State.DetectedMethods.Count -gt 0) -or ($State.ClaudePaths.Count -gt 0)
        detectedMethods = @($State.DetectedMethods)
        claudePaths = @($State.ClaudePaths)
        nativeInstalled = [bool]$State.NativeInstalled
        wingetInstalled = [bool]$State.WingetInstalled
        homebrewCask = $State.HomebrewCask
        npmInstalled = [bool]$State.NpmInstalled
        legacyLocalInstalled = [bool]$State.LegacyLocalInstalled
        warnings = @($State.Warnings)
        planNote = if ($Plan) { $Plan.Note } else { $null }
        planCommand = if ($Plan) { $Plan.DisplayCommand } else { $null }
        dryRun = [bool]$DryRun
    }
}

function Show-Status {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [string]$ResolvedMethod,
        [hashtable]$Plan
    )

    if ($Json) {
        $statusObject = New-StatusObject -Runtime $Runtime -State $State -ResolvedMethod $ResolvedMethod -Plan $Plan
        $statusObject | ConvertTo-Json -Depth 5
        return
    }

    Write-UiInfo "当前动作：$(Get-ActionDisplayName -Name $Action)"
    Write-UiInfo "检测到的系统：$($Runtime.System)"
    Write-UiInfo "检测到的架构：$($Runtime.Architecture)"
    Write-UiInfo "请求的安装方式：$Method"
    Write-UiInfo "最终使用的安装方式：$ResolvedMethod"
    Write-UiInfo "目标版本：$Target"

    if ($State.DetectedMethods.Count -gt 0) {
        Write-UiInfo "检测到的安装来源：$($State.DetectedMethods -join ', ')"
    } else {
        Write-UiInfo "检测到的安装来源：无"
    }

    if ($State.ClaudePaths.Count -gt 0) {
        Write-UiInfo "检测到的 Claude 路径："
        foreach ($path in $State.ClaudePaths) {
            Write-UiInfo "  $path"
        }
    } else {
        Write-UiInfo "检测到的 Claude 路径：无"
    }

    if ($Plan) {
        Write-UiInfo "计划执行命令：$($Plan.DisplayCommand)"
    }

    if ($State.Warnings.Count -gt 0) {
        Write-UiWarning "以下项目需要关注："
        foreach ($warning in $State.Warnings) {
            Write-UiWarning "  - $warning"
        }
    }
}

function Verify-Install {
    param([hashtable]$State)

    $candidates = New-Object System.Collections.Generic.List[string]

    if ($State.NativeInstalled -and $State.NativePath) {
        Add-UniqueItem -List $candidates -Value $State.NativePath
    }

    foreach ($path in $State.ClaudePaths) {
        Add-UniqueItem -List $candidates -Value $path
    }

    if ($candidates.Count -eq 0 -and (Test-CommandExists "claude")) {
        Add-UniqueItem -List $candidates -Value "claude"
    }

    foreach ($candidate in $candidates) {
        try {
            $output = & $candidate --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                return ($output | Out-String).Trim()
            }
        } catch {
        }
    }

    throw "安装或更新已经完成，但版本校验失败。请尝试重新打开终端后执行 claude --version。"
}

function Show-RemainingInstallHint {
    $remainingPaths = Get-ClaudePaths
    if ($remainingPaths.Count -gt 0) {
        Write-UiInfo "卸载已完成，但 PATH 中仍然存在其他 claude 命令："
        foreach ($path in $remainingPaths) {
            Write-UiInfo "  $path"
        }
        Write-UiWarning "如果这不是你预期的结果，请手动移除多余的安装。"
    } else {
        Write-UiSuccess "卸载已完成。"
    }
}

function Get-EntryCommand {
    param([hashtable]$Runtime)

    if ($Runtime.System -eq "windows") {
        return "install_claude_code.cmd"
    }

    return "pwsh ./install_claude_code.ps1"
}

function Get-ClaudeVersionText {
    param([hashtable]$State)

    $npmPackageJsonCandidates = @()
    $npmPackageJsonCandidates += [System.IO.Path]::Combine($env:APPDATA, "npm", "node_modules", "@anthropic-ai", "claude-code", "package.json")
    $npmPackageJsonCandidates += [System.IO.Path]::Combine($env:USERPROFILE, "AppData", "Roaming", "npm", "node_modules", "@anthropic-ai", "claude-code", "package.json")
    $npmPackageJsonCandidates += "/usr/lib/node_modules/@anthropic-ai/claude-code/package.json"
    $npmPackageJsonCandidates += "/usr/local/lib/node_modules/@anthropic-ai/claude-code/package.json"

    foreach ($candidate in $npmPackageJsonCandidates) {
        if (Test-Path $candidate) {
            try {
                $packageJson = Get-Content $candidate -Raw | ConvertFrom-Json
                if ($packageJson.version) {
                    return $packageJson.version
                }
            } catch {
            }
        }
    }

    try {
        return Verify-Install -State $State
    } catch {
        return $null
    }
}

function Get-DoctorSummary {
    param(
        [hashtable]$State,
        [string]$VersionText
    )

    if ($State.DetectedMethods.Count -eq 0 -and $State.ClaudePaths.Count -eq 0) {
        return "not_installed"
    }

    if (($State.DetectedMethods.Count -gt 0 -or $State.ClaudePaths.Count -gt 0) -and [string]::IsNullOrWhiteSpace($VersionText)) {
        return "warning"
    }

    if ($State.Warnings.Count -gt 0) {
        return "warning"
    }

    return "healthy"
}

function Get-DoctorRecommendations {
    param(
        [hashtable]$Runtime,
        [hashtable]$State
    )

    $recommendations = New-Object System.Collections.Generic.List[string]
    $entryCommand = Get-EntryCommand -Runtime $Runtime
    $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)

    if ($State.DetectedMethods.Count -eq 0 -and $availableMethods.Count -gt 0) {
        Add-UniqueItem -List $recommendations -Value "$entryCommand install -Yes"
    }

    if ($State.DetectedMethods.Count -eq 1) {
        $onlyMethod = $State.DetectedMethods[0]
        Add-UniqueItem -List $recommendations -Value "$entryCommand update -Method $onlyMethod -DryRun -Yes"

        if ($onlyMethod -eq "npm" -and $availableMethods -contains "native") {
            Add-UniqueItem -List $recommendations -Value "$entryCommand migrate -FromMethod npm -Method native -DryRun -Yes"
        }
    }

    if ($State.DetectedMethods.Count -gt 1) {
        Add-UniqueItem -List $recommendations -Value "$entryCommand migrate -FromMethod <source> -Method native -DryRun -Yes"
        Add-UniqueItem -List $recommendations -Value "$entryCommand uninstall -Method <source> -DryRun -Yes"
    }

    if ($State.LegacyLocalInstalled) {
        Add-UniqueItem -List $recommendations -Value "确认旧文件不再需要后，删除 $($State.LegacyLocalPath) 下的遗留文件。"
    }

    if ($State.ClaudePaths.Count -gt 0) {
        Add-UniqueItem -List $recommendations -Value "如果 Claude CLI 可以正常启动，建议继续执行 claude doctor 做更深一步的内建检查。"
    }

    return $recommendations.ToArray()
}

function New-DoctorObject {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [string]$ResolvedMethod
    )

    $versionText = Get-ClaudeVersionText -State $State

    return [ordered]@{
        action = "doctor"
        system = $Runtime.System
        architecture = $Runtime.Architecture
        preferredInstallMethod = $ResolvedMethod
        availableInstallMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
        detectedMethods = @($State.DetectedMethods)
        claudePaths = @($State.ClaudePaths)
        version = $versionText
        summary = Get-DoctorSummary -State $State -VersionText $versionText
        warnings = @($State.Warnings)
        recommendations = @(Get-DoctorRecommendations -Runtime $Runtime -State $State)
    }
}

function Show-Doctor {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [string]$ResolvedMethod
    )

    $doctorObject = New-DoctorObject -Runtime $Runtime -State $State -ResolvedMethod $ResolvedMethod

    if ($Json) {
        $doctorObject | ConvertTo-Json -Depth 5
        return
    }

    Write-UiInfo "诊断结论：$(Get-DoctorSummaryDisplayName -Summary $doctorObject.summary)"
    Write-UiInfo "检测到的系统：$($doctorObject.system)"
    Write-UiInfo "检测到的架构：$($doctorObject.architecture)"
    Write-UiInfo "推荐安装方式：$($doctorObject.preferredInstallMethod)"

    if ($doctorObject.version) {
        Write-UiInfo "检测到的版本：$($doctorObject.version)"
    } else {
        Write-UiInfo "检测到的版本：无法获取"
    }

    if ($doctorObject.availableInstallMethods.Count -gt 0) {
        Write-UiInfo "当前环境可用的安装方式：$($doctorObject.availableInstallMethods -join ', ')"
    } else {
        Write-UiInfo "当前环境可用的安装方式：无"
    }

    if ($doctorObject.detectedMethods.Count -gt 0) {
        Write-UiInfo "检测到的安装来源：$($doctorObject.detectedMethods -join ', ')"
    } else {
        Write-UiInfo "检测到的安装来源：无"
    }

    if ($doctorObject.claudePaths.Count -gt 0) {
        Write-UiInfo "检测到的 Claude 路径："
        foreach ($path in $doctorObject.claudePaths) {
            Write-UiInfo "  $path"
        }
    } else {
        Write-UiInfo "检测到的 Claude 路径：无"
    }

    if ($doctorObject.warnings.Count -gt 0) {
        Write-UiWarning "以下项目需要关注："
        foreach ($warning in $doctorObject.warnings) {
            Write-UiWarning "  - $warning"
        }
    }

    if ($doctorObject.recommendations.Count -gt 0) {
        Write-UiInfo "建议下一步执行："
        foreach ($recommendation in $doctorObject.recommendations) {
            Write-UiInfo "  - $recommendation"
        }
    }
}

function Invoke-DoctorFix {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [string]$ResolvedMethod
    )

    $actions = New-Object System.Collections.Generic.List[object]
    $warnings = New-Object System.Collections.Generic.List[string]

    if ($State.LegacyLocalInstalled) {
        $legacyPath = $State.LegacyLocalPath
        if ($DryRun) {
            $actions.Add([pscustomobject]@{
                name = "remove-legacy-local"
                applied = $false
                dryRun = $true
                detail = "Would remove $legacyPath"
            }) | Out-Null
        } else {
            Confirm-OrExit -PromptText "检测到 $legacyPath 下存在遗留文件，是否删除？"
            if (Test-Path $legacyPath) {
                Remove-Item -LiteralPath $legacyPath -Recurse -Force
            }
            $actions.Add([pscustomobject]@{
                name = "remove-legacy-local"
                applied = $true
                dryRun = $false
                detail = "Removed $legacyPath"
            }) | Out-Null
        }
    }

    if ($State.DetectedMethods.Count -gt 1) {
        $warnings.Add("检测到多个安装来源。请先查看诊断建议，再明确执行 migrate 或 uninstall。") | Out-Null
    } elseif ($State.DetectedMethods.Count -eq 1 -and $State.DetectedMethods[0] -eq "npm") {
        $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
        if ($availableMethods -contains "native") {
            $warnings.Add("检测到 npm 安装，建议通过以下命令迁移到 native：$(Get-EntryCommand -Runtime $Runtime) migrate -FromMethod npm -Method native -DryRun -Yes") | Out-Null
        }
    }

    $postState = Get-InstallationState -Runtime $Runtime
    $resultObject = [ordered]@{
        action = "doctor-fix"
        applied = ($actions.Count -gt 0)
        dryRun = [bool]$DryRun
        actions = @($actions.ToArray())
        warnings = @($warnings.ToArray())
        detectedMethods = @($postState.DetectedMethods)
        claudePaths = @($postState.ClaudePaths)
    }

    if ($Json) {
        $resultObject | ConvertTo-Json -Depth 5
        return
    }

    if ($actions.Count -gt 0) {
        Write-UiInfo "诊断修复执行结果："
        foreach ($action in $actions) {
            Write-UiInfo "  - $($action.detail)"
        }
    } else {
        Write-UiInfo "诊断修复执行结果：无变更"
    }

    if ($warnings.Count -gt 0) {
        Write-UiInfo "后续建议："
        foreach ($warning in $warnings) {
            Write-UiInfo "  - $warning"
        }
    }
}

function Resolve-MigrationSourceMethod {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [string]$RequestedSourceMethod
    )

    $supportedMethods = @(Get-SupportedMethods -Runtime $Runtime)
    if ($supportedMethods -notcontains $RequestedSourceMethod -and $RequestedSourceMethod -ne "auto") {
        throw "$($Runtime.System) 暂不支持迁移来源方式 $RequestedSourceMethod。"
    }

    if ($RequestedSourceMethod -ne "auto") {
        if (-not (Test-MethodInstalled -State $State -ResolvedMethod $RequestedSourceMethod)) {
            throw "当前机器上未检测到 $RequestedSourceMethod 安装。"
        }
        return $RequestedSourceMethod
    }

    $detectedMethods = @($State.DetectedMethods)
    if ($detectedMethods.Count -eq 1) {
        return $detectedMethods[0]
    }

    if ($detectedMethods.Count -gt 1) {
        throw "检测到多个安装来源（$($detectedMethods -join ', ')）。请重新执行并通过 -FromMethod 指定迁移来源。"
    }

    throw "未检测到可用于迁移的受支持 Claude Code 安装。"
}

function Resolve-MigrationTargetMethod {
    param(
        [hashtable]$Runtime,
        [string]$RequestedTargetMethod,
        [string]$SourceMethod
    )

    $supportedMethods = @(Get-SupportedMethods -Runtime $Runtime)
    $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)

    if ($RequestedTargetMethod -ne "auto") {
        if ($supportedMethods -notcontains $RequestedTargetMethod) {
            throw "$($Runtime.System) 暂不支持迁移目标方式 $RequestedTargetMethod。"
        }
        if ($RequestedTargetMethod -eq $SourceMethod) {
            throw "迁移目标方式与来源方式相同：$SourceMethod。"
        }
        return $RequestedTargetMethod
    }

    if ($SourceMethod -ne "native" -and $availableMethods -contains "native") {
        return "native"
    }

    foreach ($candidate in $availableMethods) {
        if ($candidate -ne $SourceMethod) {
            return $candidate
        }
    }

    throw "无法自动选择迁移目标。请重新执行并通过 -Method 指定目标安装方式。"
}

function Get-MigrationPlan {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [string]$SourceMethod,
        [string]$TargetMethod
    )

    $targetAlreadyInstalled = Test-MethodInstalled -State $State -ResolvedMethod $TargetMethod
    $installPlan = $null
    if (-not $targetAlreadyInstalled) {
        $installPlan = Get-ActionPlan -Runtime $Runtime -State $State -ResolvedMethod $TargetMethod -CurrentAction "install"
    }
    $removePlan = Get-ActionPlan -Runtime $Runtime -State $State -ResolvedMethod $SourceMethod -CurrentAction "uninstall"

    $steps = @()
    if ($installPlan) {
        $steps += [pscustomobject]@{
            step = 1
            action = "install"
            method = $TargetMethod
            command = $installPlan.DisplayCommand
            note = $installPlan.Note
        }
        $steps += [pscustomobject]@{
            step = 2
            action = "uninstall"
            method = $SourceMethod
            command = $removePlan.DisplayCommand
            note = $removePlan.Note
        }
    } else {
        $steps += [pscustomobject]@{
            step = 1
            action = "uninstall"
            method = $SourceMethod
            command = $removePlan.DisplayCommand
            note = "目标安装方式 $TargetMethod 已存在，因此本次迁移只需要做清理。"
        }
    }

    $planTitle = "把 Claude Code 从 $SourceMethod 迁移到 $TargetMethod"
    $planCommand = ($steps | ForEach-Object { "$($_.step)) $($_.command)" }) -join "; "

    return @{
        SourceMethod = $SourceMethod
        TargetMethod = $TargetMethod
        TargetAlreadyInstalled = $targetAlreadyInstalled
        InstallPlan = $installPlan
        RemovePlan = $removePlan
        Steps = @($steps)
        Note = $planTitle
        DisplayCommand = $planCommand
        Runner = {
            if ($installPlan) {
                & $installPlan.Runner
                if ($LASTEXITCODE -ne 0) {
                    throw "迁移中的安装步骤执行失败，退出码：$LASTEXITCODE"
                }

                $intermediateState = Get-InstallationState -Runtime $Runtime
                if (-not (Test-MethodInstalled -State $intermediateState -ResolvedMethod $TargetMethod)) {
                    throw "迁移已中止，因为安装完成后没有检测到目标安装方式 $TargetMethod。"
                }
            }

            & $removePlan.Runner
        }.GetNewClosure()
    }
}

function Show-MigrationPlan {
    param(
        [hashtable]$Runtime,
        [hashtable]$State,
        [hashtable]$Plan
    )

    if ($Json) {
        [ordered]@{
            action = "migrate"
            system = $Runtime.System
            architecture = $Runtime.Architecture
            sourceMethod = $Plan.SourceMethod
            targetMethod = $Plan.TargetMethod
            targetAlreadyInstalled = [bool]$Plan.TargetAlreadyInstalled
            steps = @($Plan.Steps)
            warnings = @($State.Warnings)
            dryRun = [bool]$DryRun
        } | ConvertTo-Json -Depth 6
        return
    }

    Write-UiInfo "迁移来源方式：$($Plan.SourceMethod)"
    Write-UiInfo "迁移目标方式：$($Plan.TargetMethod)"
    if ($Plan.TargetAlreadyInstalled) {
        Write-UiInfo "目标安装状态：已安装"
    } else {
        Write-UiInfo "目标安装状态：待安装"
    }
    Write-UiInfo "迁移步骤："
    foreach ($step in $Plan.Steps) {
        Write-UiInfo "  $($step.step). [$($step.method)] $($step.command)"
    }

    if ($State.Warnings.Count -gt 0) {
        Write-UiWarning "以下项目需要关注："
        foreach ($warning in $State.Warnings) {
            Write-UiWarning "  - $warning"
        }
    }
}

function Invoke-SelfTest {
    param([hashtable]$Runtime)

    $results = New-Object System.Collections.Generic.List[object]
    $state = Get-InstallationState -Runtime $Runtime
    $availableMethodsForSelfTest = @(Get-AvailableInstallMethods -Runtime $Runtime)
    $expectedChecks = 3
    if ($state.DetectedMethods.Count -gt 0) {
        $expectedChecks += 2
    } elseif ($availableMethodsForSelfTest.Count -gt 0) {
        $expectedChecks += 1
    }
    $completedChecks = 0
    $resolvedForDoctor = Resolve-Method -Runtime $Runtime -RequestedMethod $Method -CurrentAction "doctor" -State $state
    $results.Add([pscustomobject]@{
        name = "status-state"
        success = $true
        exitCode = 0
        output = ((New-StatusObject -Runtime $Runtime -State $state -ResolvedMethod $resolvedForDoctor -Plan $null) | ConvertTo-Json -Depth 5 -Compress)
    }) | Out-Null
    $completedChecks++
    Write-UiProgress -ActionName "self-test" -Status "正在执行：$(Get-SelfTestCheckDisplayName -Name 'status-state')" -Percent (40 + [int](($completedChecks / $expectedChecks) * 50))

    $doctorObject = New-DoctorObject -Runtime $Runtime -State $state -ResolvedMethod $resolvedForDoctor
    $results.Add([pscustomobject]@{
        name = "doctor-state"
        success = $true
        exitCode = 0
        output = ($doctorObject | ConvertTo-Json -Depth 5 -Compress)
    }) | Out-Null
    $completedChecks++
    Write-UiProgress -ActionName "self-test" -Status "正在执行：$(Get-SelfTestCheckDisplayName -Name 'doctor-state')" -Percent (40 + [int](($completedChecks / $expectedChecks) * 50))

    try {
        $originalDryRun = $DryRun
        $script:DryRun = $true
        $fixOutput = [ordered]@{
            warnings = @()
        }

        if ($state.DetectedMethods.Count -gt 1) {
                $fixOutput.warnings += "检测到多个安装来源。请先查看诊断建议，再明确执行 migrate 或 uninstall。"
        } elseif ($state.DetectedMethods.Count -eq 1 -and $state.DetectedMethods[0] -eq "npm") {
            $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
            if ($availableMethods -contains "native") {
                $fixOutput.warnings += "检测到 npm 安装，建议通过以下命令迁移到 native：$(Get-EntryCommand -Runtime $Runtime) migrate -FromMethod npm -Method native -DryRun -Yes"
            }
        }

        $results.Add([pscustomobject]@{
            name = "doctor-fix-dryrun"
            success = $true
            exitCode = 0
            output = ($fixOutput | ConvertTo-Json -Depth 4 -Compress)
        }) | Out-Null
        $completedChecks++
        Write-UiProgress -ActionName "self-test" -Status "正在执行：$(Get-SelfTestCheckDisplayName -Name 'doctor-fix-dryrun')" -Percent (40 + [int](($completedChecks / $expectedChecks) * 50))
        $script:DryRun = $originalDryRun
    } catch {
        $script:DryRun = $originalDryRun
        $results.Add([pscustomobject]@{
            name = "doctor-fix-dryrun"
            success = $false
            exitCode = 1
            output = $_.Exception.Message
        }) | Out-Null
        $completedChecks++
        Write-UiProgress -ActionName "self-test" -Status "正在执行：$(Get-SelfTestCheckDisplayName -Name 'doctor-fix-dryrun')" -Percent (40 + [int](($completedChecks / $expectedChecks) * 50))
    }

    try {
        if ($state.DetectedMethods.Count -gt 0) {
            $methodToTest = $state.DetectedMethods[0]
            $updatePlan = Get-ActionPlan -Runtime $Runtime -State $state -ResolvedMethod $methodToTest -CurrentAction "update"
            $results.Add([pscustomobject]@{
                name = "update-dryrun-plan"
                success = $true
                exitCode = 0
                output = $updatePlan.DisplayCommand
            }) | Out-Null
            $completedChecks++
            Write-UiProgress -ActionName "self-test" -Status "正在执行：$(Get-SelfTestCheckDisplayName -Name 'update-dryrun-plan')" -Percent (40 + [int](($completedChecks / $expectedChecks) * 50))

            $uninstallPlan = Get-ActionPlan -Runtime $Runtime -State $state -ResolvedMethod $methodToTest -CurrentAction "uninstall"
            $results.Add([pscustomobject]@{
                name = "uninstall-dryrun-plan"
                success = $true
                exitCode = 0
                output = $uninstallPlan.DisplayCommand
            }) | Out-Null
            $completedChecks++
            Write-UiProgress -ActionName "self-test" -Status "正在执行：$(Get-SelfTestCheckDisplayName -Name 'uninstall-dryrun-plan')" -Percent (40 + [int](($completedChecks / $expectedChecks) * 50))
        } else {
            if ($availableMethodsForSelfTest.Count -gt 0) {
                $methodToTest = $availableMethodsForSelfTest[0]
                $installPlan = Get-ActionPlan -Runtime $Runtime -State $state -ResolvedMethod $methodToTest -CurrentAction "install"
                $results.Add([pscustomobject]@{
                    name = "install-dryrun-plan"
                    success = $true
                    exitCode = 0
                    output = $installPlan.DisplayCommand
                }) | Out-Null
                $completedChecks++
                Write-UiProgress -ActionName "self-test" -Status "正在执行：$(Get-SelfTestCheckDisplayName -Name 'install-dryrun-plan')" -Percent (40 + [int](($completedChecks / $expectedChecks) * 50))
            }
        }
    } catch {
        $results.Add([pscustomobject]@{
            name = "plan-generation"
            success = $false
            exitCode = 1
            output = $_.Exception.Message
        }) | Out-Null
        $completedChecks++
        Write-UiProgress -ActionName "self-test" -Status "正在执行：$(Get-SelfTestCheckDisplayName -Name 'plan-generation')" -Percent (40 + [int](($completedChecks / $expectedChecks) * 50))
    }

    $allPassed = -not ($results | Where-Object { -not $_.success })

    $passedBool = [bool]$allPassed
    $script:SelfTestPassed = $passedBool
    $resultArray = $results.ToArray()

    if ($Json) {
        [ordered]@{
            action = "self-test"
            system = $Runtime.System
            architecture = $Runtime.Architecture
            passed = $passedBool
            checks = $resultArray
        } | ConvertTo-Json -Depth 6
        return
    }

    Write-UiInfo "自检结果：$(if ($passedBool) { '通过' } else { '失败' })"
    foreach ($result in $resultArray) {
        Write-UiInfo "  - $(Get-SelfTestCheckDisplayName -Name $result.name)：$(if ($result.success) { '通过' } else { '失败' })"
    }
    return
}

function Get-SelfTestData {
    param([hashtable]$Runtime)

    $results = New-Object System.Collections.Generic.List[object]
    $state = Get-InstallationState -Runtime $Runtime
    $resolvedForDoctor = Resolve-Method -Runtime $Runtime -RequestedMethod $Method -CurrentAction "doctor" -State $state
    $results.Add([pscustomobject]@{
        name = "status-state"
        success = $true
        exitCode = 0
        output = ((New-StatusObject -Runtime $Runtime -State $state -ResolvedMethod $resolvedForDoctor -Plan $null) | ConvertTo-Json -Depth 5 -Compress)
    }) | Out-Null

    $doctorObject = New-DoctorObject -Runtime $Runtime -State $state -ResolvedMethod $resolvedForDoctor
    $results.Add([pscustomobject]@{
        name = "doctor-state"
        success = $true
        exitCode = 0
        output = ($doctorObject | ConvertTo-Json -Depth 5 -Compress)
    }) | Out-Null

    try {
        $fixOutput = [ordered]@{
            warnings = @()
        }

        if ($state.DetectedMethods.Count -gt 1) {
            $fixOutput.warnings += "检测到多个安装来源。请先查看诊断建议，再明确执行 migrate 或 uninstall。"
        } elseif ($state.DetectedMethods.Count -eq 1 -and $state.DetectedMethods[0] -eq "npm") {
            $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
            if ($availableMethods -contains "native") {
                $fixOutput.warnings += "检测到 npm 安装，建议通过以下命令迁移到 native：$(Get-EntryCommand -Runtime $Runtime) migrate -FromMethod npm -Method native -DryRun -Yes"
            }
        }

        $results.Add([pscustomobject]@{
            name = "doctor-fix-dryrun"
            success = $true
            exitCode = 0
            output = ($fixOutput | ConvertTo-Json -Depth 4 -Compress)
        }) | Out-Null
    } catch {
        $results.Add([pscustomobject]@{
            name = "doctor-fix-dryrun"
            success = $false
            exitCode = 1
            output = $_.Exception.Message
        }) | Out-Null
    }

    try {
        if ($state.DetectedMethods.Count -gt 0) {
            $methodToTest = $state.DetectedMethods[0]
            $updatePlan = Get-ActionPlan -Runtime $Runtime -State $state -ResolvedMethod $methodToTest -CurrentAction "update"
            $results.Add([pscustomobject]@{
                name = "update-dryrun-plan"
                success = $true
                exitCode = 0
                output = $updatePlan.DisplayCommand
            }) | Out-Null

            $uninstallPlan = Get-ActionPlan -Runtime $Runtime -State $state -ResolvedMethod $methodToTest -CurrentAction "uninstall"
            $results.Add([pscustomobject]@{
                name = "uninstall-dryrun-plan"
                success = $true
                exitCode = 0
                output = $uninstallPlan.DisplayCommand
            }) | Out-Null
        } else {
            $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
            if ($availableMethods.Count -gt 0) {
                $methodToTest = $availableMethods[0]
                $installPlan = Get-ActionPlan -Runtime $Runtime -State $state -ResolvedMethod $methodToTest -CurrentAction "install"
                $results.Add([pscustomobject]@{
                    name = "install-dryrun-plan"
                    success = $true
                    exitCode = 0
                    output = $installPlan.DisplayCommand
                }) | Out-Null
            }
        }
    } catch {
        $results.Add([pscustomobject]@{
            name = "plan-generation"
            success = $false
            exitCode = 1
            output = $_.Exception.Message
        }) | Out-Null
    }

    return [ordered]@{
        passed = (-not ($results | Where-Object { -not $_.success }))
        checks = $results.ToArray()
    }
}

function New-ReportObject {
    param([hashtable]$Runtime)

    $state = Get-InstallationState -Runtime $Runtime
    $resolvedForDoctor = Resolve-Method -Runtime $Runtime -RequestedMethod $Method -CurrentAction "doctor" -State $state
    $doctorObject = New-DoctorObject -Runtime $Runtime -State $state -ResolvedMethod $resolvedForDoctor
    $selfTestObject = Get-SelfTestData -Runtime $Runtime

    return [ordered]@{
        action = "report"
        generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")
        system = $Runtime.System
        architecture = $Runtime.Architecture
        version = $doctorObject.version
        summary = $doctorObject.summary
        preferredInstallMethod = $doctorObject.preferredInstallMethod
        availableInstallMethods = @($doctorObject.availableInstallMethods)
        detectedMethods = @($doctorObject.detectedMethods)
        claudePaths = @($doctorObject.claudePaths)
        warnings = @($doctorObject.warnings)
        recommendations = @($doctorObject.recommendations)
        selfTestPassed = [bool]$selfTestObject.passed
        selfTestChecks = @($selfTestObject.checks)
    }
}

function Show-Report {
    param([hashtable]$Runtime)

    $reportObject = New-ReportObject -Runtime $Runtime

    if ($Json) {
        $reportObject | ConvertTo-Json -Depth 6
        return
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Claude Code 环境报告") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("- 生成时间：$($reportObject.generatedAt)") | Out-Null
    $lines.Add("- 系统：$($reportObject.system)") | Out-Null
    $lines.Add("- 架构：$($reportObject.architecture)") | Out-Null
    $lines.Add("- 版本：$(if ($reportObject.version) { $reportObject.version } else { '无法获取' })") | Out-Null
    $lines.Add("- 诊断结论：$(Get-DoctorSummaryDisplayName -Summary $reportObject.summary)") | Out-Null
    $lines.Add("- 推荐安装方式：$($reportObject.preferredInstallMethod)") | Out-Null
    $lines.Add("- 自检结果：$(if ($reportObject.selfTestPassed) { '通过' } else { '失败' })") | Out-Null
    $lines.Add("") | Out-Null

    $lines.Add("## 安装方式") | Out-Null
    foreach ($method in $reportObject.availableInstallMethods) {
        $lines.Add("- 可用：$method") | Out-Null
    }
    if ($reportObject.detectedMethods.Count -gt 0) {
        foreach ($method in $reportObject.detectedMethods) {
            $lines.Add("- 已检测到：$method") | Out-Null
        }
    } else {
        $lines.Add("- 已检测到：无") | Out-Null
    }
    $lines.Add("") | Out-Null

    $lines.Add("## Claude 路径") | Out-Null
    if ($reportObject.claudePaths.Count -gt 0) {
        foreach ($path in $reportObject.claudePaths) {
            $lines.Add("- " + '`' + $path + '`') | Out-Null
        }
    } else {
        $lines.Add("- 无") | Out-Null
    }
    $lines.Add("") | Out-Null

    $lines.Add("## 建议") | Out-Null
    if ($reportObject.recommendations.Count -gt 0) {
        foreach ($recommendation in $reportObject.recommendations) {
            $lines.Add("- $recommendation") | Out-Null
        }
    } else {
        $lines.Add("- 无") | Out-Null
    }
    $lines.Add("") | Out-Null

    $lines.Add("## 自检项") | Out-Null
    foreach ($check in $reportObject.selfTestChecks) {
        $lines.Add("- $(Get-SelfTestCheckDisplayName -Name $check.name)：$(if ($check.success) { '通过' } else { '失败' })") | Out-Null
        $lines.Add("  - 输出：$($check.output)") | Out-Null
    }

    ($lines -join [Environment]::NewLine) | Write-Output
}

try {
    Write-UiProgress -ActionName $Action -Status "正在收集运行环境信息" -Percent 5
    $runtime = Get-RuntimeInfo
    Write-UiProgress -ActionName $Action -Status "正在检测当前安装状态" -Percent 15
    $state = Get-InstallationState -Runtime $runtime

    if ($Action -eq "self-test") {
        Write-UiProgress -ActionName $Action -Status "正在执行脚本自检" -Percent 40
        $script:SelfTestPassed = $false
        Invoke-SelfTest -Runtime $runtime
        Complete-UiProgress -ActionName $Action
        $selfTestPassed = [bool]$script:SelfTestPassed
        if ($selfTestPassed) {
            exit 0
        }
        exit 1
    }

    if ($Action -eq "doctor") {
        Write-UiProgress -ActionName $Action -Status "正在分析环境并生成诊断结果" -Percent 45
        $resolvedMethod = Resolve-Method -Runtime $runtime -RequestedMethod $Method -CurrentAction $Action -State $state
        Show-Doctor -Runtime $runtime -State $state -ResolvedMethod $resolvedMethod
        if ($Fix) {
            Write-UiProgress -ActionName $Action -Status "正在执行低风险修复" -Percent 75
            Invoke-DoctorFix -Runtime $runtime -State $state -ResolvedMethod $resolvedMethod
        }
        Complete-UiProgress -ActionName $Action
        exit 0
    }

    if ($Action -eq "report") {
        Write-UiProgress -ActionName $Action -Status "正在汇总环境信息并生成报告" -Percent 50
        Show-Report -Runtime $runtime
        Complete-UiProgress -ActionName $Action
        exit 0
    }

    if ($Action -eq "migrate") {
        Write-UiProgress -ActionName $Action -Status "正在解析迁移来源和目标" -Percent 30
        $sourceMethod = Resolve-MigrationSourceMethod -Runtime $runtime -State $state -RequestedSourceMethod $FromMethod
        $targetMethod = Resolve-MigrationTargetMethod -Runtime $runtime -RequestedTargetMethod $Method -SourceMethod $sourceMethod
        $migrationPlan = Get-MigrationPlan -Runtime $runtime -State $state -SourceMethod $sourceMethod -TargetMethod $targetMethod

        Write-UiProgress -ActionName $Action -Status "正在生成迁移计划" -Percent 45
        Show-MigrationPlan -Runtime $runtime -State $state -Plan $migrationPlan

        if ($DryRun) {
            if (-not $Json) {
                Write-UiInfo "当前为预演模式，没有执行任何实际变更。"
            }
            Complete-UiProgress -ActionName $Action
            exit 0
        }

        Confirm-OrExit -PromptText "即将把 Claude Code 从 $sourceMethod 迁移到 $targetMethod，是否继续？"
        Write-UiProgress -ActionName $Action -Status "正在执行迁移步骤" -Percent 70
        & $migrationPlan.Runner

        if ($LASTEXITCODE -ne 0) {
            throw "迁移执行失败，退出码：$LASTEXITCODE"
        }

        if ($SkipVerify) {
            Write-UiSuccess "迁移已完成，已按要求跳过校验。"
            Show-RemainingInstallHint
            Complete-UiProgress -ActionName $Action
            exit 0
        }

        Write-UiProgress -ActionName $Action -Status "正在校验迁移结果" -Percent 90
        $postMigrationState = Get-InstallationState -Runtime $runtime
        if (-not (Test-MethodInstalled -State $postMigrationState -ResolvedMethod $targetMethod)) {
            throw "迁移已完成，但后续没有检测到目标安装方式 $targetMethod。"
        }

        $version = Get-ClaudeVersionText -State $postMigrationState
        if ($version) {
            Write-UiSuccess "迁移成功，当前版本：$version"
        } else {
            Write-UiSuccess "迁移成功。"
        }
        Show-RemainingInstallHint
        Complete-UiProgress -ActionName $Action
        exit 0
    }

    Write-UiProgress -ActionName $Action -Status "正在解析安装方式与执行计划" -Percent 35
    $resolvedMethod = Resolve-Method -Runtime $runtime -RequestedMethod $Method -CurrentAction $Action -State $state
    $plan = $null

    try {
        $plan = Get-ActionPlan -Runtime $runtime -State $state -ResolvedMethod $resolvedMethod -CurrentAction $Action
    } catch {
        if ($Action -eq "status") {
            $plan = $null
        } else {
            throw
        }
    }

    Show-Status -Runtime $runtime -State $state -ResolvedMethod $resolvedMethod -Plan $plan

    if ($Action -eq "status") {
        Complete-UiProgress -ActionName $Action
        exit 0
    }

    if ($Action -eq "install" -and (($state.DetectedMethods.Count -gt 0) -or ($state.ClaudePaths.Count -gt 0)) -and -not $Force) {
        if (-not $Json) {
            Write-UiInfo "Claude Code 看起来已经安装。如需重新安装，请带上 -Force。"
        }
        Complete-UiProgress -ActionName $Action
        exit 0
    }

    if ($Action -in @("update", "uninstall") -and -not (Test-MethodInstalled -State $state -ResolvedMethod $resolvedMethod)) {
        throw "当前机器上未检测到 $resolvedMethod 安装。"
    }

    if (-not $plan) {
        $plan = Get-ActionPlan -Runtime $runtime -State $state -ResolvedMethod $resolvedMethod -CurrentAction $Action
    }

    if ($Json -and $DryRun) {
        exit 0
    }

    Write-UiInfo "执行说明：$($plan.Note)"
    Write-UiInfo "执行命令：$($plan.DisplayCommand)"

    if ($DryRun) {
        Write-UiInfo "当前为预演模式，没有执行任何实际变更。"
        Complete-UiProgress -ActionName $Action
        exit 0
    }

    switch ($Action) {
        "install" { Confirm-OrExit -PromptText "即将安装或重新安装 Claude Code，是否继续？" }
        "update" { Confirm-OrExit -PromptText "即将更新 Claude Code，是否继续？" }
        "uninstall" { Confirm-OrExit -PromptText "即将卸载 Claude Code，是否继续？" }
    }

    Write-UiProgress -ActionName $Action -Status "正在执行计划命令" -Percent 70
    & $plan.Runner

    if ($LASTEXITCODE -ne 0) {
        throw "$(Get-ActionDisplayName -Name $Action)执行失败，退出码：$LASTEXITCODE"
    }

    if ($Action -eq "uninstall") {
        Show-RemainingInstallHint
        Complete-UiProgress -ActionName $Action
        exit 0
    }

    if ($SkipVerify) {
        Write-UiSuccess "$(Get-ActionDisplayName -Name $Action)已完成，已按要求跳过校验。"
        Complete-UiProgress -ActionName $Action
        exit 0
    }

    Write-UiProgress -ActionName $Action -Status "正在校验执行结果" -Percent 90
    $postState = Get-InstallationState -Runtime $runtime
    $version = Verify-Install -State $postState
    if ($version) {
        Write-UiSuccess "$(Get-ActionDisplayName -Name $Action)成功，当前版本：$version"
    } else {
        Write-UiSuccess "$(Get-ActionDisplayName -Name $Action)成功。"
    }

    Complete-UiProgress -ActionName $Action
    exit 0
} catch {
    Complete-UiProgress -ActionName $Action
    if ($env:CLAUDE_CODE_DEBUG -eq "1") {
        Write-Error ($_.Exception | Format-List * -Force | Out-String)
        if ($_.ScriptStackTrace) {
            Write-Error $_.ScriptStackTrace
        }
    } else {
        Write-Error $_.Exception.Message
    }
    exit 1
}
