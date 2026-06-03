#Requires -Version 5.1
<#
.SYNOPSIS
    Limpeza Profunda do Windows v2.0
.DESCRIPTION
    Limpeza completa de arquivos temporarios, caches, logs,
    navegadores, Hermes, Windows Update, e tudo que ocupa espaco.
.NOTES
    Criado por OWL - 2026
    Execute como Administrador para maximo resultado.
#>

$ErrorActionPreference = "Continue"
$VerbosePreference = "SilentlyContinue"

$script:totalFilesRemoved = 0
$script:totalSizeFreed = 0
$script:errors = @()
$script:startTime = Get-Date

$script:report = [System.Text.StringBuilder]::new()
$null = $report.AppendLine("=" * 60)
$null = $report.AppendLine(" LIMPEZA PROFUNDA DO WINDOWS - RELATORIO")
$null = $report.AppendLine(" Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')")
$null = $report.AppendLine("=" * 60)
$null = $report.AppendLine("")

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $prefix = switch ($Status) {
        "OK"    { "[OK]   "; $color = "Green" }
        "WARN"  { "[WARN] "; $color = "Yellow" }
        "ERROR" { "[ERRO] "; $color = "Red" }
        "INFO"  { "[INFO] "; $color = "Cyan" }
        default { "[...]  "; $color = "White" }
    }
    Write-Host "$prefix$Message" -ForegroundColor $color
}

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        return $size
    }
    return 0
}

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes bytes"
}

function Remove-DirContents {
    param([string]$Path, [string]$Description = "conteudo")
    try {
        if (Test-Path $Path) {
            $before = Get-FolderSize -Path $Path
            $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue
            $count = ($items | Measure-Object).Count
            if ($count -gt 0) {
                Remove-Item -Path "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
                $after = Get-FolderSize -Path $Path
                $freed = $before - $after
                $script:totalFilesRemoved += $count
                $script:totalSizeFreed += $freed
                $null = $report.AppendLine("  [OK] $Description : $count itens liberando $(Format-Size $freed)")
                return @{ Count = $count; Freed = $freed }
            }
        }
    } catch { $script:errors += $_.Exception.Message }
    return @{ Count = 0; Freed = 0 }
}

function Remove-FilesByPattern {
    param([string]$Path, [string]$Filter = "*", [string]$Description = "arquivos")
    try {
        $items = Get-ChildItem -Path $Path -Filter $Filter -Recurse -Force -ErrorAction SilentlyContinue
        $count = ($items | Measure-Object).Count
        $totalSize = ($items | Measure-Object -Property Length -Sum).Sum
        if ($count -gt 0) {
            $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            $script:totalFilesRemoved += $count
            $script:totalSizeFreed += $totalSize
            $null = $report.AppendLine("  [OK] $Description : $count arquivos liberando $(Format-Size $totalSize)")
        }
        return $count
    } catch { return 0 }
}

# Verificar admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

Clear-Host
Write-Host ""
Write-Host "  ====================================================" -ForegroundColor Cyan
Write-Host "     LIMPEZA PROFUNDA DO WINDOWS v2.0" -ForegroundColor Cyan
Write-Host "     Criado por OWL - 2026" -ForegroundColor Cyan
Write-Host "  ====================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $isAdmin) {
    Write-Status "Executando SEM privilegios de administrador!" "WARN"
    Write-Status "Recomenda-se executar como Admin para maximo resultado." "WARN"
    Write-Host ""
}
$null = $report.AppendLine("ADMIN: $(if($isAdmin){'SIM'}else{'NAO'})")
$null = $report.AppendLine("")


