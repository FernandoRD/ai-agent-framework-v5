<#
.SYNOPSIS
    Script de instalação do Codex Global Framework v5.
.DESCRIPTION
    Instala políticas, agentes e especialistas de domínio do Framework v5 para Codex.
    Sem -AuditOnly, aplica as alterações (com backup). O plano completo é calculado antes;
    qualquer conflito aborta sem alterar arquivos. -AuditOnly apenas audita.
.PARAMETER Target
    Caminho do diretório do projeto para instalação local.
.PARAMETER Global
    Realiza a instalação no perfil global (~/.codex).
.PARAMETER Apply
    Aceito por compatibilidade; aplicar é o comportamento padrão (no-op). Incompatível com -AuditOnly.
.PARAMETER AuditOnly
    Modo estrito de auditoria (não escreve em disco; detecta conflitos).
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
    (aliases: -WithSreIncidentSpecialist)
    Instala a extensão opcional SRE Incident Specialist (Incident Command, SLOs).
.PARAMETER WithDbTuningSpecialist
    (aliases: -WithDatabaseTuningSpecialist)
    Instala a extensão opcional Database Tuning Specialist (PostgreSQL, queries, locks).
.PARAMETER WithProxmoxSpecialist
    Instala a extensão opcional Proxmox Specialist (Proxmox VE 8.x/9.x, Corosync, Ceph, SDN, ZFS).
.PARAMETER WithAllSpecialists
    Instala simultaneamente todos os 9 especialistas de domínio disponíveis.
.PARAMETER Help
    Exibe a mensagem de ajuda com todas as opções.
