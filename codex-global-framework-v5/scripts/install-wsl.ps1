<#
.SYNOPSIS
    Script de instalação do Codex Framework no WSL a partir do Windows.
.DESCRIPTION
    Encaminha os comandos e flags de instalação para o ambiente Linux sob WSL.
.PARAMETER Distro
    Nome da distribuição WSL de destino (obrigatório).
.PARAMETER Help
    Exibe a mensagem de ajuda com todas as opções.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Distro,
    [switch]$ShareWindowsCodexHome,
    [switch]$NoHook,
    [switch]$AuditOnly,
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
Uso: .\install-wsl.ps1 -Distro <nome-da-distro> [opções]

Opções gerais:
  -Distro <nome>             Nome da distribuição WSL (obrigatório)
  -ShareWindowsCodexHome     Compartilha a configuração do Windows com o WSL
  -NoHook                    Não instala o hook de roteamento obrigatório
  -AuditOnly                 Apenas audita (não altera arquivos); sem ele, aplica
  -Help, -h, -?              Exibe esta mensagem de ajuda

Especialistas de domínio opcionais:
  -WithZabbixSpecialist      Instala o especialista Zabbix
  -WithGrafanaSpecialist     Instala o especialista Grafana (Grafana 12 / HTML Graphics)
  -WithAnsibleSpecialist     Instala o especialista Ansible (playbooks/roles/vault)
  -WithLokiSpecialist        Instala o especialista Loki (LogQL/Promtail/Alloy)
  -WithPrometheusSpecialist  Instala o especialista Prometheus (PromQL/exporters/alerting)
  -WithNetopsSpecialist      Instala o especialista NetOps (SNMP/BGP/OSPF/VLANs)
  -WithSreSpecialist         Instala o especialista SRE Incident (Incident Command/SLOs)
                             (alias: -WithSreIncidentSpecialist)
  -WithDbTuningSpecialist    Instala o especialista Database Tuning (PostgreSQL/queries/locks)
                             (alias: -WithDatabaseTuningSpecialist)
  -WithProxmoxSpecialist     Instala o especialista Proxmox VE (PVE 8.x/9.x/Ceph/SDN/HA)
  -WithAllSpecialists        Instala todos os 9 especialistas de domínio acima
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

$packageDir = Split-Path -Parent $PSScriptRoot
$linuxPackageDir = (& wsl.exe -d $Distro -- wslpath -a $packageDir).Trim()
if (-not $linuxPackageDir) { throw "Could not translate the package path for WSL." }
$prefix = ""
if ($ShareWindowsCodexHome) {
    $windowsCodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
    $linuxCodexHome = (& wsl.exe -d $Distro -- wslpath -a $windowsCodexHome).Trim()
    $prefix = "export CODEX_HOME='$linuxCodexHome'; "
}
$hookArg = if ($NoHook) { " --no-hook" } else { "" }
$auditArg = if ($AuditOnly) { " --audit-only" } else { "" }
$specArgs = ""
if ($WithZabbixSpecialist -or $WithAllSpecialists) { $specArgs += " --with-zabbix-specialist" }
if ($WithGrafanaSpecialist -or $WithAllSpecialists) { $specArgs += " --with-grafana-specialist" }
if ($WithAnsibleSpecialist -or $WithAllSpecialists) { $specArgs += " --with-ansible-specialist" }
if ($WithLokiSpecialist -or $WithAllSpecialists) { $specArgs += " --with-loki-specialist" }
if ($WithPrometheusSpecialist -or $WithAllSpecialists) { $specArgs += " --with-prometheus-specialist" }
if ($WithNetopsSpecialist -or $WithAllSpecialists) { $specArgs += " --with-netops-specialist" }
if ($WithSreSpecialist -or $WithAllSpecialists) { $specArgs += " --with-sre-specialist" }
if ($WithDbTuningSpecialist -or $WithAllSpecialists) { $specArgs += " --with-db-tuning-specialist" }
if ($WithProxmoxSpecialist -or $WithAllSpecialists) { $specArgs += " --with-proxmox-specialist" }
$command = "$prefix cd '$linuxPackageDir' && bash ./scripts/install.sh$hookArg$auditArg$specArgs"
& wsl.exe -d $Distro -- bash -lc $command
if ($LASTEXITCODE -ne 0) { throw "WSL installation failed with exit code $LASTEXITCODE." }