# ===== 1. LIXEIRA =====
Write-Host "--- 1/22: Lixeira ----------------------------------------" -ForegroundColor DarkGray
try {
    $shell = New-Object -ComObject Shell.Application
    $rb = $shell.NameSpace(0x0a)
    $rbCount = $rb.Items().Count
    Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
    del C:\$Recycle.Bin\* -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    Write-Status "Lixeira: $rbCount itens removidos" "OK"
    $null = $report.AppendLine("[1] LIXEIRA : $rbCount itens removidos")
} catch { Write-Status "Lixeira falhou: $($_.Exception.Message)" "ERROR" }

# ===== 2. TEMP DOS USUARIOS =====
Write-Host "--- 2/22: Temp dos Usuarios ------------------------------" -ForegroundColor DarkGray
$null = $report.AppendLine("")
$null = $report.AppendLine("[2] TEMP DOS USUARIOS")
foreach ($userDir in Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue) {
    $tempPath = Join-Path $userDir.FullName "AppData\Local\Temp"
    if (Test-Path $tempPath) {
        $r = Remove-DirContents -Path $tempPath -Description "Temp $($userDir.Name)"
    }
}
# Windows Temp
$wt = "C:\Windows\Temp"
if (Test-Path $wt) {
    $r = Remove-DirContents -Path $wt -Description "Windows Temp"
}

# ===== 3. LOGS DO WINDOWS =====
Write-Host "--- 3/22: Logs do Windows --------------------------------" -ForegroundColor DarkGray
$null = $report.AppendLine("")
$null = $report.AppendLine("[3] LOGS DO WINDOWS")
$logPaths = @(
    "C:\Windows\Logs\CBS\*.log",
    "C:\Windows\Logs\MoSetup\*.log",
    "C:\Windows\Logs\DISM\*.log",
    "C:\Windows\Panther\*.log",
    "C:\Windows\Performance\WinSAT\winsat.log",
    "C:\Windows\Inf\*.log",
    "C:\Windows\Setup\*.log",
    "C:\Windows\SoftwareDistribution\*.log",
    "C:\Windows\Microsoft.NET\*.log",
    "C:\Windows\Logs\MeasuredBoot\*.log",
    "C:\Windows\logs\*.log"
)
$logCount = 0
foreach ($lp in $logPaths) {
    $items = Get-ChildItem -Path $lp -Recurse -Force -ErrorAction SilentlyContinue
    $c = ($items | Measure-Object).Count
    if ($c -gt 0) {
        $items | Remove-Item -Force -ErrorAction SilentlyContinue
        $logCount += $c
        $script:totalFilesRemoved += $c
    }
}
# MpCmdRun
foreach (@("LocalService","NetworkService") | ForEach-Object {
    $mp = "C:\Windows\ServiceProfiles\$_\AppData\Local\Temp\MpCmdRun.log"
    if (Test-Path $mp) { Remove-Item $mp -Force -ErrorAction SilentlyContinue; $logCount++ }
})
Write-Status "Logs: $logCount arquivos removidos" "OK"
$null = $report.AppendLine("  $logCount arquivos de log removidos")

# ===== 4. DUMP / CRASH =====
Write-Host "--- 4/22: Dump / Crash Files -----------------------------" -ForegroundColor DarkGray
$null = $report.AppendLine("")
$null = $report.AppendLine("[4] DUMP / CRASH")
$dumpCount = 0
foreach ($userDir in Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue) {
    $dumpPath = Join-Path $userDir.FullName "AppData\Local\CrashDumps"
    if (Test-Path $dumpPath) {
        $items = Get-ChildItem -Path $dumpPath -Filter "*.dmp" -Force -ErrorAction SilentlyContinue
        $before = ($items | Measure-Object -Property Length -Sum).Sum
        $c = ($items | Measure-Object).Count
        if ($c -gt 0) {
            $items | Remove-Item -Force -ErrorAction SilentlyContinue
            $dumpCount += $c
            $script:totalFilesRemoved += $c
            $script:totalSizeFreed += $before
        }
    }
}
Write-Status "Dumps: $dumpCount removidos" "OK"
$null = $report.AppendLine("  $dumpCount dumps removidos")

