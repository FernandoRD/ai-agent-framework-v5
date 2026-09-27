<#
.SYNOPSIS
    Script de instalação do Codex Global Framework v5.
.DESCRIPTION
    Instala políticas, agentes e especialistas de domínio do Framework v5 para Codex.
    Por padrão audita as alterações. Use -Apply para efetivar a instalação por projeto.
.PARAMETER Target
    Caminho do diretório do projeto para instalação local.
.PARAMETER Global
    Realiza a instalação no perfil global (~/.codex).
.PARAMETER Apply
    Aplica as alterações no disco.
.PARAMETER AuditOnly
    Modo estrito de auditoria.
.PARAMETER NoHook
    Não instala o hook de roteamento obrigatório.
.PARAMETER WithZabbixSpecialist
    Instala a extensão opcional Zabbix Specialist.
.PARAMETER WithGrafanaSpecialist
    Instala a extensão opcional Grafana Specialist (Grafana 12 / HTML Graphics).
.PARAMETER WithAnsibleSpecialist
    Instala a extensão opcional Ansible Specialist (Playbooks, Roles, Vault).
.PARAMETER WithLokiSpecialist
    Instala a extensão opcional Loki Specialist (LogQL, Promtail, Alloy).
.PARAMETER WithPrometheusSpecialist
    Instala a extensão opcional Prometheus Specialist (PromQL, Exporters, Alertmanager).
.PARAMETER WithNetopsSpecialist
    Instala a extensão opcional NetOps Specialist (SNMP, BGP, OSPF, VLANs).
.PARAMETER WithSreSpecialist
    Instala a extensão opcional SRE Incident Specialist (Incident Command, SLOs).
.PARAMETER WithDbTuningSpecialist
    Instala a extensão opcional Database Tuning Specialist (PostgreSQL, queries, locks).
.PARAMETER WithAllSpecialists
    Instala simultaneamente todos os 8 especialistas de domínio disponíveis.
.PARAMETER Help
    Exibe a mensagem de ajuda com todas as opções.
#>
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$false)]
    [Alias("target")]
    [string]$Target,

    [Alias("global", "g")]
    [switch]$Global,

    [string]$CodexHome,
    [string]$SkillsHome,
    [switch]$NoHook,
    [switch]$AuditOnly,
    [Alias("apply")]
    [switch]$Apply,

    [Alias("with-zabbix-specialist")]
    [switch]$WithZabbixSpecialist,

    [Alias("with-grafana-specialist")]
    [switch]$WithGrafanaSpecialist,

    [Alias("with-ansible-specialist")]
    [switch]$WithAnsibleSpecialist,

    [Alias("with-loki-specialist")]
    [switch]$WithLokiSpecialist,

    [Alias("with-prometheus-specialist")]
    [switch]$WithPrometheusSpecialist,

    [Alias("with-netops-specialist")]
    [switch]$WithNetopsSpecialist,

    [Alias("with-sre-specialist", "with-sre-incident-specialist")]
    [switch]$WithSreSpecialist,

    [Alias("with-db-tuning-specialist", "with-database-tuning-specialist")]
    [switch]$WithDbTuningSpecialist,

    [Alias("with-all-specialists")]
    [switch]$WithAllSpecialists,

    [Alias("h", "?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
function Show-Usage {
    Write-Host @"
Uso: .\install.ps1 [opções]

Opções gerais:
  -Target <dir>       Diretório de destino (instalação por projeto)
  -Global, -g         Instalação no ambiente global do usuário (~/.codex)
  -Apply              Aplica as alterações no disco (padrão é auditoria)
  -AuditOnly          Modo estrito de auditoria (não altera arquivos)
  -NoHook             Não instala o hook de roteamento obrigatório
  -CodexHome <dir>    Sobrescreve o diretório ~/.codex
  -SkillsHome <dir>   Sobrescreve o diretório ~/.agents/skills
  -Help, -h, -?       Exibe esta mensagem de ajuda

Especialistas de domínio opcionais:
  -WithZabbixSpecialist          Instala o especialista Zabbix
  -WithGrafanaSpecialist         Instala o especialista Grafana (Grafana 12 / HTML Graphics)
  -WithAnsibleSpecialist         Instala o especialista Ansible (playbooks/roles/vault)
  -WithLokiSpecialist            Instala o especialista Loki (LogQL/Promtail/Alloy)
  -WithPrometheusSpecialist      Instala o especialista Prometheus (PromQL/exporters/alerting)
  -WithNetopsSpecialist          Instala o especialista NetOps (SNMP/BGP/OSPF/VLANs)
  -WithSreSpecialist             Instala o especialista SRE Incident (Incident Command/SLOs)
                                 (alias: -WithSreIncidentSpecialist)
  -WithDbTuningSpecialist        Instala o especialista Database Tuning (PostgreSQL/queries/locks)
                                 (alias: -WithDatabaseTuningSpecialist)
  -WithAllSpecialists            Instala todos os 8 especialistas de domínio acima
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

$packageDir = Split-Path -Parent $PSScriptRoot

function Assert-OptionalDirectory([string]$Path, [string]$Label) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "$Label contains a link or symlink: $current" }
            if (-not $item.PSIsContainer) { throw "$Label is not a directory: $current" }
        }
        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $current) { break }
        $current = $parent
    }
}

