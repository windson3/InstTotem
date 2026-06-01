#Requires -Version 5.0
<#
.SYNOPSIS
    Script completo: Lista programas, limpa, desinstala bloatware e faz hardening.
.DESCRIPTION
    SECAO 1: Lista IDs completos de programas instalados e atualizacoes (ListarProgramasEAtualizacoes)
    SECAO 2: Instala lista branca, desinstala restante (LimparEInstalar)
    SECAO 3: Debloat / Hardening (Cortana, Edge PDF, Dark Theme, OneDrive, Telemetry, Bloatware, .NET 3.5)
    SECAO 4: Remove pasta C:\inst\maquina\*.* e depois a pasta maquina
.NOTES
    Execute como Administrador:
      powershell -ExecutionPolicy Bypass -File "F:\Testes APP\Scripts\List-Apaga.ps1"
#>

$ErrorActionPreference = 'Continue'
$startTime = Get-Date

Write-Host ""
Write-Host "=============================================================" -ForegroundColor White
Write-Host "  LIST-APAGA.PS1 - Script Completo de Limpeza e Instalacao" -ForegroundColor Yellow
Write-Host "  Iniciado em: $($startTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Gray
Write-Host "=============================================================" -ForegroundColor White
Write-Host ""


# ============================================================================
#  SECAO 1: LISTAR PROGRAMAS INSTALADOS E ATUALIZACOES
#  (ListarProgramasEAtualizacoes.ps1)
# ============================================================================

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "  SECAO 1: LISTAR PROGRAMAS INSTALADOS E ATUALIZACOES" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- 1a. Diretorio de destino ---
$destDir = "C:\inst\maquina"
if (!(Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}
$outFile = Join-Path $destDir "ListaProgramasEAtualizacao.txt"

# --- 1b. Parse do winget list ---
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

        if ($idTok -match '^[0-9.]+$' -and $idTok -notmatch '[a-zA-Z\\]') { continue }
        if (!$name -or !$idTok -or $idTok -eq "ID") { continue }

        if (!$result.ContainsKey($name)) {
            $result[$name] = @{ ID = $idTok; Src = $src }
        }
    }
    return $result
}

Write-Host "Coletando programas instalados..." -ForegroundColor Cyan

$allPrograms = Parse-WingetList -Output (& winget list --accept-source-agreements 2>&1)
Write-Host "  winget list: $($allPrograms.Count) programas" -ForegroundColor Gray

# --- 1c. Carregar AppxPackage para cruzamento ---
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

# --- 1d. Resolver IDs truncados ---
$resolvedAppx = 0
$resolvedName = 0
$msixEntries = @($allPrograms.GetEnumerator() | Where-Object { !$_.Value.Src })

