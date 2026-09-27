[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Distro,
    [switch]$ShareWindowsCodexHome,
    [switch]$NoHook,
    [switch]$AuditOnly,
    [Alias("with-zabbix-specialist")]
    [switch]$WithZabbixSpecialist,
    [Alias("with-grafana-specialist")]
    [switch]$WithGrafanaSpecialist
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
$zabbixArg = if ($WithZabbixSpecialist) { " --with-zabbix-specialist" } else { "" }
$grafanaArg = if ($WithGrafanaSpecialist) { " --with-grafana-specialist" } else { "" }
$command = "$prefix cd '$linuxPackageDir' && bash ./scripts/install.sh$hookArg$auditArg$zabbixArg$grafanaArg"
& wsl.exe -d $Distro -- bash -lc $command
if ($LASTEXITCODE -ne 0) { throw "WSL installation failed with exit code $LASTEXITCODE." }
