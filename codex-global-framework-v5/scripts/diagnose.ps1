[CmdletBinding()]
param(
    [string]$CodexHome,
    [string]$SkillsHome
)
$errors = 0; $warnings = 0
function Ok([string]$Message) { Write-Host "OK    $Message" }
function Warn([string]$Message) { Write-Host "WARN  $Message"; $script:warnings++ }
function Fail([string]$Message) { Write-Host "FAIL  $Message"; $script:errors++ }

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
# Real path (symlinks resolved per component), as in install.ps1.
function Get-RealPath([string]$Path) {
    $full = Resolve-UserPath $Path
    $root = [IO.Path]::GetPathRoot($full)
    $real = $root
    foreach ($part in @($full.Substring($root.Length).Split([char[]]@('\', '/')) | Where-Object { $_ })) {
        $real = Join-Path $real $part
        $item = Get-Item -LiteralPath $real -Force -ErrorAction SilentlyContinue
        if ($item -and $item.PSObject.Methods['ResolveLinkTarget'] -and $item.LinkTarget) {
            $target = $item.ResolveLinkTarget($true)
            if ($target) { $real = $target.FullName }
        }
    }
    return $real
}
if ([string]::IsNullOrWhiteSpace($CodexHome)) { $CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeFullPath ".codex" } }
if ([string]::IsNullOrWhiteSpace($SkillsHome)) { $SkillsHome = Join-Path $homeFullPath ".agents\skills" }

$roles = @("luna_explorer", "luna_worker", "terra_worker", "terra_reviewer", "sol_specialist", "sol_reviewer", "sol_critical")
$legacyOnlySkills = @("task-router", "complexity-score", "deep-analysis", "implementation", "testing", "refactor", "final-review", "model-usage-report")
$currentSkills = @("security-review", "code-review", "dependency-review", "documentation")
$CodexHome = Resolve-UserPath $CodexHome; $SkillsHome = Resolve-UserPath $SkillsHome
Write-Host "Codex home: $CodexHome"; Write-Host "Skills home: $SkillsHome`n"

$agentsFile = Join-Path $CodexHome "AGENTS.md"
if ((Test-Path $agentsFile) -and (Select-String $agentsFile -Pattern "CODEX-GLOBAL-FRAMEWORK:BEGIN v5" -Quiet)) { Ok "v5 block found in AGENTS.md" } else { Fail "v5 block missing from AGENTS.md" }
$override = Join-Path $CodexHome "AGENTS.override.md"
if ((Test-Path $override) -and (Get-Item $override).Length -gt 0) { Fail "non-empty AGENTS.override.md shadows AGENTS.md" } else { Ok "no global AGENTS.override.md shadow" }

$configFile = Join-Path $CodexHome "config.toml"
$config = if (Test-Path $configFile) { [IO.File]::ReadAllText($configFile) } else { "" }
if ($config -match "# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS") { Ok "v5 agent registration block found" } else { Fail "v5 agent registration block missing" }
foreach ($role in $roles) {
    $count = ([regex]::Matches($config, "(?m)^\s*\[agents\.$([regex]::Escape($role))\]\s*$")).Count
    if ($count -eq 1) { Ok "one registration for $role" } elseif ($count -eq 0) { Fail "missing registration for $role" } else { Fail "duplicate registrations for $role ($count)" }
    $layer = Join-Path $CodexHome "agent-configs\$role.toml"
    if (Test-Path $layer) {
        $layerText = [IO.File]::ReadAllText($layer)
        if ($layerText -match '(?m)^\s*(name|description)\s*=') { Fail "layer $role contains standalone-only name/description" } else { Ok "agent layer $role" }
    } else { Fail "missing agent layer $role" }
}

$standaloneDir = Join-Path $CodexHome "agents"
if (Test-Path $standaloneDir) {
    foreach ($file in Get-ChildItem $standaloneDir -Force -File -Filter "*.toml") {
        $text = [IO.File]::ReadAllText($file.FullName)
        $role = if ($text -match '(?m)^\s*name\s*=\s*"([^"]+)"') { $Matches[1] } else { $file.BaseName }
        if ($roles -contains $role -or $roles -contains $file.BaseName) { Fail "duplicate-prone standalone framework agent: $($file.FullName)" }
    }
}

foreach ($name in $currentSkills) {
    $skill = Join-Path $SkillsHome "$name\SKILL.md"
    if ((Test-Path $skill) -and (Select-String $skill -Pattern "name: $name" -Quiet)) { Ok "skill $name" } else { Fail "missing or invalid skill $name" }
}
foreach ($name in $legacyOnlySkills) {
    if (Test-Path (Join-Path $SkillsHome $name)) { Warn "legacy-named user Skill present (left intact by the installer unless proven framework-owned): $name" }
    if (Test-Path (Join-Path $CodexHome "skills\$name")) { Warn "legacy-named .codex/skills copy present (left intact unless proven framework-owned): $name" }
}
# Same comparison as Test-SameTree in install.ps1 (files and directories; any link makes the trees differ).
function Test-Link([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    return ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
}
function Get-TreeMap([string]$Root) {
    $map = @{}
    $base = $Root.TrimEnd('\', '/').Length + 1
    foreach ($item in @(Get-ChildItem -LiteralPath $Root -Recurse -Force)) {
        if (Test-Link $item.FullName) { return $null }
        $rel = $item.FullName.Substring($base).Replace('\', '/')
        $map[$rel] = if ($item.PSIsContainer) { "<dir>" } else { (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash }
    }
    return $map
}
function Test-SameTree([string]$A, [string]$B) {
    $ma = Get-TreeMap $A; $mb = Get-TreeMap $B
    if ($null -eq $ma -or $null -eq $mb -or $ma.Count -ne $mb.Count) { return $false }
    foreach ($key in $ma.Keys) { if (-not $mb.ContainsKey($key) -or $mb[$key] -ne $ma[$key]) { return $false } }
    return $true
}
$packageDir = Split-Path -Parent $PSScriptRoot
$frameworkSkillRe = '(luna|terra|sol)_(explorer|worker|reviewer|specialist|critical)|CODEX-GLOBAL-FRAMEWORK|Codex Global Framework|task-router'
foreach ($name in $currentSkills) {
    $legacyCopy = Join-Path $CodexHome "skills\$name"
    if ((Test-Path -LiteralPath $legacyCopy) -and ((Get-RealPath $legacyCopy) -ne (Get-RealPath (Join-Path $SkillsHome $name)))) {
        # Same rule as the installer: identical or framework-owned copies are moved; a divergent one is kept.
        $skillMd = Join-Path $legacyCopy "SKILL.md"
        $identical = (Test-Path -LiteralPath $legacyCopy -PathType Container) -and (Test-SameTree (Join-Path $packageDir ".agents\skills\$name") $legacyCopy)
        if ($identical -or ((Test-Path -LiteralPath $skillMd) -and ([IO.File]::ReadAllText($skillMd) -cmatch $frameworkSkillRe))) { Fail "duplicate legacy .codex/skills copy remains: $name" }
        else { Warn "divergent .codex/skills/$name kept by the installer (merge or remove manually)" }
    }
}

$hooksFile = Join-Path $CodexHome "hooks.json"
if (Test-Path $hooksFile) {
    try { $hookData = [IO.File]::ReadAllText($hooksFile) | ConvertFrom-Json; Ok "hooks.json is valid JSON" } catch { Fail "hooks.json is invalid"; $hookData = $null }
    $frameworkHooks = @()
    if ($hookData -and $hookData.hooks.PSObject.Properties["UserPromptSubmit"]) {
        $frameworkHooks = @($hookData.hooks.UserPromptSubmit | Where-Object { ($_ | ConvertTo-Json -Depth 30 -Compress) -match "mandatory-router" })
    }
    if ($frameworkHooks.Count -eq 1) { Ok "exactly one routing reminder hook is configured" } elseif ($frameworkHooks.Count -eq 0) { Warn "routing hook absent; AGENTS.md still works" } else { Fail "duplicate routing hooks: $($frameworkHooks.Count)" }
} else { Warn "hooks.json absent; AGENTS.md still works" }
$hookScript = Join-Path $CodexHome "hooks\mandatory-router.ps1"
if (Test-Path $hookScript) {
    try { $result = & $hookScript | ConvertFrom-Json; if ($result.hookSpecificOutput.hookEventName -eq "UserPromptSubmit") { Ok "routing hook output is valid" } else { Fail "routing hook event is wrong" } } catch { Fail "routing hook output is invalid" }
}
if ($config -match '(?m)^\s*hooks\s*=\s*false\s*$') { Warn "hooks disabled in config.toml" }
if ($config -match '(?m)^\s*multi_agent\s*=\s*false\s*$') { Warn "multi-agent is disabled in config.toml" }

Write-Host ""
if ($errors) { Write-Host "Result: FAIL ($errors error(s), $warnings warning(s))"; exit 1 }
if ($warnings) { Write-Host "Result: WARN ($warnings warning(s))" } else { Write-Host "Result: OK" }
Write-Host "Restart Codex after installation. Use /hooks to verify UserPromptSubmit is Active."
