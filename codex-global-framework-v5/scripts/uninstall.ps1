[CmdletBinding()]
param(
    [string]$CodexHome,
    [string]$SkillsHome
)
$ErrorActionPreference = "Stop"
$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { [Environment]::GetFolderPath('UserProfile') }
if ([string]::IsNullOrWhiteSpace($homeDir)) { $homeDir = $HOME }
$homeFullPath = [IO.Path]::GetFullPath($homeDir)
# Same resolution as install.ps1: expands ~, resolves relative paths (even if missing), drops trailing separators.
function Resolve-UserPath([string]$Path) {
    if ($Path -eq '~') { $Path = $homeFullPath }
    elseif ($Path -match '^~[\\/]') { $Path = Join-Path $homeFullPath $Path.Substring(2) }
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $root = [IO.Path]::GetPathRoot($full)
    if ($full.Length -gt $root.Length) { $full = $full.TrimEnd('\', '/') }
    return $full
}
if ([string]::IsNullOrWhiteSpace($CodexHome)) { $CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeFullPath ".codex" } }
if ([string]::IsNullOrWhiteSpace($SkillsHome)) { $SkillsHome = Join-Path $homeFullPath ".agents\skills" }
$CodexHome = Resolve-UserPath $CodexHome
$SkillsHome = Resolve-UserPath $SkillsHome
$roles = @("luna_explorer", "luna_worker", "terra_worker", "terra_reviewer", "sol_specialist", "sol_reviewer", "sol_critical")
$skills = @("security-review", "code-review", "dependency-review", "documentation")
$hooksFile = Join-Path $CodexHome "hooks.json"
# Unbalanced markers abort before any backup or change.
function Test-MarkersBalanced([string]$Text, [string]$BeginRe, [string]$EndRe) {
    $inBlock = $false
    foreach ($line in ($Text -split "\r?\n")) {
        if ($line -match $BeginRe) { if ($inBlock) { return $false }; $inBlock = $true }
        elseif ($line -match $EndRe) { if (-not $inBlock) { return $false }; $inBlock = $false }
    }
    return (-not $inBlock)
}
foreach ($check in @(
    @{ File = (Join-Path $CodexHome "AGENTS.md"); Begin = '<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5'; End = '<!-- CODEX-GLOBAL-FRAMEWORK:END v5' },
    @{ File = (Join-Path $CodexHome "config.toml"); Begin = '# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS'; End = '# END CODEX GLOBAL FRAMEWORK V5 AGENTS' })) {
    if ((Test-Path -LiteralPath $check.File) -and -not (Test-MarkersBalanced ([IO.File]::ReadAllText($check.File)) $check.Begin $check.End)) {
        throw "Unbalanced framework markers in $($check.File); fix manually. No changes made."
    }
}
# Validate hooks.json before touching anything.
$newHooksJson = $null
if (Test-Path -LiteralPath $hooksFile) {
    try { $data = [IO.File]::ReadAllText($hooksFile) | ConvertFrom-Json }
    catch { throw "Existing hooks.json is invalid; no changes made. $($_.Exception.Message)" }
    if ($data -isnot [pscustomobject]) { throw "Existing hooks.json root must be an object; no changes made." }
    if ($data.PSObject.Properties["hooks"] -and $data.hooks -is [pscustomobject] -and $data.hooks.PSObject.Properties["UserPromptSubmit"]) {
        $data.hooks.UserPromptSubmit = @($data.hooks.UserPromptSubmit | Where-Object { ($_ | ConvertTo-Json -Depth 30 -Compress) -notmatch "mandatory-router" })
    }
    $newHooksJson = (($data | ConvertTo-Json -Depth 30) + "`r`n")
}
$backup = Join-Path $CodexHome ("backups\framework-v5-uninstall-" + (Get-Date -Format "yyyyMMdd-HHmmss-fff"))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$agentsFile = Join-Path $CodexHome "AGENTS.md"; $configFile = Join-Path $CodexHome "config.toml"
foreach ($item in @($agentsFile, $configFile, $hooksFile)) { if (Test-Path $item) { Copy-Item $item (Join-Path $backup ([IO.Path]::GetFileName($item))) -Force } }
if (Test-Path $agentsFile) {
    $text = [regex]::Replace([IO.File]::ReadAllText($agentsFile), '(?s)<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v5.*?<!-- CODEX-GLOBAL-FRAMEWORK:END v5 -->\s*', '').Trim()
    [IO.File]::WriteAllText($agentsFile, $(if ($text) { "$text`r`n" } else { "" }), [Text.UTF8Encoding]::new($false))
}
if (Test-Path $configFile) {
    $text = [regex]::Replace([IO.File]::ReadAllText($configFile), '(?s)# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS.*?# END CODEX GLOBAL FRAMEWORK V5 AGENTS\s*', '').TrimEnd()
    [IO.File]::WriteAllText($configFile, $(if ($text) { "$text`r`n" } else { "" }), [Text.UTF8Encoding]::new($false))
}
foreach ($role in $roles) {
    $path = Join-Path $CodexHome "agent-configs\$role.toml"
    if (Test-Path $path) { $destination = Join-Path $backup "agent-configs"; New-Item -ItemType Directory -Force -Path $destination | Out-Null; Move-Item $path $destination -Force }
}
foreach ($name in $skills) {
    $path = Join-Path $SkillsHome $name
    if (Test-Path $path) { $destination = Join-Path $backup "skills"; New-Item -ItemType Directory -Force -Path $destination | Out-Null; Move-Item $path $destination -Force }
}
if ($null -ne $newHooksJson) { [IO.File]::WriteAllText($hooksFile, $newHooksJson, [Text.UTF8Encoding]::new($false)) }
Remove-Item (Join-Path $CodexHome "hooks\mandatory-router.sh"), (Join-Path $CodexHome "hooks\mandatory-router.ps1") -Force -ErrorAction SilentlyContinue
Write-Host "Framework v5 removed. Backup: $backup"
