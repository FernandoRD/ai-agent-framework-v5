[CmdletBinding()]
param(
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }),
    [string]$SkillsHome = $(Join-Path $env:USERPROFILE ".agents\skills")
)
$ErrorActionPreference = "Stop"
$roles = @("luna_explorer", "luna_worker", "terra_worker", "terra_reviewer", "sol_specialist", "sol_reviewer", "sol_critical")
$skills = @("security-review", "code-review", "dependency-review", "documentation")
$backup = Join-Path $CodexHome ("backups\framework-v5-uninstall-" + (Get-Date -Format "yyyyMMdd-HHmmss-fff"))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$agentsFile = Join-Path $CodexHome "AGENTS.md"; $configFile = Join-Path $CodexHome "config.toml"; $hooksFile = Join-Path $CodexHome "hooks.json"
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
if (Test-Path $hooksFile) {
    $data = [IO.File]::ReadAllText($hooksFile) | ConvertFrom-Json
    if ($data.hooks.PSObject.Properties["UserPromptSubmit"]) { $data.hooks.UserPromptSubmit = @($data.hooks.UserPromptSubmit | Where-Object { ($_ | ConvertTo-Json -Depth 30 -Compress) -notmatch "mandatory-router" }) }
    [IO.File]::WriteAllText($hooksFile, (($data | ConvertTo-Json -Depth 30) + "`r`n"), [Text.UTF8Encoding]::new($false))
}
Remove-Item (Join-Path $CodexHome "hooks\mandatory-router.sh"), (Join-Path $CodexHome "hooks\mandatory-router.ps1") -Force -ErrorAction SilentlyContinue
Write-Host "Framework v5 removed. Backup: $backup"