#>
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Target,

    [Alias("g")]
    [switch]$Global,

    [string]$CodexHome,
    [string]$SkillsHome,
    [switch]$NoHook,
    [switch]$AuditOnly,
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

    [Alias("WithSreIncidentSpecialist", "with-sre-specialist", "with-sre-incident-specialist")]
    [switch]$WithSreSpecialist,

    [Alias("WithDatabaseTuningSpecialist", "with-db-tuning-specialist", "with-database-tuning-specialist")]
    [switch]$WithDbTuningSpecialist,

    [Alias("with-proxmox-specialist")]
    [switch]$WithProxmoxSpecialist,

    [Alias("with-all-specialists")]
    [switch]$WithAllSpecialists,

    [Alias("h", "?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
function Show-Usage {
    Write-Host @"
Uso: .\install.ps1 [opções]

Sem -AuditOnly, o instalador APLICA as alterações (com backup). O plano
completo é calculado antes; qualquer conflito aborta sem alterar arquivos.

Opções gerais:
  -Target <dir>       Diretório de destino (instalação por projeto)
  -Global, -g         Instalação no ambiente global do usuário (~/.codex)
  -AuditOnly          Apenas audita: lista ações e conflitos, sem escrever
  -Apply              Aceito por compatibilidade; aplicar é o padrão (no-op)
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
  -WithProxmoxSpecialist         Instala o especialista Proxmox VE (PVE 8.x/9.x/Ceph/SDN/HA)
  -WithAllSpecialists            Instala todos os 9 especialistas de domínio acima
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
        try {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Optional package source contains a link or symlink: $($item.FullName)" }
            if ($item.PSIsContainer) { continue }
            $relative = $item.FullName.Substring($Source.Length).TrimStart('\', '/')
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
        } catch { $conflicts.Add($_.Exception.Message) }
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
if ([string]::IsNullOrWhiteSpace($homeDir)) { $homeDir = $HOME }
$homeFullPath = [IO.Path]::GetFullPath($homeDir)

# Expands ~, resolves relative paths against the current location (even if missing), drops trailing separators.
function Resolve-UserPath([string]$Path) {
    if ($Path -eq '~') { $Path = $homeFullPath }
    elseif ($Path -match '^~[\\/]') { $Path = Join-Path $homeFullPath $Path.Substring(2) }
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $root = [IO.Path]::GetPathRoot($full)
    if ($full.Length -gt $root.Length) { $full = $full.TrimEnd('\', '/') }
    return $full
}

# Real path (symlinks resolved per component) so a linked Skills root is recognized as the same directory.
# Needs PowerShell 7 (ResolveLinkTarget); on Windows PowerShell 5.1 it degrades to the unresolved path.
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

if ($Apply -and $AuditOnly) { throw "-Apply and -AuditOnly are mutually exclusive." }

$conflicts = [System.Collections.Generic.List[string]]::new()
$notices = [System.Collections.Generic.List[string]]::new()

function Complete-Plan {
    if ($conflicts.Count) { throw ("Conflicts detected; no files were changed:`n- " + ($conflicts -join "`n- ")) }
    foreach ($note in $notices) { Write-Host "NOTE: $note" }
}

function Test-MarkersBalanced([string]$Text, [string]$BeginRe, [string]$EndRe) {
    $inBlock = $false
    foreach ($line in ($Text -split "\r?\n")) {
        if ($line -match $BeginRe) { if ($inBlock) { return $false }; $inBlock = $true }
        elseif ($line -match $EndRe) { if (-not $inBlock) { return $false }; $inBlock = $false }
    }
    return (-not $inBlock)
}

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

# A legacy Skill is moved only when SKILL.md proves it belongs to the framework.
$frameworkSkillRe = '(luna|terra|sol)_(explorer|worker|reviewer|specialist|critical)|CODEX-GLOBAL-FRAMEWORK|Codex Global Framework|task-router'
function Test-FrameworkSkill([string]$Dir) {
    $file = Join-Path $Dir "SKILL.md"
    return ((Test-Path -LiteralPath $file -PathType Leaf) -and ([IO.File]::ReadAllText($file) -cmatch $frameworkSkillRe))
}

$allSpecs = @(
    @{ Name = "zabbix-specialist"; Enabled = ($WithZabbixSpecialist -or $WithAllSpecialists) }
    @{ Name = "grafana-specialist"; Enabled = ($WithGrafanaSpecialist -or $WithAllSpecialists) }
    @{ Name = "ansible-specialist"; Enabled = ($WithAnsibleSpecialist -or $WithAllSpecialists) }
    @{ Name = "loki-specialist"; Enabled = ($WithLokiSpecialist -or $WithAllSpecialists) }
    @{ Name = "prometheus-specialist"; Enabled = ($WithPrometheusSpecialist -or $WithAllSpecialists) }
    @{ Name = "netops-specialist"; Enabled = ($WithNetopsSpecialist -or $WithAllSpecialists) }
    @{ Name = "sre-incident-specialist"; Enabled = ($WithSreSpecialist -or $WithAllSpecialists) }
    @{ Name = "database-tuning-specialist"; Enabled = ($WithDbTuningSpecialist -or $WithAllSpecialists) }
    @{ Name = "proxmox-specialist"; Enabled = ($WithProxmoxSpecialist -or $WithAllSpecialists) }
)

$agentsBeginRe = '<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN'
$agentsEndRe = '<!-- CODEX-GLOBAL-FRAMEWORK:END'
function Get-NewAgentsContent([string]$AgentsFile, [string]$NewLine) {
    $existing = if (Test-Path -LiteralPath $AgentsFile) { [IO.File]::ReadAllText($AgentsFile) } else { "" }
    $personal = [regex]::Replace($existing, '(?s)<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN.*?<!-- CODEX-GLOBAL-FRAMEWORK:END.*?-->\s*', '').Trim()
    $block = [IO.File]::ReadAllText((Join-Path $packageDir ".codex\AGENTS.md")).Trim()
    if ($personal) { return "$personal$NewLine$NewLine$block$NewLine" }
    return "$block$NewLine"
}

# A Windows drive path becomes /mnt/<x>/... (assumes the default WSL automount root; not verified here).
function ConvertTo-ShPath([string]$Path) {
    if ($Path -match '^([A-Za-z]):[\\/](.*)$') { return "/mnt/" + $Matches[1].ToLower() + "/" + ($Matches[2] -replace '\\', '/') }
    return $Path
}

$isProject = $false
if (-not [string]::IsNullOrWhiteSpace($Target)) {
    $targetPath = Resolve-UserPath $Target
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
            if (-not (Test-MarkersBalanced $text $agentsBeginRe $agentsEndRe)) { $conflicts.Add("Unbalanced framework markers in $agentsFile; fix manually") }
        } else {
            Write-Host "- existing AGENTS: append framework block preserving personal text"
        }
    } else {
        Write-Host "- new AGENTS: create AGENTS.md with framework block"
    }
    $optionalPlan = @()
    foreach ($spec in $allSpecs) {
        if ($spec.Enabled) {
            $optSrc = Join-Path $packageDir ("optional\" + $spec.Name)
            if (-not (Test-Path -LiteralPath $optSrc -PathType Container)) { $conflicts.Add("Optional package missing: $optSrc"); continue }
            try { $optionalPlan += Get-OptionalInstallPlan $optSrc $targetPath } catch { $conflicts.Add($_.Exception.Message) }
        }
    }
    Complete-Plan
    if ($AuditOnly) {
        Write-Host "Audit-only mode: no files changed."
        exit 0
    }
    [IO.File]::WriteAllText($agentsFile, (Get-NewAgentsContent $agentsFile "`n"), [System.Text.Encoding]::UTF8)
    if ($optionalPlan.Count -gt 0) {
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
$fullCodexHome = Resolve-UserPath $CodexHome
$fullSkillsHome = Resolve-UserPath $SkillsHome
if ($fullCodexHome -eq [IO.Path]::GetPathRoot($fullCodexHome) -or $fullSkillsHome -eq [IO.Path]::GetPathRoot($fullSkillsHome)) {
    throw "Refusing unsafe target path."
}
$optionalPlan = @()
foreach ($spec in $allSpecs) {
    if ($spec.Enabled) {
        $optSrc = Join-Path $packageDir ("optional\" + $spec.Name + "\.agents\skills\" + $spec.Name)
        $optDest = Join-Path $fullSkillsHome $spec.Name
        if (-not (Test-Path -LiteralPath $optSrc -PathType Container)) { $conflicts.Add("Optional package missing: $optSrc"); continue }
        try { $optionalPlan += Get-OptionalInstallPlan $optSrc $optDest } catch { $conflicts.Add($_.Exception.Message) }
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
        if (-not (Test-MarkersBalanced $text $agentsBeginRe $agentsEndRe)) { $conflicts.Add("Unbalanced framework markers in $agentsFile; fix manually") }
    }
    if (Test-Path $standaloneDir) {
        foreach ($file in Get-ChildItem $standaloneDir -Force -File -Filter "*.toml") {
            $role = Get-AgentRole $file.FullName
            if ($roles.Contains($role) -or $roles.Contains([IO.Path]::GetFileNameWithoutExtension($file.Name))) {
                $items.Add([pscustomobject]@{ Category = "standalone agent"; Path = $file.FullName; Action = "backup; register explicitly" })
            }
        }
    }
    if (Test-Path $configFile) {
        $config = [IO.File]::ReadAllText($configFile)
        if (-not (Test-MarkersBalanced $config '# BEGIN CODEX GLOBAL FRAMEWORK V[345] AGENTS' '# END CODEX GLOBAL FRAMEWORK V[345] AGENTS')) { $conflicts.Add("Unbalanced framework markers in $configFile; fix manually") }
        foreach ($role in $roles.Keys) {
            if ($config -match "(?m)^\s*\[agents\.$([regex]::Escape($role))\]\s*$") { $items.Add([pscustomobject]@{ Category = "agent registration"; Path = "$configFile [$role]"; Action = "normalize to one v5 block" }) }
        }
    }
    if ((Test-Path $hooksFile) -and ([IO.File]::ReadAllText($hooksFile) -match "mandatory-router")) { $items.Add([pscustomobject]@{ Category = "routing hook"; Path = $hooksFile; Action = "replace framework hook" }) }
    return $items
}

# ---- Plan: hooks.json (validated before anything is written; ignored with -NoHook, like install.sh) ----
$newHooksJson = $null
if (-not $NoHook) {
    $hookDir = Join-Path $fullCodexHome "hooks"
    $hookData = $null
    if (Test-Path -LiteralPath $hooksFile) {
        try { $hookData = [IO.File]::ReadAllText($hooksFile) | ConvertFrom-Json } catch { $hookData = $null }
        if ($hookData -isnot [pscustomobject]) { $conflicts.Add("Existing hooks.json is invalid or unexpected; no changes made: $hooksFile"); $hookData = $null }
    } else { $hookData = [pscustomobject]@{ description = "User hooks."; hooks = [pscustomobject]@{} } }
    $hasGroups = $false
    if ($null -ne $hookData -and $hookData.PSObject.Properties["hooks"] -and $hookData.hooks -isnot [pscustomobject]) {
        $conflicts.Add("Existing hooks.json is invalid or unexpected; no changes made: $hooksFile"); $hookData = $null
    }
    if ($null -ne $hookData -and $hookData.PSObject.Properties["hooks"] -and $hookData.hooks.PSObject.Properties["UserPromptSubmit"]) {
        if ($hookData.hooks.UserPromptSubmit -isnot [array]) { $conflicts.Add("Existing hooks.json is invalid or unexpected; no changes made: $hooksFile"); $hookData = $null }
        else { $hasGroups = $true }
    }
    if ($null -ne $hookData) {
        if (-not $hookData.PSObject.Properties["hooks"]) { $hookData | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) }
        $groups = @()
        if ($hasGroups) { $groups = @($hookData.hooks.UserPromptSubmit | Where-Object { ($_ | ConvertTo-Json -Depth 30 -Compress) -notmatch "mandatory-router" }) }
        # command (POSIX sh) is what Linux/WSL run; commandWindows is what native Windows runs.
        # A Windows drive path is translated to /mnt/<x>/... for command (assumes the default WSL automount root; not verified here).
        $windowsCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $hookDir "mandatory-router.ps1") + '"'
        $shPath = Join-Path $hookDir "mandatory-router.sh"
        $shPath = ConvertTo-ShPath $shPath
        $shCommand = "sh '" + ($shPath -replace "'", "'\''") + "'"
        $groups += [pscustomobject]@{ hooks = @([pscustomobject]@{
            type = "command"; command = $shCommand
            commandWindows = $windowsCommand; timeout = 5; statusMessage = "Applying global routing policy"
        }) }
        if ($hasGroups) { $hookData.hooks.UserPromptSubmit = $groups } else { $hookData.hooks | Add-Member -NotePropertyName UserPromptSubmit -NotePropertyValue $groups }
        $newHooksJson = (($hookData | ConvertTo-Json -Depth 30) + "`r`n")
    }
}
if ($fullCodexHome -match '[\x00-\x1f]') { $conflicts.Add("CODEX_HOME contains control characters (refusing): $fullCodexHome") }

# ---- Plan: Skills (v5 names are reused only when identical; legacy names moved only when proven) ----
$skillFindings = [System.Collections.Generic.List[object]]::new()
$skillsToInstall = [System.Collections.Generic.List[string]]::new()
$legacyMoves = [System.Collections.Generic.List[object]]::new()
foreach ($name in $currentSkills) {
    $src = Join-Path $packageDir ".agents\skills\$name"
    $dest = Join-Path $fullSkillsHome $name
    if (Test-Link $dest) { $conflicts.Add("Skill is a link (refusing): $dest") }
    elseif (Test-Path -LiteralPath $dest) {
        if ((Test-Path -LiteralPath $dest -PathType Container) -and (Test-SameTree $src $dest)) {
            $skillFindings.Add([pscustomobject]@{ Category = "Skill v5"; Path = $dest; Action = "identical: reuse" })
        } else { $conflicts.Add("Skill conflict (content differs from v5; merge manually): $dest") }
    } else {
        $skillsToInstall.Add($name)
        $skillFindings.Add([pscustomobject]@{ Category = "Skill v5"; Path = $dest; Action = "install" })
    }
}
function Add-LegacySkillPlan([string]$Root, [string]$Label, [string]$Name) {
    $path = Join-Path $Root $Name
    if (-not (Test-Path -LiteralPath $path) -and -not (Test-Link $path)) { return }
    if ((Test-Link $path) -or -not (Test-Path -LiteralPath $path -PathType Container)) {
        $notices.Add("legacy Skill name is a link or not a directory; left intact: $path")
    } elseif ((($currentSkills -contains $Name) -and (Test-SameTree (Join-Path $packageDir ".agents\skills\$Name") $path)) -or (Test-FrameworkSkill $path)) {
        $legacyMoves.Add([pscustomobject]@{ Path = $path; Backup = "$Label\$Name" })
        $skillFindings.Add([pscustomobject]@{ Category = "legacy Skill"; Path = $path; Action = "move framework Skill to backup" })
    } else {
        $notices.Add("Skill '$Name' does not look like a framework Skill; left intact: $path")
    }
}
$sharedSkillsRoot = (Get-RealPath $legacyCodexSkills) -eq (Get-RealPath $fullSkillsHome)
if (-not $sharedSkillsRoot) {
    foreach ($name in $legacySkills) { Add-LegacySkillPlan $legacyCodexSkills "legacy-codex-skills" $name }
}
foreach ($name in $legacySkills) {
    if ($currentSkills -contains $name) { continue }
    Add-LegacySkillPlan $fullSkillsHome "user-skills" $name
}

$findings = @(Get-AuditFindings) + @($skillFindings)
Write-Host "Codex Global Framework v5 preflight"
Write-Host "Codex home: $fullCodexHome"
Write-Host "Skills home: $fullSkillsHome"
if ($findings.Count) { $findings | Format-Table Category, Action, Path -AutoSize } else { Write-Host "No v3/v4 residue detected." }
if ($optionalPlan.Count -or $WithAllSpecialists) { Write-Host "- optional specialists: $($optionalPlan.Count) file(s) to create" }
Complete-Plan
if ($AuditOnly) { Write-Host "Audit-only mode: no files changed."; return }

# ---- Compute new file contents (still no writes) ----
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
$newAgents = Get-NewAgentsContent $agentsFile "`r`n"

# ---- Apply ----
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

[IO.File]::WriteAllText($configFile, $config, [Text.UTF8Encoding]::new($false))

# Move only proven framework legacy Skills.
foreach ($move in $legacyMoves) {
    $destination = Join-Path $backupDir $move.Backup
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Move-Item -LiteralPath $move.Path -Destination $destination -Force
}
if (-not $sharedSkillsRoot -and (Test-Path -LiteralPath $legacyCodexSkills) -and -not (Test-Link $legacyCodexSkills) -and -not (Get-ChildItem -LiteralPath $legacyCodexSkills -Force -ErrorAction SilentlyContinue)) { Remove-Item -LiteralPath $legacyCodexSkills -Force }

# Install v5 Skills that are absent (identical ones are reused untouched).
foreach ($name in $skillsToInstall) { Copy-Item -LiteralPath (Join-Path $packageDir ".agents\skills\$name") -Destination (Join-Path $fullSkillsHome $name) -Recurse }
if ($optionalPlan.Count -gt 0) {
    Install-OptionalPlan $optionalPlan
    Write-Host "Optional Specialist installed: $($optionalPlan.Count) file(s)."
}

[IO.File]::WriteAllText($agentsFile, $newAgents, [Text.UTF8Encoding]::new($false))

if (-not $NoHook) {
    Copy-Item -LiteralPath (Join-Path $packageDir ".codex\hooks\mandatory-router.sh") -Destination (Join-Path $hookDir "mandatory-router.sh") -Force
    Copy-Item -LiteralPath (Join-Path $packageDir ".codex\hooks\mandatory-router.ps1") -Destination (Join-Path $hookDir "mandatory-router.ps1") -Force
    [IO.File]::WriteAllText($hooksFile, $newHooksJson, [Text.UTF8Encoding]::new($false))
}

Write-Host ""
Write-Host "Codex Global Framework v5 installed."
Write-Host "Backup: $backupDir"
if ((Test-Path $overrideFile) -and (Get-Item $overrideFile).Length -gt 0) { Write-Warning "AGENTS.override.md is non-empty and shadows global AGENTS.md; review it manually." }
Write-Host "Run: $PSScriptRoot\diagnose.ps1"
if (-not $NoHook) { Write-Host "Restart Codex, open /hooks, and trust the updated hook if requested." }
