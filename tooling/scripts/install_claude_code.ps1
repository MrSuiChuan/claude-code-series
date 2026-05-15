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
    throw "Unsupported target: $Target. Use stable, latest, or a version such as 2.1.89."
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

    throw "Unsupported system"
}

function Get-HomeDirectory {
    if ($env:USERPROFILE) {
        return $env:USERPROFILE
    }

    if ($env:HOME) {
        return $env:HOME
    }

    throw "Unable to determine the current user's home directory"
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

    throw "Unsupported system"
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
        Add-UniqueItem -List $warnings -Value "Detected legacy local files under .claude/local. Remove them if they are from an older install."
    }

    if ($state.ClaudePaths.Count -gt 1) {
        Add-UniqueItem -List $warnings -Value "Detected multiple claude commands on PATH. Keep only one installation method to avoid version mismatches."
    }

    if ($detectedMethods.Count -gt 1) {
        Add-UniqueItem -List $warnings -Value ("Detected multiple install methods: " + (($detectedMethods.ToArray() | Sort-Object) -join ", "))
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
        throw "$($Runtime.System) does not support method $RequestedMethod. Available methods: $available"
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

        throw "Unable to choose an install method automatically. Install missing prerequisites or pass -Method explicitly."
    }

    $detectedMethods = @($State.DetectedMethods)

    if ($detectedMethods.Count -eq 1) {
        return $detectedMethods[0]
    }

    if ($detectedMethods.Count -gt 1) {
        throw "Multiple install methods were detected ($($detectedMethods -join ', ')). Re-run with -Method to choose the one you want to manage."
    }

    throw "No supported Claude Code installation was detected. Re-run with install or pass -Method explicitly."
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
        throw "Non-interactive environment detected. Re-run with -Yes to continue."
    }

    $answer = Read-Host "$PromptText [y/N]"
    if ($answer.ToLowerInvariant() -notin @("y", "yes")) {
        throw "Operation cancelled"
    }
}

function Get-CurlOrWgetCommand {
    if (Test-CommandExists "curl") {
        return "curl"
    }

    if (Test-CommandExists "wget") {
        return "wget"
    }

    throw "Missing required command: curl or wget"
}

