[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$false)]
    [Alias("target")]
    [string]$Target,

    [Alias("global", "g")]
    [switch]$Global,

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
    [switch]$WithAllSpecialists
)

$ErrorActionPreference = "Stop"

if (-not $Global -and [string]::IsNullOrWhiteSpace($Target)) {
    Write-Host "Uso: .\install.ps1 -Target <caminho> [-Apply]"
    Write-Host "     .\install.ps1 -Global [-Apply]"
    Write-Host "     .\install.ps1 --target <caminho> [--apply]"
    Write-Host "     .\install.ps1 --global [--apply]"
    exit 1
}

$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { [Environment]::GetFolderPath('UserProfile') }
$homeFullPath = [IO.Path]::GetFullPath($homeDir)

if ($Global) {
    $targetPath = if ([string]::IsNullOrWhiteSpace($Target)) { $homeFullPath } else { [IO.Path]::GetFullPath($Target) }
    $isGlobal = $true
} else {
    $targetPath = [IO.Path]::GetFullPath($Target)
    $isGlobal = ($targetPath.TrimEnd('\', '/') -eq $homeFullPath.TrimEnd('\', '/'))
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
)

foreach ($spec in $knownSpecialists) {
    if ($spec.Enabled) {
        $opt = Join-Path (Split-Path -Parent $scriptDir) ("optional\" + $spec.Name + "\payload")
        if (-not (Test-Path -LiteralPath $opt -PathType Container)) {
            throw "Pacote opcional não encontrado em $opt"
        }
        $payloadDirs += [IO.Path]::GetFullPath($opt)
    }
}

if (-not (Test-Path -LiteralPath $payloadDir)) {
    Write-Error "Diretório de payload não encontrado em $payloadDir"
    exit 1
}

$toolDotDir = $null
foreach ($d in (Get-ChildItem -LiteralPath $payloadDir -Directory)) {
    if ($d.Name.StartsWith(".")) {
        $toolDotDir = $d.Name
        break
    }
}

$pending = [System.Collections.Generic.List[object]]::new()
$errors = [System.Collections.Generic.List[string]]::new()

function Test-IsSymlink([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    $item = Get-Item -LiteralPath $path -Force
    return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Check-ChainForSymlinks([string]$path) {
    $current = $path
    while (-not [string]::IsNullOrWhiteSpace($current)) {
        if (Test-IsSymlink $current) { return $true }
        $parent = Split-Path -Parent $current
        if ($parent -eq $current) { break }
        $current = $parent
    }
    return $false
}

$files = foreach ($payloadRoot in $payloadDirs) { Get-ChildItem -LiteralPath $payloadRoot -Recurse -Force }
foreach ($item in ($files | Sort-Object FullName)) {
    if (Test-IsSymlink $item.FullName) {
        $errors.Add("Link no pacote: $($item.FullName)")
        continue
    }
    if ($item.PSIsContainer) {
        continue
    }

    $payloadRoot = $payloadDirs | Where-Object { $item.FullName.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) } | Sort-Object Length -Descending | Select-Object -First 1
    $relPath = $item.FullName.Substring($payloadRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    if ($isGlobal -and $toolDotDir -and -not $relPath.StartsWith(".")) {
        $dest = [IO.Path]::Combine($targetPath, $toolDotDir, $relPath)
    } else {
        $dest = [IO.Path]::Combine($targetPath, $relPath)
    }

    if (Check-ChainForSymlinks $dest) {
        $errors.Add("Link no destino: $dest")
        continue
    }

    $destParent = Split-Path -Parent $dest
    $curParent = $destParent
    $parentInvalid = $false
    while (-not [string]::IsNullOrWhiteSpace($curParent)) {
        if ((Test-Path -LiteralPath $curParent) -and -not (Test-Path -LiteralPath $curParent -PathType Container)) {
            $errors.Add("Pai não é diretório: $dest")
            $parentInvalid = $true
            break
        }
        $p = Split-Path -Parent $curParent
        if ($p -eq $curParent) { break }
        $curParent = $p
    }
    if ($parentInvalid) { continue }

    if (Test-Path -LiteralPath $dest) {
        if (Test-Path -LiteralPath $dest -PathType Container) {
            $errors.Add("Conflito, preservar e mesclar manualmente: $dest")
        } else {
            $srcBytes = [IO.File]::ReadAllBytes($item.FullName)
            $destBytes = [IO.File]::ReadAllBytes($dest)
            $identical = ($srcBytes.Length -eq $destBytes.Length)
            if ($identical) {
                for ($i = 0; $i -lt $srcBytes.Length; $i++) {
                    if ($srcBytes[$i] -ne $destBytes[$i]) {
                        $identical = $false
                        break
                    }
                }
            }
            if (-not $identical) {
                $errors.Add("Conflito, preservar e mesclar manualmente: $dest")
            } else {
                Write-Host "IDÊNTICO $dest"
            }
        }
    } else {
        $pending.Add(@{ Source = $item.FullName; Dest = $dest })
        Write-Host "CRIAR $dest"
    }
}

if ($errors.Count -gt 0) {
    foreach ($err in $errors) {
        Write-Host $err
    }
    exit 1
}

if (-not $Apply) {
    Write-Host "Auditoria: $($pending.Count) arquivo(s) novo(s); nenhuma alteração."
    exit 0
}

foreach ($entry in $pending) {
    $src = $entry.Source
    $dest = $entry.Dest
    if (Check-ChainForSymlinks $dest) {
        Write-Host "Destino tornou-se link; instalação interrompida: $dest"
        exit 1
    }
    $parentDir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $parentDir)) {
        [IO.Directory]::CreateDirectory($parentDir) | Out-Null
    }
    try {
        $srcBytes = [IO.File]::ReadAllBytes($src)
        $fs = [IO.File]::Open($dest, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $fs.Write($srcBytes, 0, $srcBytes.Length)
        } finally {
            $fs.Dispose()
        }
    } catch {
        Write-Host "Falha ao criar arquivo: $dest ($($_.Exception.Message))"
        exit 1
    }
}

Write-Host "Instalados $($pending.Count) arquivo(s). Configurações existentes preservadas."
