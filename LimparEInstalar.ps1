#Requires -Version 5.0
<#
.SYNOPSIS
    Limpeza e reinstalacao de programas via winget - gerado automaticamente.
.DESCRIPTION
    Script gerado a partir de: f:\Testes APP\Maquina Teste\ListaProgramasEAtualizacao.txt
    Gerado em: 30/05/2026 23:13:10
.NOTES
    SECAO 1: Instala os 5 programas da lista branca (manter)
    SECAO 2: Desinstala todos os outros programas da lista
    Execute como Administrador: powershell -ExecutionPolicy Bypass -File "LimparEInstalar.ps1"
#>

$ErrorActionPreference = 'Continue'

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  SECAO 1: INSTALAR PROGRAMAS (lista branca)" -ForegroundColor Green
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


Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  SECAO 2: DESINSTALAR PROGRAMAS (restante)" -ForegroundColor Yellow
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


Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  LIMPEZA E REINSTALACAO CONCLUIDA" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan


# ============================================================================
#  SECAO 3: DEBLOAT / HARDENING (Windows10Debloater)
# ============================================================================

Write-Host ""
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "  SECAO 3: DEBLOAT E HARDENING DO WINDOWS" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Magenta

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

# Renomeia chave do Edge para desabilitar
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
    # Desinstalar via winget se disponivel
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

# Remover OneDrive do Startup
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
# Garantir que a chave exista com valor 0
If (!(Test-Path $DataCollection1)) { New-Item $DataCollection1 -Force | Out-Null }
Set-ItemProperty $DataCollection1 AllowTelemetry -Value 0 -ErrorAction SilentlyContinue
If (!(Test-Path $DataCollection2)) { New-Item $DataCollection2 -Force | Out-Null }
Set-ItemProperty $DataCollection2 AllowTelemetry -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando Feedback Experience..."
$Period = "HKCU:\Software\Microsoft\Siuf\Rules"
If (!(Test-Path $Period)) { New-Item $Period -Force | Out-Null }
Set-ItemProperty $Period PeriodInNanoSeconds -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Desabilitando services de telemetria..."
# DiagTrack - Diagnostics Tracking Service
Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

# dmwappushservice - WAP Push Service
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
    # Background Tasks
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
    # Windows File
    "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    # Launch
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
    # PreInstalledConfigTask
    "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
    # Protocol
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
    "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
    # Share Target
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
        # Tentar com source do Windows Update
        DISM.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /LimitAccess 2>&1 | Out-Null
    }
}
catch {
    Write-Host "  [AVISO] Erro ao instalar .NET 3.5: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "  DEBLOAT E HARDENING CONCLUIDO" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Magenta