function Get-NativeInstallPlan {
    param(
        [hashtable]$Runtime,
        [string]$InstallTarget
    )

    if ($Runtime.System -eq "windows") {
        if ($InstallTarget -eq "latest") {
            return @{
                Note = "Run the official native installer"
                DisplayCommand = "irm https://claude.ai/install.ps1 | iex"
                Runner = {
                    irm https://claude.ai/install.ps1 | iex
                }
            }
        }

        return @{
            Note = "Run the official native installer with a pinned target"
            DisplayCommand = "& ([scriptblock]::Create((irm https://claude.ai/install.ps1))) $InstallTarget"
            Runner = {
                & ([scriptblock]::Create((irm https://claude.ai/install.ps1))) $InstallTarget
            }.GetNewClosure()
        }
    }

    if (-not (Test-CommandExists "bash")) {
        throw "Missing required command: bash"
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
        Note = "Run the official native installer"
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
            Note = "Update the native installation"
            DisplayCommand = "$runnerPath update"
            Runner = {
                & $runnerPath update
            }.GetNewClosure()
        }
    }

    return @{
        Note = "Switch the native installation to a target release"
        DisplayCommand = "$runnerPath install $UpdateTarget"
        Runner = {
            & $runnerPath install $UpdateTarget
        }.GetNewClosure()
    }
}

function Get-NativeUninstallPlan {
    param([hashtable]$State)

    return @{
        Note = "Remove the native binary and version files"
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
        throw "WinGet in this wrapper supports the default package stream only. Use -Target latest."
    }

    if (-not (Test-CommandExists "winget")) {
        throw "Missing required command: winget"
    }

    switch ($CurrentAction) {
        "install" {
            return @{
                Note = "Install Claude Code with WinGet"
                DisplayCommand = "winget install Anthropic.ClaudeCode"
                Runner = { & winget install Anthropic.ClaudeCode }
            }
        }
        "update" {
            return @{
                Note = "Update Claude Code with WinGet"
                DisplayCommand = "winget upgrade Anthropic.ClaudeCode"
                Runner = { & winget upgrade Anthropic.ClaudeCode }
            }
        }
        "uninstall" {
            return @{
                Note = "Remove Claude Code with WinGet"
                DisplayCommand = "winget uninstall Anthropic.ClaudeCode"
                Runner = { & winget uninstall Anthropic.ClaudeCode }
            }
        }
    }

    throw "Unsupported action for WinGet: $CurrentAction"
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

    throw "Homebrew in this wrapper supports stable or latest only."
}

function Get-HomebrewPlan {
    param(
        [hashtable]$State,
        [string]$CurrentAction,
        [string]$SelectedTarget
    )

    if (-not (Test-CommandExists "brew")) {
        throw "Missing required command: brew"
    }

    $caskName = Get-HomebrewCaskForTarget -State $State -SelectedTarget $SelectedTarget

    switch ($CurrentAction) {
        "install" {
            return @{
                Note = "Install Claude Code with Homebrew"
                DisplayCommand = "brew install --cask $caskName"
                Runner = {
                    & brew install --cask $caskName
                }.GetNewClosure()
            }
        }
        "update" {
            return @{
                Note = "Update Claude Code with Homebrew"
                DisplayCommand = "brew upgrade $caskName"
                Runner = {
                    & brew upgrade $caskName
                }.GetNewClosure()
            }
        }
        "uninstall" {
            return @{
                Note = "Remove Claude Code with Homebrew"
                DisplayCommand = "brew uninstall --cask $caskName"
                Runner = {
                    & brew uninstall --cask $caskName
                }.GetNewClosure()
            }
        }
    }

    throw "Unsupported action for Homebrew: $CurrentAction"
}

function Get-NpmPlan {
    param(
        [string]$CurrentAction,
        [string]$SelectedTarget
    )

    if (-not (Test-CommandExists "npm")) {
        throw "Missing required command: npm"
    }

    if ($SelectedTarget -eq "stable") {
        throw "npm in this wrapper supports latest or a specific version, not stable."
    }

    switch ($CurrentAction) {
        "install" {
            $packageSpec = if ($SelectedTarget -eq "latest") { "@anthropic-ai/claude-code" } else { "@anthropic-ai/claude-code@$SelectedTarget" }
            return @{
                Note = "Install Claude Code with npm"
                DisplayCommand = "npm install -g $packageSpec"
                Runner = {
                    & npm install -g $packageSpec
                }.GetNewClosure()
            }
        }
        "update" {
            $packageSpec = if ($SelectedTarget -eq "latest") { "@anthropic-ai/claude-code@latest" } else { "@anthropic-ai/claude-code@$SelectedTarget" }
            return @{
                Note = "Update Claude Code with npm"
                DisplayCommand = "npm install -g $packageSpec"
                Runner = {
                    & npm install -g $packageSpec
                }.GetNewClosure()
            }
        }
        "uninstall" {
            return @{
                Note = "Remove Claude Code with npm"
                DisplayCommand = "npm uninstall -g @anthropic-ai/claude-code"
                Runner = {
                    & npm uninstall -g @anthropic-ai/claude-code
                }
            }
        }
    }

    throw "Unsupported action for npm: $CurrentAction"
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

    throw "Unable to build an action plan for method $ResolvedMethod"
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

    Write-Host "Action: $Action"
    Write-Host "Detected system: $($Runtime.System)"
    Write-Host "Detected architecture: $($Runtime.Architecture)"
    Write-Host "Requested method: $Method"
    Write-Host "Resolved method: $ResolvedMethod"
    Write-Host "Target: $Target"

    if ($State.DetectedMethods.Count -gt 0) {
        Write-Host "Detected install methods: $($State.DetectedMethods -join ', ')"
    } else {
        Write-Host "Detected install methods: none"
    }

    if ($State.ClaudePaths.Count -gt 0) {
        Write-Host "Claude paths:"
        foreach ($path in $State.ClaudePaths) {
            Write-Host "  $path"
        }
    } else {
        Write-Host "Claude paths: none"
    }

    if ($Plan) {
        Write-Host "Planned command: $($Plan.DisplayCommand)"
    }

    if ($State.Warnings.Count -gt 0) {
        Write-Host "Warnings:"
        foreach ($warning in $State.Warnings) {
            Write-Host "  - $warning"
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

    throw "The install/update finished, but version verification failed. Try opening a new terminal and run claude --version again."
}

function Show-RemainingInstallHint {
    $remainingPaths = Get-ClaudePaths
    if ($remainingPaths.Count -gt 0) {
        Write-Host "Uninstall finished, but another claude command is still on PATH:"
        foreach ($path in $remainingPaths) {
            Write-Host "  $path"
        }
        Write-Host "If this is unexpected, remove the extra installation manually."
    } else {
        Write-Host "Uninstall finished."
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
        Add-UniqueItem -List $recommendations -Value "Remove stale files under $($State.LegacyLocalPath) after confirming they are not needed."
    }

    if ($State.ClaudePaths.Count -gt 0) {
        Add-UniqueItem -List $recommendations -Value "If the Claude CLI starts normally, run claude doctor for a deeper built-in check."
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

    Write-Host "Doctor summary: $($doctorObject.summary)"
    Write-Host "Detected system: $($doctorObject.system)"
    Write-Host "Detected architecture: $($doctorObject.architecture)"
    Write-Host "Preferred install method: $($doctorObject.preferredInstallMethod)"

    if ($doctorObject.version) {
        Write-Host "Detected version: $($doctorObject.version)"
    } else {
        Write-Host "Detected version: unavailable"
    }

    if ($doctorObject.availableInstallMethods.Count -gt 0) {
        Write-Host "Available install methods: $($doctorObject.availableInstallMethods -join ', ')"
    } else {
        Write-Host "Available install methods: none"
    }

    if ($doctorObject.detectedMethods.Count -gt 0) {
        Write-Host "Detected install methods: $($doctorObject.detectedMethods -join ', ')"
    } else {
        Write-Host "Detected install methods: none"
    }

    if ($doctorObject.claudePaths.Count -gt 0) {
        Write-Host "Claude paths:"
        foreach ($path in $doctorObject.claudePaths) {
            Write-Host "  $path"
        }
    } else {
        Write-Host "Claude paths: none"
    }

    if ($doctorObject.warnings.Count -gt 0) {
        Write-Host "Warnings:"
        foreach ($warning in $doctorObject.warnings) {
            Write-Host "  - $warning"
        }
    }

    if ($doctorObject.recommendations.Count -gt 0) {
        Write-Host "Recommended next commands:"
        foreach ($recommendation in $doctorObject.recommendations) {
            Write-Host "  - $recommendation"
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
            Confirm-OrExit -PromptText "Legacy files were detected under $legacyPath. Remove them?"
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
        $warnings.Add("Multiple install methods are present. Review doctor recommendations and run migrate/uninstall explicitly.") | Out-Null
    } elseif ($State.DetectedMethods.Count -eq 1 -and $State.DetectedMethods[0] -eq "npm") {
        $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
        if ($availableMethods -contains "native") {
            $warnings.Add("npm installation detected. Consider migrating to native with: $(Get-EntryCommand -Runtime $Runtime) migrate -FromMethod npm -Method native -DryRun -Yes") | Out-Null
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
        Write-Host "Doctor fix actions:"
        foreach ($action in $actions) {
            Write-Host "  - $($action.detail)"
        }
    } else {
        Write-Host "Doctor fix actions: none"
    }

    if ($warnings.Count -gt 0) {
        Write-Host "Follow-up recommendations:"
        foreach ($warning in $warnings) {
            Write-Host "  - $warning"
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
        throw "$($Runtime.System) does not support migration source method $RequestedSourceMethod."
    }

    if ($RequestedSourceMethod -ne "auto") {
        if (-not (Test-MethodInstalled -State $State -ResolvedMethod $RequestedSourceMethod)) {
            throw "No $RequestedSourceMethod installation was detected on this machine."
        }
        return $RequestedSourceMethod
    }

    $detectedMethods = @($State.DetectedMethods)
    if ($detectedMethods.Count -eq 1) {
        return $detectedMethods[0]
    }

    if ($detectedMethods.Count -gt 1) {
        throw "Multiple install methods were detected ($($detectedMethods -join ', ')). Re-run with -FromMethod to choose the source installation."
    }

    throw "No supported Claude Code installation was detected for migration."
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
            throw "$($Runtime.System) does not support migration target method $RequestedTargetMethod."
        }
        if ($RequestedTargetMethod -eq $SourceMethod) {
            throw "The migration target method is the same as the source method: $SourceMethod."
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

    throw "Unable to choose a migration target automatically. Re-run with -Method to choose the destination installation method."
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
            note = "Target method $TargetMethod is already installed, so migration only needs cleanup."
        }
    }

    $planTitle = "Migrate Claude Code from $SourceMethod to $TargetMethod"
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
                    throw "Migration install step failed with exit code: $LASTEXITCODE"
                }

                $intermediateState = Get-InstallationState -Runtime $Runtime
                if (-not (Test-MethodInstalled -State $intermediateState -ResolvedMethod $TargetMethod)) {
                    throw "Migration stopped because the target method $TargetMethod was not detected after install."
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

    Write-Host "Migration source method: $($Plan.SourceMethod)"
    Write-Host "Migration target method: $($Plan.TargetMethod)"
    if ($Plan.TargetAlreadyInstalled) {
        Write-Host "Target install state: already installed"
    } else {
        Write-Host "Target install state: will be installed"
    }
    Write-Host "Migration steps:"
    foreach ($step in $Plan.Steps) {
        Write-Host "  $($step.step). [$($step.method)] $($step.command)"
    }

    if ($State.Warnings.Count -gt 0) {
        Write-Host "Warnings:"
        foreach ($warning in $State.Warnings) {
            Write-Host "  - $warning"
        }
    }
}

function Invoke-SelfTest {
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
        $originalDryRun = $DryRun
        $script:DryRun = $true
        $fixOutput = [ordered]@{
            warnings = @()
        }

        if ($state.DetectedMethods.Count -gt 1) {
            $fixOutput.warnings += "Multiple install methods are present. Review doctor recommendations and run migrate/uninstall explicitly."
        } elseif ($state.DetectedMethods.Count -eq 1 -and $state.DetectedMethods[0] -eq "npm") {
            $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
            if ($availableMethods -contains "native") {
                $fixOutput.warnings += "npm installation detected. Consider migrating to native with: $(Get-EntryCommand -Runtime $Runtime) migrate -FromMethod npm -Method native -DryRun -Yes"
            }
        }

        $results.Add([pscustomobject]@{
            name = "doctor-fix-dryrun"
            success = $true
            exitCode = 0
            output = ($fixOutput | ConvertTo-Json -Depth 4 -Compress)
        }) | Out-Null
        $script:DryRun = $originalDryRun
    } catch {
        $script:DryRun = $originalDryRun
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

    Write-Host "Self-test summary: $(if ($passedBool) { 'passed' } else { 'failed' })"
    foreach ($result in $resultArray) {
        Write-Host "  - $($result.name): $(if ($result.success) { 'ok' } else { 'failed' })"
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
            $fixOutput.warnings += "Multiple install methods are present. Review doctor recommendations and run migrate/uninstall explicitly."
        } elseif ($state.DetectedMethods.Count -eq 1 -and $state.DetectedMethods[0] -eq "npm") {
            $availableMethods = @(Get-AvailableInstallMethods -Runtime $Runtime)
            if ($availableMethods -contains "native") {
                $fixOutput.warnings += "npm installation detected. Consider migrating to native with: $(Get-EntryCommand -Runtime $Runtime) migrate -FromMethod npm -Method native -DryRun -Yes"
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
    $lines.Add("# Claude Code Environment Report") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("- Generated: $($reportObject.generatedAt)") | Out-Null
    $lines.Add("- System: $($reportObject.system)") | Out-Null
    $lines.Add("- Architecture: $($reportObject.architecture)") | Out-Null
    $lines.Add("- Version: $(if ($reportObject.version) { $reportObject.version } else { 'unavailable' })") | Out-Null
    $lines.Add("- Summary: $($reportObject.summary)") | Out-Null
    $lines.Add("- Preferred install method: $($reportObject.preferredInstallMethod)") | Out-Null
    $lines.Add("- Self-test: $(if ($reportObject.selfTestPassed) { 'passed' } else { 'failed' })") | Out-Null
    $lines.Add("") | Out-Null

    $lines.Add("## Install Methods") | Out-Null
    foreach ($method in $reportObject.availableInstallMethods) {
        $lines.Add("- Available: $method") | Out-Null
    }
    if ($reportObject.detectedMethods.Count -gt 0) {
        foreach ($method in $reportObject.detectedMethods) {
            $lines.Add("- Detected: $method") | Out-Null
        }
    } else {
        $lines.Add("- Detected: none") | Out-Null
    }
    $lines.Add("") | Out-Null

    $lines.Add("## Claude Paths") | Out-Null
    if ($reportObject.claudePaths.Count -gt 0) {
        foreach ($path in $reportObject.claudePaths) {
            $lines.Add("- " + '`' + $path + '`') | Out-Null
        }
    } else {
        $lines.Add("- none") | Out-Null
    }
    $lines.Add("") | Out-Null

    $lines.Add("## Recommendations") | Out-Null
    if ($reportObject.recommendations.Count -gt 0) {
        foreach ($recommendation in $reportObject.recommendations) {
            $lines.Add("- $recommendation") | Out-Null
        }
    } else {
        $lines.Add("- none") | Out-Null
    }
    $lines.Add("") | Out-Null

    $lines.Add("## Self-Test Checks") | Out-Null
    foreach ($check in $reportObject.selfTestChecks) {
        $lines.Add("- $($check.name): $(if ($check.success) { 'ok' } else { 'failed' })") | Out-Null
        $lines.Add("  - Output: $($check.output)") | Out-Null
    }

    ($lines -join [Environment]::NewLine) | Write-Output
}

try {
    $runtime = Get-RuntimeInfo
    $state = Get-InstallationState -Runtime $runtime

    if ($Action -eq "self-test") {
        $script:SelfTestPassed = $false
        Invoke-SelfTest -Runtime $runtime
        $selfTestPassed = [bool]$script:SelfTestPassed
        if ($selfTestPassed) {
            exit 0
        }
        exit 1
    }

    if ($Action -eq "doctor") {
        $resolvedMethod = Resolve-Method -Runtime $runtime -RequestedMethod $Method -CurrentAction $Action -State $state
        Show-Doctor -Runtime $runtime -State $state -ResolvedMethod $resolvedMethod
        if ($Fix) {
            Invoke-DoctorFix -Runtime $runtime -State $state -ResolvedMethod $resolvedMethod
        }
        exit 0
    }

    if ($Action -eq "report") {
        Show-Report -Runtime $runtime
        exit 0
    }

    if ($Action -eq "migrate") {
        $sourceMethod = Resolve-MigrationSourceMethod -Runtime $runtime -State $state -RequestedSourceMethod $FromMethod
        $targetMethod = Resolve-MigrationTargetMethod -Runtime $runtime -RequestedTargetMethod $Method -SourceMethod $sourceMethod
        $migrationPlan = Get-MigrationPlan -Runtime $runtime -State $state -SourceMethod $sourceMethod -TargetMethod $targetMethod

        Show-MigrationPlan -Runtime $runtime -State $state -Plan $migrationPlan

        if ($DryRun) {
            if (-not $Json) {
                Write-Host "Dry-run mode enabled. Nothing was executed."
            }
            exit 0
        }

        Confirm-OrExit -PromptText "Claude Code will be migrated from $sourceMethod to $targetMethod. Continue?"
        & $migrationPlan.Runner

        if ($LASTEXITCODE -ne 0) {
            throw "Migration failed with exit code: $LASTEXITCODE"
        }

        if ($SkipVerify) {
            Write-Host "Migration finished. Verification was skipped."
            Show-RemainingInstallHint
            exit 0
        }

        $postMigrationState = Get-InstallationState -Runtime $runtime
        if (-not (Test-MethodInstalled -State $postMigrationState -ResolvedMethod $targetMethod)) {
            throw "Migration finished, but the target method $targetMethod was not detected afterwards."
        }

        $version = Get-ClaudeVersionText -State $postMigrationState
        if ($version) {
            Write-Host "Migration succeeded: $version"
        } else {
            Write-Host "Migration succeeded."
        }
        Show-RemainingInstallHint
        exit 0
    }

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
        exit 0
    }

    if ($Action -eq "install" -and (($state.DetectedMethods.Count -gt 0) -or ($state.ClaudePaths.Count -gt 0)) -and -not $Force) {
        if (-not $Json) {
            Write-Host "Claude Code already appears to be installed. Re-run with -Force to reinstall."
        }
        exit 0
    }

    if ($Action -in @("update", "uninstall") -and -not (Test-MethodInstalled -State $state -ResolvedMethod $resolvedMethod)) {
        throw "No $resolvedMethod installation was detected on this machine."
    }

    if (-not $plan) {
        $plan = Get-ActionPlan -Runtime $runtime -State $state -ResolvedMethod $resolvedMethod -CurrentAction $Action
    }

    if ($Json -and $DryRun) {
        exit 0
    }

    Write-Host "Plan note: $($plan.Note)"
    Write-Host "Plan command: $($plan.DisplayCommand)"

    if ($DryRun) {
        Write-Host "Dry-run mode enabled. Nothing was executed."
        exit 0
    }

    switch ($Action) {
        "install" { Confirm-OrExit -PromptText "Claude Code will be installed or reinstalled. Continue?" }
        "update" { Confirm-OrExit -PromptText "Claude Code will be updated. Continue?" }
        "uninstall" { Confirm-OrExit -PromptText "Claude Code will be removed. Continue?" }
    }

    & $plan.Runner

    if ($LASTEXITCODE -ne 0) {
        throw "$Action failed with exit code: $LASTEXITCODE"
    }

    if ($Action -eq "uninstall") {
        Show-RemainingInstallHint
        exit 0
    }

    if ($SkipVerify) {
        Write-Host "$Action finished. Verification was skipped."
        exit 0
    }

    $postState = Get-InstallationState -Runtime $runtime
    $version = Verify-Install -State $postState
    if ($version) {
        Write-Host "$Action succeeded: $version"
    } else {
        Write-Host "$Action succeeded."
    }

    exit 0
} catch {
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
