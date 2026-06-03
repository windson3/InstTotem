#Requires -Version 5.0
<#
.SYNOPSIS
    Script unificado de manutencao para o Totem.
.DESCRIPTION
    1) Lista programas instalados e atualizacoes em um arquivo TXT em %TEMP%\InstTotemMaintenance.
    2) Executa limpeza, instalacao de lista branca, desinstalacao de bloatware e hardening do Windows.
    3) Executa instalacoes adicionais de arcade via winget.
.NOTES
    Execute como Administrador:
      powershell -ExecutionPolicy Bypass -File "Run-Maintenance.ps1"
    O arquivo de relatorio sera salvo em uma pasta generica de temporario do Windows.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = 'Continue'

$ReportRoot = Join-Path $env:TEMP 'InstTotemMaintenance'
$ReportFile = Join-Path $ReportRoot 'ListaProgramasEAtualizacao.txt'
$MachineFolder = 'C:\inst\maquina'

function Assert-RunningAsAdministrator {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Error 'Este script precisa ser executado como Administrador.'
        exit 1
    }
}

function Ensure-DirectoryExists {
    param([string]$Path)
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function Write-Section {
    param([string]$Text)
    Write-Host ''
    Write-Host '=============================================================' -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Yellow
    Write-Host '=============================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Invoke-Winget {
    param(
        [Parameter(Mandatory=$true)][string[]]$Arguments
    )

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = 'winget'
    $processInfo.Arguments = $Arguments -join ' '
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    return [PSCustomObject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout
        StdErr = $stderr
    }
}

function Parse-WingetList {
    param([string[]]$Output)

    $hIdx = -1
    for ($i = 0; $i -lt $Output.Count; $i++) {
        if ($Output[$i].TrimStart() -match '^Nome') { $hIdx = $i; break }
    }
    if ($hIdx -lt 0) { return @{} }

    $hLine = $Output[$hIdx]
    $idPos  = $hLine.IndexOf('ID')
    $verPos = $hLine.IndexOf('Ver')
    $origPos = $hLine.IndexOf('Origem')
    $fieldW = $verPos - $idPos
    if ($fieldW -le 0) { $fieldW = 48 }

    $result = @{}
    $inData = $false

    for ($j = $hIdx + 1; $j -lt $Output.Count; $j++) {
        $line = $Output[$j]
        if ($line -match '^-{10,}') { $inData = $true; continue }
        if (-not $inData) { continue }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $name = $line.Substring(0, [Math]::Min($idPos, $line.Length)).TrimEnd()
        $idRaw = ''
        if ($line.Length -gt $idPos) {
            $idRaw = $line.Substring($idPos, [Math]::Min($fieldW, $line.Length - $idPos)).Trim()
        }
        $idTok = ($idRaw -split '\s+')[0].Trim()
        $src = ''
        if ($origPos -gt 0 -and $line.Length -gt $origPos) {
            $src = $line.Substring($origPos).Trim()
        }

        if ($idTok -match '^[0-9.]+$' -and $idTok -notmatch '[a-zA-Z\\]') { continue }
        if (-not $name -or -not $idTok -or $idTok -eq 'ID') { continue }

        if (-not $result.ContainsKey($name)) {
            $result[$name] = @{ ID = $idTok; Src = $src }
        }
    }

    return $result
}

function Get-NormalizedName {
    param([string]$DisplayName)
    $n = $DisplayName -replace '\s*\(.*?\)\s*', ''
    $n = $n -replace '[^\w]', ''
    return $n.ToLower()
}

function Get-ProgramInventory {
    Write-Host 'Coletando programas instalados...' -ForegroundColor Cyan

    $wingetResult = Invoke-Winget -Arguments @('list', '--accept-source-agreements')
    $allPrograms = Parse-WingetList -Output ($wingetResult.StdOut -split "`n")
    Write-Host "  winget list: $($allPrograms.Count) programas" -ForegroundColor Gray

    $appxMap = @{}
    try {
        Get-AppxPackage | ForEach-Object {
            $pkgName = ($_.PackageFullName -split '_')[0]
            if (-not $appxMap.ContainsKey($pkgName) -or $_.PackageFullName.Length -gt $appxMap[$pkgName].Length) {
                $appxMap[$pkgName] = $_.PackageFullName
            }
        }
    } catch { }
    Write-Host "  AppxPackage : $($appxMap.Count) pacotes carregados" -ForegroundColor Gray

    $resolvedAppx = 0
    $resolvedName = 0
    $msixEntries = @($allPrograms.GetEnumerator() | Where-Object { -not $_.Value.Src })

    foreach ($entry in $msixEntries) {
        $name = $entry.Key
        $idTok = $entry.Value.ID
        $idClean = $idTok -replace '^MSIX\\', ''
        $pkgBase = ($idClean -split '_')[0]

        if ($appxMap.ContainsKey($pkgBase)) {
            $allPrograms[$name].ID = $appxMap[$pkgBase]
            $resolvedAppx++
            continue
        }

        $searchResult = Invoke-Winget -Arguments @('list', '--name', $name, '--accept-source-agreements')
        $searchLines = $searchResult.StdOut -split "`n"
        $srHdr = -1
        for ($si = 0; $si -lt $searchLines.Count; $si++) {
            if ($searchLines[$si].TrimStart() -match '^Nome') { $srHdr = $si; break }
        }
        if ($srHdr -ge 0) {
            $srH = $searchLines[$srHdr]
            $srId = $srH.IndexOf('ID'); $srVer = $srH.IndexOf('Ver')
            $srIn = $false
            for ($sj = $srHdr + 1; $sj -lt $searchLines.Count; $sj++) {
                $sl = $searchLines[$sj]
                if ($sl -match '^-{10,}') { $srIn = $true; continue }
                if (-not $srIn -or [string]::IsNullOrWhiteSpace($sl)) { continue }

                $srName = $sl.Substring(0, [Math]::Min($srId, $sl.Length)).TrimEnd()
                $srIdV = ''
                if ($sl.Length -gt $srId) {
                    $srIdV = $sl.Substring($srId, [Math]::Min($srVer - $srId, $sl.Length - $srId)).Trim()
                }
                $srIdTok = ($srIdV -split '\s+')[0].Trim()

                if ($srName -eq $name -and $srIdTok -and $srIdTok -ne 'ID') {
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

    $bestMap = @{}
    foreach ($entry in $allPrograms.GetEnumerator()) {
        $id = $entry.Value.ID
        $dispName = $entry.Key
        $normName = Get-NormalizedName $dispName
        if (-not $bestMap.ContainsKey($normName) -or $id.Length -gt $bestMap[$normName].ID.Length) {
            $bestMap[$normName] = @{ ID = $id; DisplayName = $dispName }
        }
    }

    $idToName = @{}
    foreach ($entry in $bestMap.GetEnumerator()) {
        $idToName[$entry.Value.ID] = $entry.Value.DisplayName
    }

    return @($idToName.Keys | Sort-Object)
}

function Get-WindowsUpdates {
    Write-Host 'Coletando atualizacoes...' -ForegroundColor Cyan
    $updTable = @{}

    try {
        Get-HotFix -ErrorAction Stop | ForEach-Object {
            if (-not $updTable.ContainsKey($_.HotFixID)) { $updTable[$_.HotFixID] = $_.HotFixID }
        }
    } catch { }

    try {
        Get-WmiObject -Class Win32_QuickFixEngineering -ErrorAction Stop | ForEach-Object {
            if (-not $updTable.ContainsKey($_.HotFixID)) { $updTable[$_.HotFixID] = $_.HotFixID }
        }
    } catch { }

    try {
        $session = New-Object -ComObject 'Microsoft.Update.Session' -ErrorAction Stop
        try {
            $searcher = $session.CreateUpdateSearcher()
            $queryCount = [Math]::Min($searcher.GetTotalHistoryCount(), 5000)
            if ($queryCount -gt 0) {
                $history = $searcher.QueryHistory(0, $queryCount)
                foreach ($entry in $history) {
                    if ($entry.ResultCode -eq 2 -and -not $updTable.ContainsKey($entry.Title)) {
                        $updTable[$entry.Title] = $entry.Title
                    }
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($entry) | Out-Null
                }
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($history) | Out-Null
            }
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($searcher) | Out-Null
        } finally {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($session) | Out-Null
        }
    } catch { }

    $kbUpdates = @($updTable.Keys | Where-Object { $_ -match '^KB(\d+)$' } |
        Sort-Object -Property { [long]([regex]::Match($_, '^KB(\d+)$').Groups[1].Value) })
    $nonKbUpdates = @($updTable.Keys | Where-Object { $_ -notmatch '^KB(\d+)$' } | Sort-Object)
    return @($kbUpdates + $nonKbUpdates)
}

function Generate-Report {
    param(
        [string[]]$ProgramIds,
        [string[]]$Updates
    )

    Ensure-DirectoryExists -Path $ReportRoot

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('==============================================================')
    [void]$sb.AppendLine('  RELATORIO DE PROGRAMAS INSTALADOS E ATUALIZACOES')
    [void]$sb.AppendLine("  Gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')")
    [void]$sb.AppendLine("  Computador: $env:COMPUTERNAME")
    [void]$sb.AppendLine("  Usuario: $env:USERNAME")
    [void]$sb.AppendLine("  Sistema: $([System.Environment]::OSVersion.VersionString)")
    [void]$sb.AppendLine('==============================================================')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('--------------------------------------------------------------')
    [void]$sb.AppendLine('  SECAO 1: IDs DE PROGRAMAS INSTALADOS (resolucao completa)')
    [void]$sb.AppendLine("  Total: $($ProgramIds.Count) IDs unicos")
    [void]$sb.AppendLine('--------------------------------------------------------------')
    $i = 1
    foreach ($id in $ProgramIds) {
        [void]$sb.AppendLine("[$i] $id")
        $i++
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('--------------------------------------------------------------')
    [void]$sb.AppendLine('  SECAO 2: ATUALIZACOES / HOTFIXES DO WINDOWS')
    [void]$sb.AppendLine("  Total: $($Updates.Count) atualizacoes encontradas")
    [void]$sb.AppendLine('--------------------------------------------------------------')
    $i = 1
    foreach ($u in $Updates) {
        [void]$sb.AppendLine("[$i] $u")
        $i++
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ReportFile, $sb.ToString(), $utf8NoBom)

    Write-Host ''
    Write-Host "  RELATORIO GERADO: $ReportFile" -ForegroundColor Green
    Write-Host "  IDs Programas : $($ProgramIds.Count)" -ForegroundColor White
    Write-Host "  Atualizacoes   : $($Updates.Count)" -ForegroundColor White
    Write-Host ''
}

function Install-WhiteListApps {
    Write-Section 'SECAO 2A: INSTALAR PROGRAMAS (lista branca)'

    $packages = @(
        'Microsoft.PowerShell',
        'Notepad++.Notepad++',
        'Google.Chrome',
        'AnyDesk.AnyDesk',
        'RARLab.WinRAR'
    )

    $index = 1
    foreach ($pkg in $packages) {
        Write-Host "[$index/$($packages.Count)] Instalando: $pkg" -ForegroundColor White
        $result = Invoke-Winget -Arguments @('install', '--accept-package-agreements', '--accept-source-agreements', $pkg)
        if ($result.ExitCode -ne 0) {
            Write-Host "[AVISO] Falha ao instalar: $pkg" -ForegroundColor DarkYellow
        }
        $index++
    }
}

function Uninstall-Programs {
    Write-Section 'SECAO 2B: DESINSTALAR PROGRAMAS (restante)'

    $packages = @(
        'BurntSushi.ripgrep.MSVC',
        'Gyan.FFmpeg',
        'Microsoft.DotNet.HostingBundle.3.1',
        'Microsoft.DotNet.Runtime.3.1',
        'Microsoft.Edge',
        'ARP\Machine\X86\Microsoft Edge Update',
        'Microsoft.EdgeWebView2Runtime',
        'Microsoft.OneDrive',
        'MSIX\AppUp.IntelGraphicsExperience_1.100.5688.0_x64__8j3eq9eme6ctt',
        'MSIX\Clipchamp.Clipchamp_4.5.10220.0_x64__yxz26nhyzhsrt',
        'Microsoft.Teams',
        'MSIX\Microsoft.AV1VideoExtension_2.0.7.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.AVCEncoderVideoExtension_1.1.23.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.ApplicationCompatibilityEnhancements_1.2511.9.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.BingNews_4.55.62231.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.BingSearch_1.1.43.0_x64__8wekyb3d8bbwe',
        'Microsoft.AppInstaller',
        'MSIX\Microsoft.GamingApp_2602.1001.5.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.GetHelp_10.2409.33293.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.HEIFImageExtension_1.2.29.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.Ink.Handwriting.Main.pt-BR.1.0_0.1082.2350.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.Ink.Handwriting.pt-BR.1.0_0.1082.2350.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.Ink.Handwriting.pt-BR.1.0_0.1082.2350.0_x86__8wekyb3d8bbwe',
        'MSIX\Microsoft.MPEG2VideoExtension_1.2.13.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.MicrosoftEdge.Stable_145.0.3800.70_neutral__8wekyb3d8bbwe',
        'MSIX\Microsoft.MicrosoftOfficeHub_19.2602.54021.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.MicrosoftSolitaireCollection_4.25.1130.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.MicrosoftStickyNotes_6.1.4.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.MixedReality.Portal_2000.21051.1282.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x86__8wekyb3d8bbwe',
        'MSIX\Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x86__8wekyb3d8bbwe',
        'MSIX\Microsoft.Office.OneNote_16001.14326.22594.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.OutlookForWindows_1.2026.210.300_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.Paint_11.2512.221.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.People_10.2202.100.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.PowerAutomateDesktop_11.2602.145.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.RawImageExtension_2.5.7.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.ScreenSketch_11.2511.47.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.SecHealthUI_1000.29510.1001.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.SkypeApp_15.150.3125.0_x64__kzf8qxf38zg5c',
        'MSIX\Microsoft.StartExperiencesApp_1.229.1.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.StorePurchaseApp_22512.1401.1.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.Todos_2.168.6211.0_x64__8wekyb3d8bbwe',
        'Microsoft.UI.Xaml.2.7',
        'Microsoft.UI.Xaml.2.8',
        'Microsoft.VCLibs.Desktop.14',
        'MSIX\Microsoft.VCLibs.140.00_14.0.33519.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.VCLibs.140.00_14.0.33519.0_x86__8wekyb3d8bbwe',
        'MSIX\Microsoft.VP9VideoExtensions_1.2.12.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WebMediaExtensions_1.2.17.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WebpImageExtension_1.2.14.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WidgetsPlatformRuntime_1.6.14.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.Windows.DevHome_0.0.0.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.Windows.Photos_2025.11120.5001.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAlarms_11.2512.0.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAppRuntime.1.5_5001.373.1736.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAppRuntime.1.5_5001.373.1736.0_x86__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAppRuntime.1.6_6000.519.329.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAppRuntime.1.6_6000.519.329.0_x86__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAppRuntime.1.7_7000.770.750.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAppRuntime.1.7_7000.770.750.0_x86__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAppRuntime.1.8_8000.770.947.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsAppRuntime.1.8_8000.770.947.0_x86__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsCalculator_11.2508.4.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsFeedbackHub_1.2602.13304.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsMaps_11.2506.3.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsNotepad_11.2510.14.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.WindowsSoundRecorder_11.2512.0.0_x64__8wekyb3d8bbwe',
        'Microsoft.WindowsTerminal',
        'MSIX\Microsoft.Winget.Source_2026.226.1147.24_neutral__8wekyb3d8bbwe',
        'MSIX\Microsoft.Xbox.TCUI_1.24.10001.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.XboxGameOverlay_1.54.4001.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.XboxGamingOverlay_7.326.2102.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.XboxIdentityProvider_12.13016001.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.XboxSpeechToTextOverlay_1.21.13002.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.YourPhone_1.26011.42.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.ZuneMusic_11.2512.10.0_x64__8wekyb3d8bbwe',
        'MSIX\Microsoft.ZuneVideo_10.25121.10051.0_x64__8wekyb3d8bbwe',
        'MSIX\MicrosoftCorporationII.QuickAssist_2.0.29.0_x64__8wekyb3d8bbwe',
        'MSIX\MicrosoftWindows.Client.WebExperience_526.1202.40.0_x64__cw5n1h2txyewy',
        'MSIX\MicrosoftWindows.CrossDevice_1.26011.30.0_x64__cw5n1h2txyewy',
        'MSIX\microsoft.windowscommunicationsapps_16005.14326.22342.0_x64__8wekyb3d8bbwe',
        '9NBLGGH4VF97',
        'Email e Calendário',
        'Hub de Comentários',
        'Microsoft.549981C3F5F10_8wekyb3d8bbwe',
        'Microsoft.BingNews_8wekyb3d8bbwe',
        'Microsoft.BingWeather_8wekyb3d8bbwe',
        'Microsoft.GamingApp_8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_8wekyb3',
        'Microsoft.MicrosoftStickyNotes_8wekyb3',
        'Microsoft.OutlookForWindows_8wekyb3d8bbwe',
        'Microsoft.People_8wekyb3',
        'Microsoft.PowerAutomateDesktop_8wekyb3d8bbwe',
        'Microsoft.Todos_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_',
        'Microsoft.WindowsMaps_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_8wekyb3d8bbwe',
        'MicrosoftCorporationII.MicrosoftFamily_8wekyb3d8bbwe',
        'MicrosoftTeams_8wekyb3d8bbwe',
        'Notas Autoadesivas da Microsoft',
        'Solitaire & Casual Games',
        'microsoft.windowscommunicationsapps_8wekyb3d',
        'C6FD611E-7EFE-488C-A0E0-974C09EF6473',
        'Clipchamp.Clipchamp_yxz26nhyzhsrt',
        'Microsoft.GetHelp_8wekyb3d8bbwe',
        'Microsoft.WindowsNotepad_8wekyb3',
        'Microsoft.Xbox.TCUI_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_8wekyb3d8bbwe',
        'Microsoft.XboxGamingOverlay_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_8wekyb3d8bbwe',
        'Microsoft.YourPhone_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_8wekyb3d8bbwe',
        'MicrosoftCorporationII.QuickAssist_8wekyb3d8bbwe'
    )

    $uniquePackages = $packages | Sort-Object -Unique
    $index = 1
    foreach ($pkg in $uniquePackages) {
        Write-Host "[$index/$($uniquePackages.Count)] Desinstalando: $pkg" -ForegroundColor White
        $result = Invoke-Winget -Arguments @('uninstall', '--disable-interactivity', $pkg)
        if ($result.ExitCode -ne 0) {
            Write-Host "[AVISO] Falha ao desinstalar: $pkg" -ForegroundColor DarkYellow
        }
        $index++
    }
}

function Apply-DebloatAndHardening {
    Write-Section 'SECAO 3: DEBLOAT E HARDENING DO WINDOWS'

    Write-Host '[3a] Desabilitando Cortana...' -ForegroundColor Cyan
    $Cortana1 = 'HKCU:\SOFTWARE\Microsoft\Personalization\Settings'
    $Cortana2 = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization'
    $Cortana3 = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore'
    if (-not (Test-Path $Cortana1)) { New-Item $Cortana1 -Force | Out-Null }
    Set-ItemProperty $Cortana1 AcceptedPrivacyPolicy -Value 0 -ErrorAction SilentlyContinue
    if (-not (Test-Path $Cortana2)) { New-Item $Cortana2 -Force | Out-Null }
    Set-ItemProperty $Cortana2 RestrictImplicitTextCollection -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty $Cortana2 RestrictImplicitInkCollection -Value 1 -ErrorAction SilentlyContinue
    if (-not (Test-Path $Cortana3)) { New-Item $Cortana3 -Force | Out-Null }
    Set-ItemProperty $Cortana3 HarvestContacts -Value 0 -ErrorAction SilentlyContinue
    $SearchReg = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    if (-not (Test-Path $SearchReg)) { New-Item $SearchReg -Force | Out-Null }
    Set-ItemProperty $SearchReg AllowCortana -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty $SearchReg DisableWebSearch -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' BingSearchEnabled -Value 0 -ErrorAction SilentlyContinue
    Write-Host '  [OK] Cortana desabilitada.' -ForegroundColor Green

    Write-Host '[3b] Impedindo Edge como visualizador PDF padrao...' -ForegroundColor Cyan
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
    $NoPDF = 'HKCR:\.pdf'
    $NoProgids = 'HKCR:\.pdf\OpenWithProgids'
    $NoWithList = 'HKCR:\.pdf\OpenWithList'
    foreach ($entry in @(
        @{Key=$NoPDF; Name='NoOpenWith'}, @{Key=$NoPDF; Name='NoStaticDefaultVerb'},
        @{Key=$NoProgids; Name='NoOpenWith'}, @{Key=$NoProgids; Name='NoStaticDefaultVerb'},
        @{Key=$NoWithList; Name='NoOpenWith'}, @{Key=$NoWithList; Name='NoStaticDefaultVerb'}
    )) {
        if (-not (Get-ItemProperty $entry.Key $entry.Name -ErrorAction SilentlyContinue)) {
            New-ItemProperty $entry.Key $entry.Name -ErrorAction SilentlyContinue | Out-Null
        }
    }
    $EdgeKey = 'HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_'
    if (Test-Path $EdgeKey) { Set-Item $EdgeKey 'AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_' -ErrorAction SilentlyContinue }
    Write-Host '  [OK] Edge PDF desabilitado.' -ForegroundColor Green

    Write-Host '[3c] Habilitando Dark Theme...' -ForegroundColor Cyan
    $ThemePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    if (-not (Test-Path $ThemePath)) { New-Item $ThemePath -Force | Out-Null }
    Set-ItemProperty $ThemePath AppsUseLightTheme -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty $ThemePath SystemUsesLightTheme -Value 0 -ErrorAction SilentlyContinue
    Write-Host '  [OK] Dark Theme habilitado.' -ForegroundColor Green

    Write-Host '[3d] Desinstalando OneDrive...' -ForegroundColor Cyan
    Stop-Process -Name 'OneDrive*' -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $oneDriveExe = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    if (-not (Test-Path $oneDriveExe)) { $oneDriveExe = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }
    if (Test-Path $oneDriveExe) {
        Start-Process $oneDriveExe '/uninstall' -NoNewWindow -Wait -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    } else {
        Write-Host '  -> OneDriveSetup.exe nao encontrado, tentando desinstalar via winget...' -ForegroundColor Yellow
        Invoke-Winget -Arguments @('uninstall', 'Microsoft.OneDrive', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity') | Out-Null
    }
    foreach ($path in @(
        "$env:USERPROFILE\OneDrive",
        "$env:LOCALAPPDATA\Microsoft\OneDrive",
        "$env:PROGRAMDATA\Microsoft OneDrive",
        "$env:SYSTEMDRIVE\OneDriveTemp"
    )) {
        Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
    }
    foreach ($regPath in @(
        'HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}',
        'HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
    )) {
        if (-not (Test-Path $regPath)) { New-Item $regPath -Force | Out-Null }
        Set-ItemProperty $regPath System.IsPinnedToNameSpaceTree -Value 0 -ErrorAction SilentlyContinue
    }
    Remove-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' 'OneDrive' -ErrorAction SilentlyContinue
    Write-Host '  [OK] OneDrive desinstalado.' -ForegroundColor Green

    Write-Host '[3e] Desabilitando Telemetria do Windows...' -ForegroundColor Cyan
    $advPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
    if (Test-Path $advPath) { Set-ItemProperty $advPath Enabled -Value 0 -ErrorAction SilentlyContinue }
    $dataCollectionPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection',
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
    )
    foreach ($path in $dataCollectionPaths) {
        if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
        Set-ItemProperty $path AllowTelemetry -Value 0 -ErrorAction SilentlyContinue
    }
    $periodPath = 'HKCU:\Software\Microsoft\Siuf\Rules'
    if (-not (Test-Path $periodPath)) { New-Item $periodPath -Force | Out-Null }
    Set-ItemProperty $periodPath PeriodInNanoSeconds -Value 0 -ErrorAction SilentlyContinue
    foreach ($svc in @('DiagTrack','dmwappushservice')) {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
    foreach ($task in @('XblGameSaveTaskLogon','XblGameSaveTask','Consolidator','UsbCeip','DmClient','DmClientOnScenarioDownload')) {
        Get-ScheduledTask $task -ErrorAction SilentlyContinue | Disable-ScheduledTask
    }
    $sensorState = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}'
    $locationConfig = 'HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration'
    if (-not (Test-Path $sensorState)) { New-Item $sensorState -Force | Out-Null }
    Set-ItemProperty $sensorState SensorPermissionState -Value 0 -ErrorAction SilentlyContinue
    if (-not (Test-Path $locationConfig)) { New-Item $locationConfig -Force | Out-Null }
    Set-ItemProperty $locationConfig Status -Value 0 -ErrorAction SilentlyContinue
    foreach ($wifiPath in @(
        'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting',
        'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots',
        'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config'
    )) {
        if (-not (Test-Path $wifiPath)) { New-Item $wifiPath -Force | Out-Null }
        if ($wifiPath -like '*config') {
            Set-ItemProperty $wifiPath AutoConnectAllowedOEM -Value 0 -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty $wifiPath Value -Value 0 -ErrorAction SilentlyContinue
        }
    }
    Write-Host '  [OK] Telemetria desabilitada.' -ForegroundColor Green

    Write-Host '[3f] Removendo chaves de registro de Bloatware...' -ForegroundColor Cyan
    $bloatwareKeys = @(
        'HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y',
        'HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0',
        'HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe',
        'HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0',
        'HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y',
        'HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0',
        'HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe',
        'HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0',
        'HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy',
        'HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0'
    )
    $removedCount = 0
    foreach ($key in $bloatwareKeys) {
        if (Test-Path $key) {
            try { Remove-Item -Path $key -Recurse -Force -ErrorAction Stop; $removedCount++ } catch { }
        }
    }
    Write-Host "  -> $removedCount chaves HKCR removidas." -ForegroundColor Green

    Write-Host '  -> Desabilitando Windows Consumer Features...'
    $registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    $registryOEM = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    if (-not (Test-Path $registryPath)) { New-Item $registryPath -Force | Out-Null }
    foreach ($prop in @('DisableWindowsConsumerFeatures')) {
        Set-ItemProperty $registryPath $prop -Value 1 -ErrorAction SilentlyContinue
    }
    if (-not (Test-Path $registryOEM)) { New-Item $registryOEM -Force | Out-Null }
    foreach ($prop in @('ContentDeliveryAllowed','OemPreInstalledAppsEnabled','PreInstalledAppsEnabled','PreInstalledAppsEverEnabled','SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled','SubscribedContent-338389Enabled','SubscribedContent-310093Enabled')) {
        Set-ItemProperty $registryOEM $prop -Value 0 -ErrorAction SilentlyContinue
    }
    $live = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'
    if (-not (Test-Path $live)) { New-Item $live -Force | Out-Null }
    Set-ItemProperty $live NoTileApplicationNotification -Value 1 -ErrorAction SilentlyContinue
    $people = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
    if (-not (Test-Path $people)) { New-Item $people -Force | Out-Null }
    Set-ItemProperty $people PeopleBand -Value 0 -ErrorAction SilentlyContinue
    $holo = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic'
    if (Test-Path $holo) { Set-ItemProperty $holo FirstRunSucceeded -Value 0 -ErrorAction SilentlyContinue }
    Write-Host '  [OK] Windows Consumer Features desabilitadas.' -ForegroundColor Green

    Write-Host '[3g] Instalando .NET Framework 3.5...' -ForegroundColor Cyan
    try {
        $dismResult = DISM.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart 2>&1
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) {
            Write-Host '  [OK] .NET Framework 3.5 instalado com sucesso.' -ForegroundColor Green
        } elseif ($LASTEXITCODE -eq -2146498530 -or $LASTEXITCODE -eq 1242) {
            Write-Host '  [AVISO] .NET 3.5 ja esta instalado ou nao esta disponivel nesta edicao.' -ForegroundColor Yellow
        } else {
            Write-Host "  [AVISO] DISM retornou exit code $LASTEXITCODE. Tentando alternate source..." -ForegroundColor Yellow
            DISM.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /LimitAccess 2>&1 | Out-Null
        }
    } catch {
        Write-Host "  [AVISO] Erro ao instalar .NET 3.5: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host '  [OK] Debloat e hardening concluido.' -ForegroundColor Green
}

function Remove-TermporaryMachineFolder {
    Write-Section 'SECAO 4: REMOVER PASTA C:\INST\MAQUINA'
    if (Test-Path $MachineFolder) {
        Write-Host "  -> Removendo arquivos de $MachineFolder ..." -ForegroundColor White
        $files = Get-ChildItem -Path $MachineFolder -Force -ErrorAction SilentlyContinue
        $fileCount = ($files | Measure-Object).Count
        if ($fileCount -gt 0) {
            Remove-Item -Path "$MachineFolder\*" -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "  -> $fileCount arquivo(s) removido(s)." -ForegroundColor Gray
        } else {
            Write-Host '  -> Nenhum arquivo encontrado na pasta.' -ForegroundColor Gray
        }
        try {
            Remove-Item -Path $MachineFolder -Force -Recurse -ErrorAction Stop
            Write-Host "  [OK] Pasta $MachineFolder removida com sucesso." -ForegroundColor Green
        } catch {
            Write-Host "  [AVISO] Nao foi possivel remover a pasta: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  -> Pasta $MachineFolder nao encontrada. Nada a remover." -ForegroundColor Yellow
    }
}

function Install-ArcadePackages {
    Write-Section 'SECAO 5: INSTALACOES DE ARCADE'

    $packages = @(
        'Microsoft.PowerShell',
        'Notepad++.Notepad++',
        'Google.Chrome',
        'AnyDesk.AnyDesk',
        'RARLab.WinRAR'
    )
    $index = 1
    foreach ($pkg in $packages) {
        Write-Host "[$index/$($packages.Count)] Instalando: $pkg" -ForegroundColor White
        $result = Invoke-Winget -Arguments @('install', '--accept-package-agreements', '--accept-source-agreements', $pkg)
        if ($result.ExitCode -ne 0) {
            Write-Host "[AVISO] Falha ao instalar: $pkg" -ForegroundColor DarkYellow
        }
        $index++
    }
}

function Main {
    Assert-RunningAsAdministrator

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error 'winget nao encontrado. Instale o App Installer antes de executar este script.'
        exit 1
    }

    Ensure-DirectoryExists -Path $ReportRoot

    $startTime = Get-Date
    Write-Host ''
    Write-Host '=============================================================' -ForegroundColor White
    Write-Host '  Run-Maintenance.ps1 - Inicio da manutencao' -ForegroundColor Green
    Write-Host "  Iniciado em: $($startTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Gray
    Write-Host '=============================================================' -ForegroundColor White
    Write-Host ''

    Write-Section 'SECAO 1: LISTAR PROGRAMAS E ATUALIZACOES'
    $programIds = Get-ProgramInventory
    $updates = Get-WindowsUpdates
    Generate-Report -ProgramIds $programIds -Updates $updates

    Install-WhiteListApps
    Uninstall-Programs
    Apply-DebloatAndHardening
    Remove-TermporaryMachineFolder
    Install-ArcadePackages

    $endTime = Get-Date
    $elapsed = $endTime - $startTime
    Write-Host '=============================================================' -ForegroundColor White
    Write-Host '  Run-Maintenance.ps1 - EXECUCAO COMPLETA' -ForegroundColor Green
    Write-Host "  Inicio : $($startTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "  Fim    : $($endTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "  Tempo  : $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
    Write-Host '=============================================================' -ForegroundColor White
    Write-Host ''
}

Main
