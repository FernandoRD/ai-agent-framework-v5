<#
.SYNOPSIS
    Script de instalação do Framework v5.
.DESCRIPTION
    Instala as políticas, agentes e especialistas de domínio do Framework v5.
    Por padrão executa em modo de auditoria (sem modificar arquivos). Use -Apply para efetivar.
.PARAMETER Target
    Caminho do diretório do projeto para instalação local.
.PARAMETER Global
    Realiza a instalação no perfil global do usuário.
.PARAMETER Apply
    Aplica as alterações no disco (padrão é apenas auditoria).
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
.PARAMETER WithProxmoxSpecialist
    Instala a extensão opcional Proxmox Specialist (Proxmox VE 8.x/9.x, Corosync, Ceph, SDN, ZFS).
.PARAMETER WithShellPythonSpecialist
    Instala a extensão opcional Shell & Python Specialist (Bash, POSIX sh, fish, Python 3.10+).
.PARAMETER WithDockerKubernetesSpecialist
    Instala a extensão opcional Docker & Kubernetes Specialist (Docker Engine, Compose v2, Kubernetes, Helm).
.PARAMETER WithAllSpecialists
    Instala simultaneamente todos os 11 especialistas de domínio disponíveis.
.PARAMETER Help
    Exibe a mensagem de ajuda com todas as opções.
#>
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Target,

    [Alias("g")]
    [switch]$Global,

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

    [Alias("with-proxmox-specialist")]
    [switch]$WithProxmoxSpecialist,

    [Alias("with-shell-python-specialist")]
    [switch]$WithShellPythonSpecialist,

    [Alias("with-docker-kubernetes-specialist")]
    [switch]$WithDockerKubernetesSpecialist,

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
  -Target <caminho>   Diretório de destino (instalação por projeto)
  -Global, -g         Instalação no ambiente global do usuário
  -Apply              Aplica as alterações no disco (padrão é apenas auditoria)
  -Help, -h, -?       Exibe esta mensagem de ajuda

Especialistas de domínio opcionais:
  -WithZabbixSpecialist          Instala o especialista Zabbix
  -WithGrafanaSpecialist         Instala o especialista Grafana (Grafana 12 / HTML Graphics)
  -WithAnsibleSpecialist         Instala o especialista Ansible (playbooks/roles/vault)
  -WithLokiSpecialist            Instala o especialista Loki (LogQL/Promtail/Alloy)
  -WithPrometheusSpecialist      Instala o especialista Prometheus (PromQL/exporters/alerting)
  -WithNetopsSpecialist          Instala o especialista NetOps (SNMP/BGP/OSPF/VLANs)
  -WithSreSpecialist             Instala o especialista SRE Incident (Incident Command/SLOs)
                                 (alias: -with-sre-specialist, -with-sre-incident-specialist)
  -WithDbTuningSpecialist        Instala o especialista Database Tuning (PostgreSQL/queries/locks)
                                 (alias: -with-db-tuning-specialist, -with-database-tuning-specialist)
  -WithProxmoxSpecialist         Instala o especialista Proxmox VE (PVE 8.x/9.x/Ceph/SDN/HA)
  -WithShellPythonSpecialist     Instala o especialista Shell & Python (Bash/POSIX sh/Python 3.10+)
  -WithDockerKubernetesSpecialist
                                 Instala o especialista Docker & Kubernetes (Compose/K8s/Helm)
  -WithAllSpecialists            Instala todos os 11 especialistas de domínio acima
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

if ($PSBoundParameters.ContainsKey('Target') -and [string]::IsNullOrWhiteSpace($Target)) {
    [Console]::Error.WriteLine("Erro: -Target exige um caminho.")
    Show-Usage
    exit 1
}

if (-not $Global -and [string]::IsNullOrWhiteSpace($Target)) {
    Show-Usage
    exit 1
}

$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { [Environment]::GetFolderPath('UserProfile') }
$homeFullPath = [IO.Path]::GetFullPath($homeDir)