foreach ($entry in $msixEntries) {
    $name  = $entry.Key
    $idTok = $entry.Value.ID
    $idClean = $idTok -replace '^MSIX\\', ''
    $pkgBase = ($idClean -split '_')[0]

    if ($appxMap.ContainsKey($pkgBase)) {
        $allPrograms[$name].ID = $appxMap[$pkgBase]
        $resolvedAppx++
        continue
    }

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

# --- 1e. De-duplicar ---
Function Get-NormalizedName {
    param([string]$DisplayName)
    $n = $DisplayName -replace '\s*\(.*?\)\s*', ''
    $n = $n -replace '[^\w]', ''
    return $n.ToLower()
}

$bestMap = @{}
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

# --- 1f. Coletar atualizacoes/hotfixes ---
Write-Host "Coletando atualizacoes..." -ForegroundColor Cyan
$updTable = @{}

try {
    Get-HotFix -ErrorAction Stop | ForEach-Object {
        if (!$updTable.ContainsKey($_.HotFixID)) { $updTable[$_.HotFixID] = $_.HotFixID }
    }
}
catch { }

try {
    Get-WmiObject -Class Win32_QuickFixEngineering -ErrorAction Stop | ForEach-Object {
        if (!$updTable.ContainsKey($_.HotFixID)) { $updTable[$_.HotFixID] = $_.HotFixID }
    }
}
catch { }

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

$kbUpdates = @($updTable.Keys | Where-Object { $_ -match '^KB(\d+)$' } |
    Sort-Object -Property { [long]([regex]::Match($_, '^KB(\d+)$').Groups[1].Value) })
$nonKbUpdates = @($updTable.Keys | Where-Object { $_ -notmatch '^KB(\d+)$' } | Sort-Object)
$updates = @($kbUpdates + $nonKbUpdates)

# --- 1g. Gerar arquivo TXT ---
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

Write-Host ""
Write-Host "  RELATORIO GERADO: $outFile" -ForegroundColor Green
Write-Host "  IDs Programas : $($uniqueIDs.Count)" -ForegroundColor White
Write-Host "  Atualizacoes   : $($updates.Count)" -ForegroundColor White
Write-Host ""
Write-Host "  SECAO 1 CONCLUIDA." -ForegroundColor Green
Write-Host ""


# ============================================================================
#  SECAO 2: INSTALAR / DESINSTALAR PROGRAMAS
#  (LimparEInstalar.ps1)
# ============================================================================

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "  SECAO 2: INSTALAR / DESINSTALAR PROGRAMAS" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  SECAO 2A: INSTALAR PROGRAMAS (lista branca)" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

Write-Host "[1/5] Instalando: Microsoft.PowerShell" -ForegroundColor White
winget install --accept-package-agreements --accept-source-agreements Microsoft.PowerShell
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao instalar: Microsoft.PowerShell" -ForegroundColor DarkYellow }

Write-Host "[2/5] Instalando: Notepad++.Notepad++" -ForegroundColor White
winget install --accept-package-agreements --accept-source-agreements Notepad++.Notepad++
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao instalar: Notepad++.Notepad++" -ForegroundColor DarkYellow }

Write-Host "[3/5] Instalando: Google.Chrome" -ForegroundColor White
winget install --accept-package-agreements --accept-source-agreements Google.Chrome
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao instalar: Google.Chrome" -ForegroundColor DarkYellow }

Write-Host "[4/5] Instalando: AnyDesk.AnyDesk" -ForegroundColor White
winget install --accept-package-agreements --accept-source-agreements AnyDesk.AnyDesk
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao instalar: AnyDesk.AnyDesk" -ForegroundColor DarkYellow }

Write-Host "[5/5] Instalando: RARLab.WinRAR" -ForegroundColor White
winget install --accept-package-agreements --accept-source-agreements RARLab.WinRAR
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao instalar: RARLab.WinRAR" -ForegroundColor DarkYellow }

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  SECAO 2B: DESINSTALAR PROGRAMAS (restante)" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Cyan

Write-Host "[1/7] Desinstalando: RipGrep MSVC" -ForegroundColor White
winget uninstall --disable-interactivity BurntSushi.ripgrep.MSVC
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao desinstalar: RipGrep MSVC" -ForegroundColor DarkYellow }

Write-Host "[2/7] Desinstalando: FFmpeg" -ForegroundColor White
winget uninstall --disable-interactivity Gyan.FFmpeg
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao desinstalar: FFmpeg" -ForegroundColor DarkYellow }

Write-Host "[3/7] Desinstalando: Microsoft .NET Core Host - 3.1.32 (x64)" -ForegroundColor White
winget uninstall --disable-interactivity Microsoft.DotNet.HostingBundle.3.1
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao desinstalar: Microsoft .NET Core Host - 3.1.32 (x64)" -ForegroundColor DarkYellow }

Write-Host "[4/7] Desinstalando: Microsoft .NET Core Host FX Resolver - 3.1.32 (x64)" -ForegroundColor White
winget uninstall --disable-interactivity Microsoft.DotNet.Runtime.3.1
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao desinstalar: Microsoft .NET Core Host FX Resolver - 3.1.32 (x64)" -ForegroundColor DarkYellow }

Write-Host "[5/7] Desinstalando: Microsoft Edge" -ForegroundColor White
winget uninstall --disable-interactivity Microsoft.Edge
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao desinstalar: Microsoft Edge" -ForegroundColor DarkYellow }

Write-Host "[6/7] Desinstalando: Microsoft Edge WebView2 Runtime" -ForegroundColor White
winget uninstall --disable-interactivity Microsoft.EdgeWebView2Runtime
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao desinstalar: Microsoft Edge WebView2 Runtime" -ForegroundColor DarkYellow }

Write-Host "[7/7] Desinstalando: Microsoft Visual C++ 2015-2022 Redistributable (x64) - 14.51.36231" -ForegroundColor White
winget uninstall --disable-interactivity Microsoft.VCRedist.2015+.x64
if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao desinstalar: Microsoft Visual C++ 2015-2022 Redistributable (x64) - 14.51.36231" -ForegroundColor DarkYellow }

Write-Host ""
Write-Host "  SECAO 2 CONCLUIDA." -ForegroundColor Green
Write-Host ""


# ============================================================================
#  SECAO 3: DEBLOAT / HARDENING (Windows10Debloater)
# ============================================================================

Write-Host "=============================================================" -ForegroundColor Magenta
Write-Host "  SECAO 3: DEBLOAT E HARDENING DO WINDOWS" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Magenta

# --- 3a. Disable Cortana ---
Write-Host ""
Write-Host "[3a] Desabilitando Cortana..." -ForegroundColor Cyan

Write-Host "  -> Desabilitando Cortana via registro (HKCU)..."
$Cortana1 = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
$Cortana2 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
$Cortana3 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
If (!(Test-Path $Cortana1)) { New-Item $Cortana1 -Force | Out-Null }
Set-ItemProperty $Cortana1 AcceptedPrivacyPolicy -Value 0 -ErrorAction SilentlyContinue
If (!(Test-Path $Cortana2)) { New-Item $Cortana2 -Force | Out-Null }
Set-ItemProperty $Cortana2 RestrictImplicitTextCollection -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty $Cortana2 RestrictImplicitInkCollection -Value 1 -ErrorAction SilentlyContinue
If (!(Test-Path $Cortana3)) { New-Item $Cortana3 -Force | Out-Null }
Set-ItemProperty $Cortana3 HarvestContacts -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando Cortana no Windows Search (HKLM)..."
$Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
If (!(Test-Path $Search)) { New-Item $Search -Force | Out-Null }
Set-ItemProperty $Search AllowCortana -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $Search DisableWebSearch -Value 1 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando Bing Search no menu iniciar..."
Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled -Value 0 -ErrorAction SilentlyContinue

Write-Host "  [OK] Cortana desabilitada." -ForegroundColor Green


# --- 3b. Disable Edge as default PDF viewer ---
Write-Host ""
Write-Host "[3b] Impedindo Edge como visualizador PDF padrao..." -ForegroundColor Cyan

Write-Host "  -> Removendo associacao Edge PDF..."
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
$NoPDF = "HKCR:\.pdf"
$NoProgids = "HKCR:\.pdf\OpenWithProgids"
$NoWithList = "HKCR:\.pdf\OpenWithList"

If (!(Get-ItemProperty $NoPDF NoOpenWith -ErrorAction SilentlyContinue)) {
    New-ItemProperty $NoPDF NoOpenWith -ErrorAction SilentlyContinue | Out-Null
}
If (!(Get-ItemProperty $NoPDF NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
    New-ItemProperty $NoPDF NoStaticDefaultVerb -ErrorAction SilentlyContinue | Out-Null
}
If (!(Get-ItemProperty $NoProgids NoOpenWith -ErrorAction SilentlyContinue)) {
    New-ItemProperty $NoProgids NoOpenWith -ErrorAction SilentlyContinue | Out-Null
}
If (!(Get-ItemProperty $NoProgids NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
    New-ItemProperty $NoProgids NoStaticDefaultVerb -ErrorAction SilentlyContinue | Out-Null
}
If (!(Get-ItemProperty $NoWithList NoOpenWith -ErrorAction SilentlyContinue)) {
    New-ItemProperty $NoWithList NoOpenWith -ErrorAction SilentlyContinue | Out-Null
}
If (!(Get-ItemProperty $NoWithList NoStaticDefaultVerb -ErrorAction SilentlyContinue)) {
    New-ItemProperty $NoWithList NoStaticDefaultVerb -ErrorAction SilentlyContinue | Out-Null
}

$Edge = "HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
If (Test-Path $Edge) {
    Set-Item $Edge "AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_" -ErrorAction SilentlyContinue
}

Write-Host "  [OK] Edge PDF desabilitado." -ForegroundColor Green


# --- 3c. Enable Dark Theme ---
Write-Host ""
Write-Host "[3c] Habilitando Dark Theme (Tema Escuro)..." -ForegroundColor Cyan

Write-Host "  -> Aplicando tema escuro..."
$ThemePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
If (!(Test-Path $ThemePath)) { New-Item $ThemePath -Force | Out-Null }
Set-ItemProperty $ThemePath AppsUseLightTheme -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $ThemePath SystemUsesLightTheme -Value 0 -ErrorAction SilentlyContinue

Write-Host "  [OK] Dark Theme habilitado." -ForegroundColor Green


# --- 3d. Uninstall OneDrive ---
Write-Host ""
Write-Host "[3d] Desinstalando OneDrive..." -ForegroundColor Cyan

Write-Host "  -> Parando processos do OneDrive..."
Stop-Process -Name "OneDrive*" -Force -ErrorAction SilentlyContinue
Start-Sleep 2

$onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
If (!(Test-Path $onedrive)) {
    $onedrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
}

If (Test-Path $onedrive) {
    Write-Host "  -> Executando desinstalacao do OneDrive..."
    Start-Process $onedrive "/uninstall" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep 2
}
else {
    Write-Host "  -> OneDriveSetup.exe nao encontrado, tentando metodo alternativo..." -ForegroundColor Yellow
    winget uninstall "Microsoft.OneDrive" --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
}

Write-Host "  -> Removendo arquivos residuais do OneDrive..."
Remove-Item "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
If (Test-Path "$env:SYSTEMDRIVE\OneDriveTemp") {
    Remove-Item "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue
}

Write-Host "  -> Removendo OneDrive do Explorer..."
$ExplorerReg1 = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
$ExplorerReg2 = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
If (!(Test-Path $ExplorerReg1)) { New-Item $ExplorerReg1 -Force | Out-Null }
Set-ItemProperty $ExplorerReg1 System.IsPinnedToNameSpaceTree -Value 0 -ErrorAction SilentlyContinue
If (!(Test-Path $ExplorerReg2)) { New-Item $ExplorerReg2 -Force | Out-Null }
Set-ItemProperty $ExplorerReg2 System.IsPinnedToNameSpaceTree -Value 0 -ErrorAction SilentlyContinue

$StartupRun = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty $StartupRun "OneDrive" -ErrorAction SilentlyContinue

Write-Host "  [OK] OneDrive desinstalado." -ForegroundColor Green


# --- 3e. Disable Telemetry ---
Write-Host ""
Write-Host "[3e] Desabilitando Telemetria do Windows..." -ForegroundColor Cyan

Write-Host "  -> Desabilitando Advertising ID..."
$Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
If (Test-Path $Advertising) {
    Set-ItemProperty $Advertising Enabled -Value 0 -ErrorAction SilentlyContinue
}

Write-Host "  -> Desabilitando coleta de dados (AllowTelemetry)..."
$DataCollection1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
$DataCollection2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
$DataCollection3 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
If (Test-Path $DataCollection1) { Set-ItemProperty $DataCollection1 AllowTelemetry -Value 0 -ErrorAction SilentlyContinue }
If (Test-Path $DataCollection2) { Set-ItemProperty $DataCollection2 AllowTelemetry -Value 0 -ErrorAction SilentlyContinue }
If (Test-Path $DataCollection3) { Set-ItemProperty $DataCollection3 AllowTelemetry -Value 0 -ErrorAction SilentlyContinue }
If (!(Test-Path $DataCollection1)) { New-Item $DataCollection1 -Force | Out-Null }
Set-ItemProperty $DataCollection1 AllowTelemetry -Value 0 -ErrorAction SilentlyContinue
If (!(Test-Path $DataCollection2)) { New-Item $DataCollection2 -Force | Out-Null }
Set-ItemProperty $DataCollection2 AllowTelemetry -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando Feedback Experience..."
$Period = "HKCU:\Software\Microsoft\Siuf\Rules"
If (!(Test-Path $Period)) { New-Item $Period -Force | Out-Null }
Set-ItemProperty $Period PeriodInNanoSeconds -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando servicos de telemetria..."
Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
Set-Service "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando tasks agendadas de telemetria..."
Get-ScheduledTask "XblGameSaveTaskLogon" -ErrorAction SilentlyContinue | Disable-ScheduledTask
Get-ScheduledTask "XblGameSaveTask" -ErrorAction SilentlyContinue | Disable-ScheduledTask
Get-ScheduledTask "Consolidator" -ErrorAction SilentlyContinue | Disable-ScheduledTask
Get-ScheduledTask "UsbCeip" -ErrorAction SilentlyContinue | Disable-ScheduledTask
Get-ScheduledTask "DmClient" -ErrorAction SilentlyContinue | Disable-ScheduledTask
Get-ScheduledTask "DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Disable-ScheduledTask

Write-Host "  -> Desabilitando rastreamento de localizacao..."
$SensorState = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
$LocationConfig = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
If (!(Test-Path $SensorState)) { New-Item $SensorState -Force | Out-Null }
Set-ItemProperty $SensorState SensorPermissionState -Value 0 -ErrorAction SilentlyContinue
If (!(Test-Path $LocationConfig)) { New-Item $LocationConfig -Force | Out-Null }
Set-ItemProperty $LocationConfig Status -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando Wi-Fi Sense..."
$WifiSense1 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
$WifiSense2 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
$WifiSense3 = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
If (!(Test-Path $WifiSense1)) { New-Item $WifiSense1 -Force | Out-Null }
Set-ItemProperty $WifiSense1 Value -Value 0 -ErrorAction SilentlyContinue
If (!(Test-Path $WifiSense2)) { New-Item $WifiSense2 -Force | Out-Null }
Set-ItemProperty $WifiSense2 Value -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $WifiSense3 AutoConnectAllowedOEM -Value 0 -ErrorAction SilentlyContinue

Write-Host "  [OK] Telemetria desabilitada." -ForegroundColor Green


# --- 3f. Remove Bloatware Registry Keys ---
Write-Host ""
Write-Host "[3f] Removendo chaves de registro de Bloatware..." -ForegroundColor Cyan

Write-Host "  -> Removendo chaves HKCR de bloatware..."
$BloatwareKeys = @(
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
)

$removedCount = 0
foreach ($key in $BloatwareKeys) {
    If (Test-Path $key) {
        try {
            Remove-Item $key -Recurse -Force -ErrorAction Stop
            $removedCount++
        }
        catch { }
    }
}
Write-Host "  -> $removedCount chaves HKCR removidas."

Write-Host "  -> Desabilitando Windows Consumer Features..."
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$registryOEM  = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
If (!(Test-Path $registryPath)) { New-Item $registryPath -Force | Out-Null }
Set-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 -ErrorAction SilentlyContinue
If (!(Test-Path $registryOEM)) { New-Item $registryOEM -Force | Out-Null }
Set-ItemProperty $registryOEM ContentDeliveryAllowed -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $registryOEM OemPreInstalledAppsEnabled -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $registryOEM PreInstalledAppsEnabled -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $registryOEM PreInstalledAppsEverEnabled -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $registryOEM SilentInstalledAppsEnabled -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $registryOEM SystemPaneSuggestionsEnabled -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando sugestoes no menu iniciar e live tiles..."
If (!(Test-Path $registryOEM)) { New-Item $registryOEM -Force | Out-Null }
Set-ItemProperty $registryOEM SubscribedContent-338389Enabled -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $registryOEM SubscribedContent-310093Enabled -Value 0 -ErrorAction SilentlyContinue

$Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
If (!(Test-Path $Live)) { New-Item $Live -Force | Out-Null }
Set-ItemProperty $Live NoTileApplicationNotification -Value 1 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando People no taskbar..."
$People = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"
If (!(Test-Path $People)) { New-Item $People -Force | Out-Null }
Set-ItemProperty $People PeopleBand -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Configurando Mixed Reality Portal..."
$Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"
If (Test-Path $Holo) {
    Set-ItemProperty $Holo FirstRunSucceeded -Value 0 -ErrorAction SilentlyContinue
}

Write-Host "  [OK] Bloatware RegKeys removidas." -ForegroundColor Green


# --- 3g. Install .NET Framework 3.5 ---
Write-Host ""
Write-Host "[3g] Instalando .NET Framework 3.5..." -ForegroundColor Cyan

Write-Host "  -> Instalando via DISM (Windows Feature)..."
try {
    $dismResult = DISM.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart 2>&1
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) {
        Write-Host "  [OK] .NET Framework 3.5 instalado com sucesso." -ForegroundColor Green
    }
    elseif ($LASTEXITCODE -eq -2146498530 -or $LASTEXITCODE -eq 1242) {
        Write-Host "  [AVISO] .NET 3.5 ja esta instalado ou nao disponivel nesta edicao." -ForegroundColor Yellow
    }
    else {
        Write-Host "  [AVISO] DISM retornou exit code $LASTEXITCODE. Tentando alternate source..." -ForegroundColor Yellow
        DISM.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /LimitAccess 2>&1 | Out-Null
    }
}
catch {
    Write-Host "  [AVISO] Erro ao instalar .NET 3.5: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  SECAO 3 CONCLUIDA." -ForegroundColor Green
Write-Host ""


# ============================================================================
#  SECAO 4: REMOVER PASTA C:\INST\MAQUINA
# ============================================================================

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "  SECAO 4: REMOVER PASTA C:\INST\MAQUINA" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

$maquinaDir = "C:\inst\maquina"

if (Test-Path $maquinaDir) {
    Write-Host "  -> Removendo arquivos de $maquinaDir ..." -ForegroundColor White

    # Remove todos os arquivos dentro da pasta
    $files = Get-ChildItem -Path $maquinaDir -Force -ErrorAction SilentlyContinue
    $fileCount = ($files | Measure-Object).Count

    if ($fileCount -gt 0) {
        Remove-Item -Path "$maquinaDir\*" -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "  -> $fileCount arquivo(s) removido(s)." -ForegroundColor Gray
    }
    else {
        Write-Host "  -> Nenhum arquivo encontrado na pasta." -ForegroundColor Gray
    }

    # Remove a pasta maquina
    Write-Host "  -> Removendo pasta $maquinaDir ..." -ForegroundColor White
    try {
        Remove-Item -Path $maquinaDir -Force -Recurse -ErrorAction Stop
        Write-Host "  [OK] Pasta $maquinaDir removida com sucesso." -ForegroundColor Green
    }
    catch {
        Write-Host "  [AVISO] Nao foi possivel remover a pasta: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  -> Pasta $maquinaDir nao encontrada. Nada a remover." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  SECAO 4 CONCLUIDA." -ForegroundColor Green
Write-Host ""


# ============================================================================
#  FINALIZACAO
# ============================================================================

$endTime = Get-Date
$elapsed = $endTime - $startTime

Write-Host "=============================================================" -ForegroundColor White
Write-Host "  LIST-APAGA.PS1 - EXECUCAO COMPLETA" -ForegroundColor Green
Write-Host "  Inicio : $($startTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Fim    : $($endTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Tempo  : $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
Write-Host "=============================================================" -ForegroundColor White
Write-Host ""
