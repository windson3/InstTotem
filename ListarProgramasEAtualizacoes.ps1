#Requires -Version 5.0
<#
.SYNOPSIS
    Lista IDs completos e unicos de programas instalados e atualizacoes do Windows.
.DESCRIPTION
    Estrategia multi-fonte para obter IDs completos (sem truncamento):
      1. winget list                   -> Nome + ID + Source (todos os programas)
      2. Get-AppxPackage               -> resolve IDs MSIX completos (PackageFullName)
      3. winget list --name "<nome>"   -> resolve IDs restantes via busca por nome
    Secao 2: atualizacoes/hotfixes (Get-HotFix + WMI + Update.Session API).
    Gera: C:\inst\maquina\ListaProgramasEAtualizacao.txt
.NOTES
    Requer winget (App Installer). PowerShell 5.0+.
    Os IDs de programas MSIX/WindowsAppRuntime podem conter espacos no nome
    interno do pacote — sao exibidos conforme registrado pelo sistema.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================================
#  1. DIRETORIO DE DESTINO
# ============================================================================
$destDir = "C:\inst\maquina"
if (!(Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}
$outFile = Join-Path $destDir "ListaProgramasEAtualizacao.txt"

# ============================================================================
#  2. LISTAR PROGRAMAS — ESTRATEGIA MULTI-FONTE
# ============================================================================
Write-Host "Coletando programas instalados..." -ForegroundColor Cyan

# --- 2a. Parse do winget list ---
Function Parse-WingetList {
    param([string[]]$Output)

    $hIdx = -1
    for ($i = 0; $i -lt $Output.Count; $i++) {
        if ($Output[$i].TrimStart() -match '^Nome') { $hIdx = $i; break }
    }
    if ($hIdx -lt 0) { return @{} }

    $hLine = $Output[$hIdx]
    $idPos  = $hLine.IndexOf("ID")
    $verPos = $hLine.IndexOf("Ver")
    $origPos = $hLine.IndexOf("Origem")
    $fieldW = $verPos - $idPos; if ($fieldW -le 0) { $fieldW = 48 }

    $result = @{}
    $inData = $false

    for ($j = $hIdx + 1; $j -lt $Output.Count; $j++) {
        $line = $Output[$j]
        if ($line -match '^-{10,}') { $inData = $true; continue }
        if (!$inData) { continue }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $name = $line.Substring(0, [Math]::Min($idPos, $line.Length)).TrimEnd()
        $idRaw = ""
        if ($line.Length -gt $idPos) {
            $idRaw = $line.Substring($idPos, [Math]::Min($fieldW, $line.Length - $idPos)).Trim()
        }
        $idTok = ($idRaw -split '\s+')[0].Trim()
        $src = ""
        if ($origPos -gt 0 -and $line.Length -gt $origPos) {
            $src = $line.Substring($origPos).Trim()
        }

        # Skip pure version tokens (name overflow into ID column)
        if ($idTok -match '^[0-9.]+$' -and $idTok -notmatch '[a-zA-Z\\]') { continue }
        if (!$name -or !$idTok -or $idTok -eq "ID") { continue }

        if (!$result.ContainsKey($name)) {
            $result[$name] = @{ ID = $idTok; Src = $src }
        }
    }
    return $result
}

$allPrograms = Parse-WingetList -Output (& winget list --accept-source-agreements 2>&1)
Write-Host "  winget list: $($allPrograms.Count) programas" -ForegroundColor Gray

# --- 2b. Carregar AppxPackage para cruzamento ---
$appxMap = @{}
try {
    Get-AppxPackage | ForEach-Object {
        $pkgName = ($_.PackageFullName -split '_')[0]
        if (!$appxMap.ContainsKey($pkgName) -or $_.PackageFullName.Length -gt $appxMap[$pkgName].Length) {
            $appxMap[$pkgName] = $_.PackageFullName
        }
    }
}
catch { }
Write-Host "  AppxPackage : $($appxMap.Count) pacotes carregados" -ForegroundColor Gray

# --- 2c. Resolver IDs truncados ---
$resolvedAppx = 0
$resolvedName = 0

$msixEntries = @($allPrograms.GetEnumerator() | Where-Object { !$_.Value.Src })

foreach ($entry in $msixEntries) {
    $name  = $entry.Key
    $idTok = $entry.Value.ID

    # Extrai nome base do pacote MSIX\Publisher.AppName_version...
    $idClean = $idTok -replace '^MSIX\\', ''
    $pkgBase = ($idClean -split '_')[0]

    # Estrategia A: cruzar com AppxPackage
    if ($appxMap.ContainsKey($pkgBase)) {
        $allPrograms[$name].ID = $appxMap[$pkgBase]
        $resolvedAppx++
        continue
    }

    # Estrategia B: winget list --name "<nome>"
    $searchResult = & winget list --name "$name" --accept-source-agreements 2>&1
    $srHdr = -1
    for ($si = 0; $si -lt $searchResult.Count; $si++) {
        if ($searchResult[$si].TrimStart() -match '^Nome') { $srHdr = $si; break }
    }
    if ($srHdr -ge 0) {
        $srH = $searchResult[$srHdr]
        $srId = $srH.IndexOf("ID"); $srVer = $srH.IndexOf("Ver")
        $srIn = $false
        for ($sj = $srHdr + 1; $sj -lt $searchResult.Count; $sj++) {
            $sl = $searchResult[$sj]
            if ($sl -match '^-{10,}') { $srIn = $true; continue }
            if (!$srIn -or [string]::IsNullOrWhiteSpace($sl)) { continue }

            $srName = $sl.Substring(0, [Math]::Min($srId, $sl.Length)).TrimEnd()
            $srIdV  = ""
            if ($sl.Length -gt $srId) {
                $srIdV = $sl.Substring($srId, [Math]::Min($srVer - $srId, $sl.Length - $srId)).Trim()
            }
            $srIdTok = ($srIdV -split '\s+')[0].Trim()

            if ($srName -eq $name -and $srIdTok -and $srIdTok -ne "ID") {
                if ($srIdTok.Length -gt $allPrograms[$name].ID.Length) {
                    $allPrograms[$name].ID = $srIdTok
                    $resolvedName++
                }
                break
            }
        }
    }
}

Write-Host "  Resolvidos AppxPackage: $resolvedAppx" -ForegroundColor Gray
Write-Host "  Resolvidos --name     : $resolvedName" -ForegroundColor Gray

# --- 2d. De-duplicar ---
# Mesmo programa pode aparecer com IDs de fontes diferentes:
#   winget: Notepad++.Notepad++
#   msix:   MSIX\NotepadPlusPlus_1.0.0.0_neutral__2247w0b46hfww
# Normaliza o nome do programa para agrupar variantes e mantem
# o ID mais completo (mais longo) de cada grupo.
Function Get-NormalizedName {
    param([string]$DisplayName)
    # Remove parenteses com arquitetura: "Foo (64-bit x64)" -> "Foo"
    $n = $DisplayName -replace '\s*\(.*?\)\s*', ''
    # Remove caracteres especiais para comparacao
    $n = $n -replace '[^\w]', ''
    return $n.ToLower()
}

$bestMap = @{}  # NormName -> @{ ID, DisplayName }
foreach ($entry in $allPrograms.GetEnumerator()) {
    $id       = $entry.Value.ID
    $dispName = $entry.Key
    $normName = Get-NormalizedName $dispName

    if (!$bestMap.ContainsKey($normName) -or $id.Length -gt $bestMap[$normName].ID.Length) {
        $bestMap[$normName] = @{ ID = $id; DisplayName = $dispName }
    }
}

$idToName = @{}
foreach ($entry in $bestMap.GetEnumerator()) {
    $idToName[$entry.Value.ID] = $entry.Value.DisplayName
}
$uniqueIDs = @($idToName.Keys | Sort-Object)
Write-Host "  IDs unicos: $($uniqueIDs.Count)" -ForegroundColor Green

# ============================================================================
#  3. COLETAR ATUALIZACOES/HOTFIXES DO WINDOWS
# ============================================================================
Write-Host "Coletando atualizacoes..." -ForegroundColor Cyan
$updTable = @{}

# Metodo 1: Get-HotFix
try {
    Get-HotFix -ErrorAction Stop | ForEach-Object {
        if (!$updTable.ContainsKey($hf.HotFixID)) {
            $updTable[$hf.HotFixID] = $hf.HotFixID
        }
    }
}
catch { }

# Metodo 2: WMI Win32_QuickFixEngineering
try {
    Get-WmiObject -Class Win32_QuickFixEngineering -ErrorAction Stop | ForEach-Object {
        if (!$updTable.ContainsKey($_.HotFixID)) {
            $updTable[$_.HotFixID] = $_.HotFixID
        }
    }
}
catch { }

# Metodo 3: Microsoft.Update.Session COM API
try {
    $session = New-Object -ComObject "Microsoft.Update.Session" -ErrorAction Stop
    try {
        $searcher = $session.CreateUpdateSearcher()
        $queryCount = [Math]::Min($searcher.GetTotalHistoryCount(), 5000)
        if ($queryCount -gt 0) {
            $history = $searcher.QueryHistory(0, $queryCount)
            foreach ($entry in $history) {
                if ($entry.ResultCode -eq 2 -and !$updTable.ContainsKey($entry.Title)) {
                    $updTable[$entry.Title] = $entry.Title
                }
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($entry) | Out-Null
            }
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($history) | Out-Null
        }
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($searcher) | Out-Null
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($session) | Out-Null
    }
}
catch { }

# Ordenar: KB por numero (asc), depois nao-KB alfabetico
$kbUpdates = @($updTable.Keys | Where-Object { $_ -match '^KB(\d+)$' } |
    Sort-Object -Property { [long]([regex]::Match($_, '^KB(\d+)$').Groups[1].Value) })
$nonKbUpdates = @($updTable.Keys | Where-Object { $_ -notmatch '^KB(\d+)$' } | Sort-Object)
$updates = @($kbUpdates + $nonKbUpdates)

# ============================================================================
#  4. GERAR ARQUIVO TXT
# ============================================================================
$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine("==============================================================")
[void]$sb.AppendLine("  RELATORIO DE PROGRAMAS INSTALADOS E ATUALIZACOES")
[void]$sb.AppendLine("  Gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')")
[void]$sb.AppendLine("  Computador: $env:COMPUTERNAME")
[void]$sb.AppendLine("  Usuario: $env:USERNAME")
[void]$sb.AppendLine("  Sistema: $([System.Environment]::OSVersion.VersionString)")
[void]$sb.AppendLine("==============================================================")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("--------------------------------------------------------------")
[void]$sb.AppendLine("  SECAO 1: IDs DE PROGRAMAS INSTALADOS (resolucao completa)")
[void]$sb.AppendLine("  Total: $($uniqueIDs.Count) IDs unicos")
[void]$sb.AppendLine("--------------------------------------------------------------")

$i = 1
foreach ($id in $uniqueIDs) {
    [void]$sb.AppendLine("[$i] $id")
    $i++
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("--------------------------------------------------------------")
[void]$sb.AppendLine("  SECAO 2: ATUALIZACOES / HOTFIXES DO WINDOWS")
[void]$sb.AppendLine("  Total: $($updates.Count) atualizacoes encontradas")
[void]$sb.AppendLine("--------------------------------------------------------------")

$i = 1
foreach ($u in $updates) {
    [void]$sb.AppendLine("[$i] $u")
    $i++
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outFile, $sb.ToString(), $utf8NoBom)

# ============================================================================
#  5. RESUMO
# ============================================================================
Write-Host ""
Write-Host "  RELATORIO GERADO: $outFile" -ForegroundColor Green
Write-Host "  IDs Programas : $($uniqueIDs.Count)" -ForegroundColor White
Write-Host "  Atualizacoes   : $($updates.Count)" -ForegroundColor White
Write-Host ""