function Resolve-TargetPath([string]$Path) {
    # Uses the PowerShell location (not the .NET process directory) and expands ~.
    if ($Path -eq '~' -or $Path.StartsWith('~/') -or $Path.StartsWith('~\')) {
        $Path = Join-Path $homeFullPath $Path.Substring(1).TrimStart('\', '/')
    }
    $full = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
    $root = [IO.Path]::GetPathRoot($full)
    if ($full.Length -gt $root.Length) { $full = $full.TrimEnd('\', '/') }
    return $full
}

if ($Global) {
    $targetPath = if ([string]::IsNullOrWhiteSpace($Target)) { $homeFullPath } else { Resolve-TargetPath $Target }
    $isGlobal = $true
} else {
    $targetPath = Resolve-TargetPath $Target
    $isGlobal = ($targetPath.TrimEnd('\', '/') -eq $homeFullPath.TrimEnd('\', '/'))
}

# Safety check: refuse a filesystem/drive root (parity with install.sh refusing '/')
if ($targetPath -eq [IO.Path]::GetPathRoot($targetPath)) {
    [Console]::Error.WriteLine("Erro: Recusando instalar no caminho raiz '$targetPath'.")
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$payloadDir = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $scriptDir) "payload"))
$payloadDirs = @($payloadDir)
$knownSpecialists = @(
    @{ Name = "zabbix-specialist"; Enabled = ($WithZabbixSpecialist -or $WithAllSpecialists) }
    @{ Name = "grafana-specialist"; Enabled = ($WithGrafanaSpecialist -or $WithAllSpecialists) }
    @{ Name = "ansible-specialist"; Enabled = ($WithAnsibleSpecialist -or $WithAllSpecialists) }
    @{ Name = "loki-specialist"; Enabled = ($WithLokiSpecialist -or $WithAllSpecialists) }
    @{ Name = "prometheus-specialist"; Enabled = ($WithPrometheusSpecialist -or $WithAllSpecialists) }
    @{ Name = "netops-specialist"; Enabled = ($WithNetopsSpecialist -or $WithAllSpecialists) }
    @{ Name = "sre-incident-specialist"; Enabled = ($WithSreSpecialist -or $WithAllSpecialists) }
    @{ Name = "database-tuning-specialist"; Enabled = ($WithDbTuningSpecialist -or $WithAllSpecialists) }
    @{ Name = "proxmox-specialist"; Enabled = ($WithProxmoxSpecialist -or $WithAllSpecialists) }
    @{ Name = "shell-python-specialist"; Enabled = ($WithShellPythonSpecialist -or $WithAllSpecialists) }
    @{ Name = "docker-kubernetes-specialist"; Enabled = ($WithDockerKubernetesSpecialist -or $WithAllSpecialists) }
)

foreach ($spec in $knownSpecialists) {
    if ($spec.Enabled) {
        $p = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $scriptDir) "optional/$($spec.Name)/payload"))
        if (-not (Test-Path -LiteralPath $p)) {
            throw "Pacote opcional não encontrado: $p"
        }
        $payloadDirs += $p
    }
}

$toolDotDir = ""
foreach ($item in (Get-ChildItem -LiteralPath $payloadDir -Force)) {
    if ($item.PSIsContainer -and $item.Name.StartsWith('.')) {
        $toolDotDir = $item.Name
        break
    }
}

function Test-PathForSymlinks([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                return $true
            }
        }
        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $current) { break }
        $current = $parent
    }
    return $false
}

function Test-ParentInvalid([string]$Path) {
    $parent = Split-Path -Parent $Path
    while ($true) {
        if (Test-Path -LiteralPath $parent) {
            $item = Get-Item -LiteralPath $parent -Force
            if (-not $item.PSIsContainer) { return $true }
            return $false
        }
        $nextParent = Split-Path -Parent $parent
        if ([string]::IsNullOrEmpty($nextParent) -or $nextParent -eq $parent) { break }
        $parent = $nextParent
    }
    return $false
}

if (Test-PathForSymlinks $targetPath) {
    throw "Target path or parent is a symlink: $targetPath"
}

$errors = @()
$pendingSources = @()
$pendingDests = @()

foreach ($dir in $payloadDirs) {
    $files = Get-ChildItem -LiteralPath $dir -Recurse -File -Force | Sort-Object FullName
    foreach ($file in $files) {
        if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            $errors += "Link no pacote: $($file.FullName)"
            continue
        }
        $sourceRel = $file.FullName.Substring($dir.Length).TrimStart('\', '/')
        $firstPart = $sourceRel.Split('\/')[0]

        if ($isGlobal -and (-not [string]::IsNullOrEmpty($toolDotDir)) -and (-not $firstPart.StartsWith('.'))) {
            $dest = Join-Path $targetPath (Join-Path $toolDotDir $sourceRel)
        } else {
            $dest = Join-Path $targetPath $sourceRel
        }

        if (Test-PathForSymlinks $dest) {
            $errors += "Link no destino: $dest"
            continue
        }

        if (Test-ParentInvalid $dest) {
            $errors += "Pai não é diretório: $dest"
            continue
        }

        if (Test-Path -LiteralPath $dest) {
            $destItem = Get-Item -LiteralPath $dest -Force
            if ($destItem.PSIsContainer) {
                $errors += "Conflito, preservar e mesclar manualmente: $dest"
                continue
            }
            $srcHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            $destHash = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
            if ($srcHash -ne $destHash) {
                $errors += "Conflito, preservar e mesclar manualmente: $dest"
            } else {
                Write-Host "IDÊNTICO $dest"
            }
        } else {
            $pendingSources += $file.FullName
            $pendingDests += $dest
            Write-Host "CRIAR $dest"
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($err in $errors) { Write-Host $err }
    exit 1
}

if (-not $Apply) {
    Write-Host "Auditoria: $($pendingSources.Count) arquivo(s) novo(s); nenhuma alteração."
    exit 0
}

for ($i = 0; $i -lt $pendingSources.Count; $i++) {
    $src = $pendingSources[$i]
    $dest = $pendingDests[$i]

    if (Test-PathForSymlinks $dest) {
        throw "Destino tornou-se link; instalação interrompida: $dest"
    }

    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $fileStream = $null
    try {
        $sourceBytes = [IO.File]::ReadAllBytes($src)
        $fileStream = New-Object IO.FileStream($dest, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $fileStream.Write($sourceBytes, 0, $sourceBytes.Length)
    } catch {
        throw "Falha ao criar arquivo (conflito ou erro de gravação): $dest"
    } finally {
        if ($fileStream -ne $null) { $fileStream.Dispose() }
    }
}

Write-Host "Instalados $($pendingSources.Count) arquivo(s). Configurações existentes preservadas."