function Get-OptionalInstallPlan([string]$Source, [string]$Destination) {
    Assert-OptionalDirectory $Source "Optional package source"
    Assert-OptionalDirectory $Destination "Optional package destination"
    $plan = @()
    foreach ($item in @(Get-ChildItem -LiteralPath $Source -Recurse -Force)) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Optional package source contains a link or symlink: $($item.FullName)" }
        if ($item.PSIsContainer) { continue }
        $relative = $item.FullName.Substring($Source.Length).TrimStart('\\', '/')
        $target = Join-Path $Destination $relative
        Assert-OptionalDirectory (Split-Path -Parent $target) "Optional package destination"
        if (Test-Path -LiteralPath $target) {
            $existing = Get-Item -LiteralPath $target -Force
            if (($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Optional package destination contains a link or symlink: $target" }
            if ($existing.PSIsContainer) { throw "Optional package conflict (expected file): $target" }
            if ($existing.Length -ne $item.Length -or (Get-FileHash -LiteralPath $existing.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash) { throw "Optional package conflict: $target" }
            continue
        }
        $plan += [pscustomobject]@{ Source = $item.FullName; Destination = $target }
    }
    return $plan
}

function Install-OptionalPlan([object[]]$Plan) {
    foreach ($entry in $Plan) {
        $parent = Split-Path -Parent $entry.Destination
        Assert-OptionalDirectory $parent "Optional package destination"
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -ErrorAction Stop | Out-Null }
        [IO.File]::Copy($entry.Source, $entry.Destination, $false)
    }
}

$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { [Environment]::GetFolderPath('UserProfile') }
$homeFullPath = [IO.Path]::GetFullPath($homeDir)

$isProject = $false
if (-not [string]::IsNullOrWhiteSpace($Target)) {
    $targetPath = [IO.Path]::GetFullPath($Target)
    if (-not $Global -and ($targetPath.TrimEnd('\', '/') -ne $homeFullPath.TrimEnd('\', '/'))) {
        $isProject = $true
    }
}

if ($isProject) {
    if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
        throw "Target directory does not exist or is not a directory: $targetPath"
    }
    $agentsFile = Join-Path $targetPath "AGENTS.md"
    Write-Host "Codex Framework v5 project preflight"
    Write-Host "Project target: $targetPath"
    Write-Host "Agents file: $agentsFile"
    if (Test-Path -LiteralPath $agentsFile) {
        $text = [IO.File]::ReadAllText($agentsFile)
        if ($text -match 'CODEX-GLOBAL-FRAMEWORK:BEGIN') {
            Write-Host "- legacy/existing AGENTS: replace marked framework block"
        } else {
            Write-Host "- existing AGENTS: append framework block preserving personal text"
        }
    } else {
        Write-Host "- new AGENTS: create AGENTS.md with framework block"
    }
    $optionalPlan = @()
    $allSpecs = @(
        @{ Name = "zabbix-specialist"; Enabled = ($WithZabbixSpecialist -or $WithAllSpecialists) }
        @{ Name = "grafana-specialist"; Enabled = ($WithGrafanaSpecialist -or $WithAllSpecialists) }
        @{ Name = "ansible-specialist"; Enabled = ($WithAnsibleSpecialist -or $WithAllSpecialists) }
        @{ Name = "loki-specialist"; Enabled = ($WithLokiSpecialist -or $WithAllSpecialists) }
        @{ Name = "prometheus-specialist"; Enabled = ($WithPrometheusSpecialist -or $WithAllSpecialists) }
        @{ Name = "netops-specialist"; Enabled = ($WithNetopsSpecialist -or $WithAllSpecialists) }
        @{ Name = "sre-incident-specialist"; Enabled = ($WithSreSpecialist -or $WithAllSpecialists) }
        @{ Name = "database-tuning-specialist"; Enabled = ($WithDbTuningSpecialist -or $WithAllSpecialists) }
    )
    foreach ($spec in $allSpecs) {
        if ($spec.Enabled) {
            $optSrc = Join-Path $packageDir ("optional\" + $spec.Name)
            if (Test-Path -LiteralPath $optSrc -PathType Container) {
                $optionalPlan += Get-OptionalInstallPlan $optSrc $targetPath
            }
        }
    }
    if ($AuditOnly) {
        Write-Host "Audit-only mode: no files changed."
        exit 0
    }
    $existing = if (Test-Path -LiteralPath $agentsFile) { [IO.File]::ReadAllText($agentsFile) } else { "" }
    $personal = [regex]::Replace($existing, '(?s)<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN.*?<!-- CODEX-GLOBAL-FRAMEWORK:END.*?-->\s*', '').Trim()
    $packageAgents = Join-Path $packageDir ".codex\AGENTS.md"
    $block = [IO.File]::ReadAllText($packageAgents).Trim()
    $finalContent = if ($personal) { "$personal`n`n$block`n" } else { "$block`n" }
    [IO.File]::WriteAllText($agentsFile, $finalContent, [System.Text.Encoding]::UTF8)
    if ($WithZabbixSpecialist -or $WithGrafanaSpecialist) {
        Install-OptionalPlan $optionalPlan
        Write-Host "Optional Specialist installed: $($optionalPlan.Count) file(s)."
    }
    Write-Host "`nCodex Framework v5 installed for project: $targetPath"
    exit 0
}

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    $CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeFullPath ".codex" }
}
if ([string]::IsNullOrWhiteSpace($SkillsHome)) {
    $SkillsHome = Join-Path $homeFullPath ".agents\skills"
}
$fullCodexHome = [IO.Path]::GetFullPath($CodexHome)
$fullSkillsHome = [IO.Path]::GetFullPath($SkillsHome)
if ($fullCodexHome -eq [IO.Path]::GetPathRoot($fullCodexHome) -or $fullSkillsHome -eq [IO.Path]::GetPathRoot($fullSkillsHome)) {
    throw "Refusing unsafe target path."
}
$optionalPlan = @()
if (-not $isProject) {
    $allSpecs = @(
        @{ Name = "zabbix-specialist"; Enabled = ($WithZabbixSpecialist -or $WithAllSpecialists) }
        @{ Name = "grafana-specialist"; Enabled = ($WithGrafanaSpecialist -or $WithAllSpecialists) }
        @{ Name = "ansible-specialist"; Enabled = ($WithAnsibleSpecialist -or $WithAllSpecialists) }
        @{ Name = "loki-specialist"; Enabled = ($WithLokiSpecialist -or $WithAllSpecialists) }
        @{ Name = "prometheus-specialist"; Enabled = ($WithPrometheusSpecialist -or $WithAllSpecialists) }
        @{ Name = "netops-specialist"; Enabled = ($WithNetopsSpecialist -or $WithAllSpecialists) }
        @{ Name = "sre-incident-specialist"; Enabled = ($WithSreSpecialist -or $WithAllSpecialists) }
        @{ Name = "database-tuning-specialist"; Enabled = ($WithDbTuningSpecialist -or $WithAllSpecialists) }
    )
    foreach ($spec in $allSpecs) {
        if ($spec.Enabled) {
            $optSrc = Join-Path $packageDir ("optional\" + $spec.Name + "\.agents\skills\" + $spec.Name)
            $optDest = Join-Path $fullSkillsHome $spec.Name
            if (Test-Path -LiteralPath $optSrc -PathType Container) {
                $optionalPlan += Get-OptionalInstallPlan $optSrc $optDest
            }
        }
    }
}

$roles = [ordered]@{
    luna_explorer  = "Low-cost read-only explorer for targeted codebase mapping and compact context capsules."
    luna_worker    = "Efficient worker for narrow, well-specified, low-risk implementation and mechanical tasks."
    terra_worker   = "Balanced implementation worker for normal engineering changes across related files."
    terra_reviewer = "Independent read-only reviewer for correctness, regressions, and missing tests."
    sol_specialist = "High-capability specialist for difficult implementation and ambiguous multi-step reasoning."
    sol_reviewer   = "Independent read-only reviewer for complex or high-risk engineering changes."
    sol_critical   = "Read-only critical analyst for security boundaries, data loss, concurrency, and production incidents."
}
$legacySkills = @("task-router", "complexity-score", "deep-analysis", "implementation", "testing", "refactor", "final-review", "model-usage-report", "security-review", "code-review", "dependency-review", "documentation")
$currentSkills = @("security-review", "code-review", "dependency-review", "documentation")
$agentsFile = Join-Path $fullCodexHome "AGENTS.md"
$overrideFile = Join-Path $fullCodexHome "AGENTS.override.md"
$configFile = Join-Path $fullCodexHome "config.toml"
$hooksFile = Join-Path $fullCodexHome "hooks.json"
$standaloneDir = Join-Path $fullCodexHome "agents"
$layerDir = Join-Path $fullCodexHome "agent-configs"
$legacyCodexSkills = Join-Path $fullCodexHome "skills"

function Get-AgentRole([string]$Path) {
    $text = [IO.File]::ReadAllText($Path)
    if ($text -match '(?m)^\s*name\s*=\s*"([^"]+)"') { return $Matches[1] }
    return [IO.Path]::GetFileNameWithoutExtension($Path)
}

function Get-AuditFindings {
    $items = [System.Collections.Generic.List[object]]::new()
    if ((Test-Path $overrideFile) -and (Get-Item $overrideFile).Length -gt 0) {
        $items.Add([pscustomobject]@{ Category = "shadow"; Path = $overrideFile; Action = "manual review required" })
    }
    if (Test-Path $agentsFile) {
        $text = [IO.File]::ReadAllText($agentsFile)
        if ($text -match 'CODEX-GLOBAL-FRAMEWORK:BEGIN v[1-4]') { $items.Add([pscustomobject]@{ Category = "legacy AGENTS"; Path = $agentsFile; Action = "replace marked framework block" }) }
        if ($text -match '(?i)task-router' -and $text -notmatch 'CODEX-GLOBAL-FRAMEWORK:BEGIN') { $items.Add([pscustomobject]@{ Category = "unmarked AGENTS"; Path = $agentsFile; Action = "preserve and warn for manual review" }) }
    }
    if (Test-Path $standaloneDir) {
        foreach ($file in Get-ChildItem $standaloneDir -Force -File -Filter "*.toml") {
            $role = Get-AgentRole $file.FullName
            if ($roles.Contains($role) -or $roles.Contains([IO.Path]::GetFileNameWithoutExtension($file.Name))) {
                $items.Add([pscustomobject]@{ Category = "standalone agent"; Path = $file.FullName; Action = "backup; register explicitly" })
            }
        }
    }
    foreach ($root in @($legacyCodexSkills, $fullSkillsHome)) {
        foreach ($name in $legacySkills) {
            $path = Join-Path $root $name
            if (Test-Path $path) {
                $action = if ($currentSkills -contains $name -and $root -eq $fullSkillsHome) { "backup and replace with v5" } else { "move legacy Skill to backup" }
                $items.Add([pscustomobject]@{ Category = "legacy Skill"; Path = $path; Action = $action })
            }
        }
    }
    if (Test-Path $configFile) {
        $config = [IO.File]::ReadAllText($configFile)
        foreach ($role in $roles.Keys) {
            if ($config -match "(?m)^\s*\[agents\.$([regex]::Escape($role))\]\s*$") { $items.Add([pscustomobject]@{ Category = "agent registration"; Path = "$configFile [$role]"; Action = "normalize to one v5 block" }) }
        }
    }
    if ((Test-Path $hooksFile) -and ([IO.File]::ReadAllText($hooksFile) -match "mandatory-router")) { $items.Add([pscustomobject]@{ Category = "routing hook"; Path = $hooksFile; Action = "replace framework hook" }) }
    return $items
}

if (Test-Path $hooksFile) {
    try { $null = [IO.File]::ReadAllText($hooksFile) | ConvertFrom-Json }
    catch { throw "Existing hooks.json is invalid; no changes made. $($_.Exception.Message)" }
}
$findings = @(Get-AuditFindings)
Write-Host "Codex Global Framework v5 preflight"
Write-Host "Codex home: $fullCodexHome"
Write-Host "Skills home: $fullSkillsHome"
if ($findings.Count) { $findings | Format-Table Category, Action, Path -AutoSize } else { Write-Host "No v3/v4 residue detected." }
if ($AuditOnly) { Write-Host "Audit-only mode: no files changed."; return }

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
$backupDir = Join-Path $fullCodexHome "backups\framework-v5-$timestamp"
New-Item -ItemType Directory -Force -Path $fullCodexHome, $fullSkillsHome, $standaloneDir, $layerDir, (Join-Path $fullCodexHome "hooks"), $backupDir | Out-Null
function Backup-Path([string]$Source, [string]$RelativeDestination) {
    if (Test-Path -LiteralPath $Source) {
        $destination = Join-Path $backupDir $RelativeDestination
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
        Copy-Item -LiteralPath $Source -Destination $destination -Recurse -Force
    }
}
Backup-Path $agentsFile "codex\AGENTS.md"
Backup-Path $configFile "codex\config.toml"
Backup-Path $hooksFile "codex\hooks.json"

# Clean every framework standalone definition by its internal role name.
foreach ($file in @(Get-ChildItem $standaloneDir -Force -File -Filter "*.toml" -ErrorAction SilentlyContinue)) {
    $role = Get-AgentRole $file.FullName
    if ($roles.Contains($role) -or $roles.Contains([IO.Path]::GetFileNameWithoutExtension($file.Name))) {
        $destinationDir = Join-Path $backupDir "codex\standalone-agents"
        New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
        Move-Item -LiteralPath $file.FullName -Destination (Join-Path $destinationDir $file.Name) -Force
    }
}

# Install configuration layers outside the auto-discovery directory.
foreach ($role in $roles.Keys) {
    $target = Join-Path $layerDir "$role.toml"
    Backup-Path $target "codex\agent-configs\$role.toml"
    Copy-Item -LiteralPath (Join-Path $packageDir ".codex\agent-configs\$role.toml") -Destination $target -Force
}

# Normalize exact framework role tables and register each role once.
$config = if (Test-Path $configFile) { [IO.File]::ReadAllText($configFile) } else { "" }
$config = [regex]::Replace($config, '(?s)# BEGIN CODEX GLOBAL FRAMEWORK V[345] AGENTS.*?# END CODEX GLOBAL FRAMEWORK V[345] AGENTS\s*', '')
foreach ($role in $roles.Keys) {
    $escaped = [regex]::Escape($role)
    $config = [regex]::Replace($config, "(?ms)^\s*\[agents\.$escaped\]\s*\r?\n.*?(?=^\s*\[|\z)", "")
}
$registration = [System.Collections.Generic.List[string]]::new()
$registration.Add("# BEGIN CODEX GLOBAL FRAMEWORK V5 AGENTS")
foreach ($role in $roles.Keys) {
    $registration.Add(""); $registration.Add("[agents.$role]")
    $registration.Add('description = "' + $roles[$role] + '"')
    $registration.Add('config_file = "agent-configs/' + $role + '.toml"')
}
$registration.Add(""); $registration.Add("# END CODEX GLOBAL FRAMEWORK V5 AGENTS")
$config = $config.TrimEnd()
if ($config) { $config += "`r`n`r`n" }
$config += ($registration -join "`r`n") + "`r`n"
[IO.File]::WriteAllText($configFile, $config, [Text.UTF8Encoding]::new($false))

# Move only known framework Skills, including legacy ~/.codex/skills copies.
foreach ($rootEntry in @(
    [pscustomobject]@{ Root = $legacyCodexSkills; Backup = "legacy-codex-skills" },
    [pscustomobject]@{ Root = $fullSkillsHome; Backup = "user-skills" }
)) {
    foreach ($name in $legacySkills) {
        $target = Join-Path $rootEntry.Root $name
        if (Test-Path -LiteralPath $target) {
            $destination = Join-Path $backupDir "$($rootEntry.Backup)\$name"
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
            Move-Item -LiteralPath $target -Destination $destination -Force
        }
    }
    if ((Test-Path $rootEntry.Root) -and -not (Get-ChildItem $rootEntry.Root -Force -ErrorAction SilentlyContinue)) { Remove-Item -LiteralPath $rootEntry.Root -Force }
}
New-Item -ItemType Directory -Force -Path $fullSkillsHome | Out-Null
foreach ($name in $currentSkills) { Copy-Item -LiteralPath (Join-Path $packageDir ".agents\skills\$name") -Destination (Join-Path $fullSkillsHome $name) -Recurse -Force }
if ($WithZabbixSpecialist -or $WithGrafanaSpecialist) {
    Install-OptionalPlan $optionalPlan
    Write-Host "Optional Specialist installed: $($optionalPlan.Count) file(s)."
}

# Replace only marked framework AGENTS content and preserve personal text.
$block = [IO.File]::ReadAllText((Join-Path $packageDir ".codex\AGENTS.md")).Trim()
$existing = if (Test-Path $agentsFile) { [IO.File]::ReadAllText($agentsFile) } else { "" }
$personal = [regex]::Replace($existing, '(?s)<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN.*?<!-- CODEX-GLOBAL-FRAMEWORK:END.*?-->\s*', '').Trim()
$content = if ($personal) { "$personal`r`n`r`n$block`r`n" } else { "$block`r`n" }
[IO.File]::WriteAllText($agentsFile, $content, [Text.UTF8Encoding]::new($false))

if (-not $NoHook) {
    $hookDir = Join-Path $fullCodexHome "hooks"
    Copy-Item -LiteralPath (Join-Path $packageDir ".codex\hooks\mandatory-router.sh") -Destination (Join-Path $hookDir "mandatory-router.sh") -Force
    Copy-Item -LiteralPath (Join-Path $packageDir ".codex\hooks\mandatory-router.ps1") -Destination (Join-Path $hookDir "mandatory-router.ps1") -Force
    if (Test-Path $hooksFile) {
        try { $hookData = [IO.File]::ReadAllText($hooksFile) | ConvertFrom-Json } catch { throw "Existing hooks.json is invalid; original is in $backupDir. $($_.Exception.Message)" }
    } else { $hookData = [pscustomobject]@{ description = "User hooks."; hooks = [pscustomobject]@{} } }
    if (-not $hookData.PSObject.Properties["hooks"]) { $hookData | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) }
    $groups = @()
    if ($hookData.hooks.PSObject.Properties["UserPromptSubmit"]) { $groups = @($hookData.hooks.UserPromptSubmit | Where-Object { ($_ | ConvertTo-Json -Depth 30 -Compress) -notmatch "mandatory-router" }) }
    $windowsCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $hookDir "mandatory-router.ps1") + '"'
    $groups += [pscustomobject]@{ hooks = @([pscustomobject]@{
        type = "command"; command = 'sh "${CODEX_HOME:-$HOME/.codex}/hooks/mandatory-router.sh"'
        commandWindows = $windowsCommand; timeout = 5; statusMessage = "Applying global routing policy"
    }) }
    if ($hookData.hooks.PSObject.Properties["UserPromptSubmit"]) { $hookData.hooks.UserPromptSubmit = $groups } else { $hookData.hooks | Add-Member -NotePropertyName UserPromptSubmit -NotePropertyValue $groups }
    [IO.File]::WriteAllText($hooksFile, (($hookData | ConvertTo-Json -Depth 30) + "`r`n"), [Text.UTF8Encoding]::new($false))
}

Write-Host ""
Write-Host "Codex Global Framework v5 installed."
Write-Host "Backup: $backupDir"
if ((Test-Path $overrideFile) -and (Get-Item $overrideFile).Length -gt 0) { Write-Warning "AGENTS.override.md is non-empty and shadows global AGENTS.md; review it manually." }
Write-Host "Run: $PSScriptRoot\diagnose.ps1"
if (-not $NoHook) { Write-Host "Restart Codex, open /hooks, and trust the updated hook if requested." }
