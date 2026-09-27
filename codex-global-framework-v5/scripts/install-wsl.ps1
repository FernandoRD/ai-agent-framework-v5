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
    [Alias("with-sre-specialist")]
    [switch]$WithSreSpecialist,
    [Alias("with-db-tuning-specialist")]
    [switch]$WithDbTuningSpecialist,
    [Alias("with-all-specialists")]
    [switch]$WithAllSpecialists
)
$ErrorActionPreference = "Stop"
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
$command = "$prefix cd '$linuxPackageDir' && bash ./scripts/install.sh$hookArg$auditArg$specArgs"
& wsl.exe -d $Distro -- bash -lc $command
if ($LASTEXITCODE -ne 0) { throw "WSL installation failed with exit code $LASTEXITCODE." }
