#Requires -Version 5.1
<#
.SYNOPSIS
    WinUtil Tweaks - Script de Otimizacao Windows
.DESCRIPTION
    Script gerado automaticamente a partir do WinUtil JSON tweaks.
    Inclui telemetry debloat, performance, privacy e UI tweaks.
.PARAMETER WhatIf
    Simula as alteracoes sem aplicar (dry-run seguro)
.PARAMETER ApplyOnly
    Aplica apenas os tweaks listados (separados por virgula)
.EXAMPLE
    .\WinUtil-Tweaks.ps1 -WhatIf
    .\WinUtil-Tweaks.ps1 -ApplyOnly "WPFTweaksRevertStartMenu,WPFTweaksDisableBitLocker"
.NOTES
    Gerado por OWL Agent - ZOO Company
    Teste em ambiente seguro ate a linha 9999
    Dica: use -WhatIf primeiro para simular alteracoes
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ApplyOnly = ""
)

$ErrorActionPreference = "Continue"
$Script:WhatIfMode = $false  # Set via SupportsShouldProcess
$Script:LogPath = "$Env:TEMP\WinUtil_Tweaks_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$Script:BackupRegPath = "$Env:TEMP\WinUtil_RegBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
$Script:ChangesApplied = 0
$Script:ChangesSkipped = 0
$Script:ChangesFailed = 0

# ============================================================
# FUNCOES AUXILIARES
# ============================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    Add-Content -Path $Script:LogPath -Value $line -Encoding UTF8
    switch ($Level) {
        "OK"     { Write-Host "[OK] $Message" -ForegroundColor Green }
        "WARN"   { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR"  { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "SKIP"   { Write-Host "[SKIP] $Message" -ForegroundColor Cyan }
        default  { Write-Host "[INFO] $Message" -ForegroundColor White }
    }
}

function Set-RegistrySafe {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type,
        $OriginalValue = $null
    )
    try {
        if ($WhatIfPreference) {
            Write-Log "WHATIF: Set $Path\$Name = $Value ($Type)" "SKIP"
            $Script:ChangesSkipped++
            return
        }

        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        $regType = switch ($Type) {
            "DWord"   { [Microsoft.Win32.RegistryValueKind]::DWord }
            "String"  { [Microsoft.Win32.RegistryValueKind]::String }
            "Binary"  { [Microsoft.Win32.RegistryValueKind]::Binary }
            "QWord"   { [Microsoft.Win32.RegistryValueKind]::QWord }
            "MultiString" { [Microsoft.Win32.RegistryValueKind]::MultiString }
            default   { [Microsoft.Win32.RegistryValueKind]::String }
        }

        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $regType -Force
        Write-Log "Set $Path\$Name = $Value ($Type)" "OK"
        $Script:ChangesApplied++
    }
    catch {
        Write-Log "Failed $Path\$Name : $_" "ERROR"
        $Script:ChangesFailed++
    }
}

function Remove-RegistrySafe {
    param([string]$Path, [string]$Name)
    try {
        if ($WhatIfPreference) {
            Write-Log "WHATIF: Remove $Path\$Name" "SKIP"
            $Script:ChangesSkipped++
            return
        }
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
        Write-Log "Removed $Path\$Name" "OK"
        $Script:ChangesApplied++
    }
    catch {
        Write-Log "Failed remove $Path\$Name : $_" "ERROR"
        $Script:ChangesFailed++
    }
}

function Set-ServiceSafe {
    param(
        [string]$Name,
        [string]$StartupType
    )
    try {
        if ($WhatIfPreference) {
            Write-Log "WHATIF: Set-Service $Name = $StartupType" "SKIP"
            $Script:ChangesSkipped++
            return
        }
        Set-Service -Name $Name -StartupType $StartupType -ErrorAction SilentlyContinue
        Write-Log "Set-Service $Name = $StartupType" "OK"
        $Script:ChangesApplied++
    }
    catch {
        Write-Log "Failed Set-Service $Name : $_" "ERROR"
        $Script:ChangesFailed++
    }
}

function Remove-AppxSafe {
    param([string]$PackageName)
    try {
        if ($WhatIfPreference) {
            Write-Log "WHATIF: Remove-AppxPackage $PackageName" "SKIP"
            $Script:ChangesSkipped++
            return
        }
        Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Write-Log "Removed Appx: $PackageName" "OK"
        $Script:ChangesApplied++
    }
    catch {
        Write-Log "Failed remove Appx $PackageName : $_" "ERROR"
        $Script:ChangesFailed++
    }
}

function Invoke-ScriptSafe {
    param([string]$ScriptBlock, [string]$Description)
    try {
        if ($WhatIfPreference) {
            Write-Log "WHATIF: $Description" "SKIP"
            $Script:ChangesSkipped++
            return
        }
        Invoke-Expression $ScriptBlock
        Write-Log "$Description - Executado" "OK"
        $Script:ChangesApplied++
    }
    catch {
        Write-Log "Failed $Description : $_" "ERROR"
        $Script:ChangesFailed++
    }
}

# ============================================================
# HEADER
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  WinUtil Tweaks - Otimizacao Windows" -ForegroundColor Cyan
Write-Host "  Gerado por OWL Agent - ZOO Company" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($WhatIfPreference) {
    Write-Host ">>> MODO WHATIF (DRY-RUN) - Nenhuma alteracao sera aplicada <<<" -ForegroundColor Yellow
    Write-Host ""
}

Write-Log "Inicio da execucao - WhatIf mode active"

# ============================================================
# TWEAKS - ESSENTIAL
# ============================================================

# --- WPFTweaksActivity: Activity History - Disable ---
Write-Host "`n[Essential] Activity History - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Activity*")
if ($apply) {
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Type "DWord"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksHiber: Hibernation - Disable ---
Write-Host "`n[Essential] Hibernation - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Hiber*")
if ($apply) {
    Set-RegistrySafe -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Value 0 -Type "DWord"
    Invoke-ScriptSafe -ScriptBlock "powercfg.exe /hibernate off" -Description "Disable hibernation powercfg"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksRevertStartMenu: Start Menu Previous Layout ---
Write-Host "`n[Essential] Start Menu Previous Layout - Enable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*StartMenu*" -or $ApplyOnly -like "*RevertStart*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    Invoke-WebRequest https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip -OutFile ViVeTool.zip
    Expand-Archive ViVeTool.zip
    Remove-Item ViVeTool.zip
    Start-Process 'ViVeTool\ViVeTool.exe' -ArgumentList '/disable /id:47205210' -Wait -NoNewWindow
    Remove-Item ViVeTool -Recurse
    Write-Host 'Old start menu reverted. Please restart your computer to take effect.'
'@ -Description "Revert Start Menu to previous layout"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksServices: Services - Set to Manual ---
Write-Host "`n[Essential] Services - Set to Manual" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Services*")
if ($apply) {
    Set-ServiceSafe -Name "CscService" -StartupType "Disabled"
    Set-ServiceSafe -Name "DiagTrack" -StartupType "Disabled"
    Set-ServiceSafe -Name "MapsBroker" -StartupType "Manual"
    Set-ServiceSafe -Name "StorSvc" -StartupType "Manual"
    Set-ServiceSafe -Name "SharedAccess" -StartupType "Disabled"
    Invoke-ScriptSafe -ScriptBlock @'
    $Memory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1KB
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name SvcHostSplitThresholdInKB -Value $Memory
'@ -Description "Adjust SvcHostSplitThresholdInKB to match system memory"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksTelemetry: Telemetry - Disable ---
Write-Host "`n[Essential] Telemetry - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Telemetry*")
if ($apply) {
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Input\TIPC" -Name "Enabled" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0 -Type "DWord"
    Invoke-ScriptSafe -ScriptBlock @'
    Set-MpPreference -SubmitSamplesConsent 2
    Set-Service -Name diagtrack -StartupType Disabled
    Set-Service -Name wermgr -StartupType Disabled
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name PeriodInNanoSeconds -ErrorAction SilentlyContinue
'@ -Description "Disable telemetry services and Defender sample submission"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksPowershell7Tele: PowerShell 7 Telemetry - Disable ---
Write-Host "`n[Essential] PowerShell 7 Telemetry - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Powershell7*" -or $ApplyOnly -like "*PS7*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')
'@ -Description "Set POWERSHELL_TELEMETRY_OPTOUT environment variable"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksLocation: Location Tracking - Disable ---
Write-Host "`n[Essential] Location Tracking - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Location*")
if ($apply) {
    Set-ServiceSafe -Name "lfsvc" -StartupType "Disabled"
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type "String"
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Value 0 -Type "DWord"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksDisableStoreSearch: Microsoft Store Recommended Search - Disable ---
Write-Host "`n[Essential] Microsoft Store Recommended Search - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*StoreSearch*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    icacls "$Env:LocalAppData\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db" /deny Everyone:F
'@ -Description "Block Store search results in Start Menu"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksRestorePoint: Restore Point - Create ---
Write-Host "`n[Essential] Restore Point - Create" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*RestorePoint*")
if ($apply) {
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type "DWord"
    Invoke-ScriptSafe -ScriptBlock @'
    if (-not (Get-ComputerRestorePoint)) {
        Enable-ComputerRestore -Drive $Env:SystemDrive
    }
    Checkpoint-Computer -Description "System Restore Point created by WinUtil" -RestorePointType MODIFY_SETTINGS
    Write-Host "System Restore Point Created Successfully" -ForegroundColor Green
'@ -Description "Create system restore point"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksDeBloat: Unwanted Pre-Installed Apps - Remove ---
Write-Host "`n[Essential] Unwanted Pre-Installed Apps - Remove" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*DeBloat*" -or $ApplyOnly -like "*Bloat*")
if ($apply) {
    $bloatApps = @(
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.BingNews",
        "Microsoft.BingSearch",
        "Microsoft.BingWeather",
        "Clipchamp.Clipchamp",
        "Microsoft.Todos",
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.Windows.DevHome",
        "Microsoft.Paint",
        "Microsoft.OutlookForWindows",
        "Microsoft.WindowsAlarms",
        "Microsoft.StartExperiencesApp",
        "Microsoft.GetHelp",
        "Microsoft.ZuneMusic",
        "MicrosoftCorporationII.QuickAssist",
        "MSTeams"
    )
    foreach ($app in $bloatApps) {
        Remove-AppxSafe -PackageName $app
    }
    Invoke-ScriptSafe -ScriptBlock @'
    $TeamsPath = "$Env:LocalAppData\Microsoft\Teams\Update.exe"
    if (Test-Path $TeamsPath) {
        Write-Host "Uninstalling Teams"
        Start-Process $TeamsPath -ArgumentList "-uninstall" -Wait
        Write-Host "Deleting Teams directory"
        Remove-Item $TeamsPath -Recurse -Force
    }
'@ -Description "Uninstall Microsoft Teams"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksDeleteTempFiles: Temporary Files - Remove ---
Write-Host "`n[Essential] Temporary Files - Remove" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*TempFiles*" -or $ApplyOnly -like "*DeleteTemp*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    Remove-Item -Path "$Env:Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$Env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
'@ -Description "Clean TEMP folders"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksDiskCleanup: Disk Cleanup - Run ---
Write-Host "`n[Essential] Disk Cleanup - Run" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*DiskCleanup*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    cleanmgr.exe /d C: /VERYLOWDISK
    Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
'@ -Description "Run Disk Cleanup and DISM component cleanup"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksConsumerFeatures: ConsumerFeatures - Disable ---
Write-Host "`n[Essential] ConsumerFeatures - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*ConsumerFeatures*")
if ($apply) {
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type "DWord"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksDisableBitLocker: BitLocker - Disable ---
Write-Host "`n[Essential] BitLocker - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*BitLocker*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    Disable-BitLocker -MountPoint $Env:SystemDrive
'@ -Description "Disable BitLocker"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksWPBT: Windows Platform Binary Table - Disable ---
Write-Host "`n[Essential] WPBT - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*WPBT*")
if ($apply) {
    Set-RegistrySafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "DisableWpbtExecution" -Value 1 -Type "DWord"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksEndTaskOnTaskbar: End Task With Right Click - Enable ---
Write-Host "`n[Essential] End Task With Right Click - Enable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*EndTask*")
if ($apply) {
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type "DWord"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksDisableExplorerAutoDiscovery: File Explorer Auto Discovery - Disable ---
Write-Host "`n[Essential] File Explorer Auto Discovery - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*ExplorerAuto*" -or $ApplyOnly -like "*AutoDiscovery*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    $bags = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags"
    $bagMRU = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU"
    Remove-Item -Path $bags -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed $bags"
    Remove-Item -Path $bagMRU -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed $bagMRU"
    $allFolders = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"
    if (!(Test-Path $allFolders)) {
        New-Item -Path $allFolders -Force | Out-Null
        Write-Host "Created $allFolders"
    }
    New-ItemProperty -Path $allFolders -Name "FolderType" -Value "NotSpecified" -PropertyType String -Force | Out-Null
    Write-Host "Set FolderType to NotSpecified"
    Write-Host "Please sign out and back in, or restart your computer to apply the changes!"
'@ -Description "Disable Explorer automatic folder type discovery"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksDisableBGapps: Background Apps - Disable ---
Write-Host "`n[Essential] Background Apps - Disable" -ForegroundColor Magenta
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*BGapps*" -or $ApplyOnly -like "*BackgroundApps*")
if ($apply) {
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type "DWord"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# ============================================================
# TWEAKS - ADVANCED (CAUTION)
# ============================================================

# --- WPFTweaksXboxRemoval: Xbox & Gaming Components - Remove ---
Write-Host "`n[Advanced] Xbox & Gaming Components - Remove" -ForegroundColor Red
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Xbox*")
if ($apply) {
    Set-RegistrySafe -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type "DWord"
    $xboxApps = @(
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.GamingApp",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGamingOverlay"
    )
    foreach ($app in $xboxApps) {
        Remove-AppxSafe -PackageName $app
    }
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksWindowsAI: Windows AI - Disable ---
Write-Host "`n[Advanced] Windows AI - Disable" -ForegroundColor Red
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*WindowsAI*" -or $ApplyOnly -like "*AI*")
if ($apply) {
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "SettingsPageVisibility" -Value "hide:aicomponents" -Type "String"
    Set-RegistrySafe -Path "HKLM:\SOFTWARE\Policies\WindowsNotepad" -Name "DisableAIFeatures" -Value 1 -Type "DWord"
    Invoke-ScriptSafe -ScriptBlock @'
    $Appx = (Get-AppxPackage MicrosoftWindows.Client.CoreAI).PackageFullName
    $Sid = (Get-LocalUser $Env:UserName).Sid.Value
    New-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$Sid\$Appx" -Force | Out-Null
    Get-AppxPackage -AllUsers *Copilot* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers Microsoft.MicrosoftOfficeHub | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Remove-AppxPackage $Appx -ErrorAction SilentlyContinue
    Set-Service -Name WSAIFabricSvc -StartupType Disabled -ErrorAction SilentlyContinue
    Disable-WindowsOptionalFeature -FeatureName Recall -Online -ErrorAction SilentlyContinue
    Write-Host "Windows AI Disabled"
'@ -Description "Disable Windows AI features and packages"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksDisplay: Visual Effects - Set to Best Performance ---
Write-Host "`n[Advanced] Visual Effects - Best Performance" -ForegroundColor Red
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Display*" -or $ApplyOnly -like "*VisualEffects*")
if ($apply) {
    Set-RegistrySafe -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value "0" -Type "String"
    Set-RegistrySafe -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "200" -Type "String"
    Set-RegistrySafe -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type "String"
    Set-RegistrySafe -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type "DWord"
    Set-RegistrySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type "DWord"
    Invoke-ScriptSafe -ScriptBlock @'
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
'@ -Description "Set visual effects to best performance"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksRemoveOneDrive: Microsoft OneDrive - Remove ---
Write-Host "`n[Advanced] Microsoft OneDrive - Remove" -ForegroundColor Red
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*OneDrive*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    icacls $Env:OneDrive /deny "Administrators:(D,DC)"
    Write-Host "Uninstalling OneDrive..."
    Start-Process 'C:\Windows\System32\OneDriveSetup.exe' -ArgumentList '/uninstall' -Wait
    Write-Host "Removing leftover OneDrive Files..."
    Stop-Process -Name FileCoAuth,Explorer -ErrorAction SilentlyContinue
    Remove-Item "$Env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    icacls $Env:OneDrive /grant "Administrators:(D,DC)"
    if (-not (Get-ChildItem -Path $Env:OneDrive -ErrorAction SilentlyContinue)) {
        Remove-Item -Path $Env:OneDrive -ErrorAction SilentlyContinue
        [Environment]::SetEnvironmentVariable('OneDrive', $null, 'User')
    }
    Set-Service -Name OneSyncSvc -StartupType Disabled -ErrorAction SilentlyContinue
'@ -Description "Remove Microsoft OneDrive"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksRemoveEdge: Microsoft Edge - Remove ---
Write-Host "`n[Advanced] Microsoft Edge - Remove" -ForegroundColor Red
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Edge*" -or $ApplyOnly -like "*RemoveEdge*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    Invoke-WinUtilRemoveEdge
'@ -Description "Remove Microsoft Edge"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# --- WPFTweaksBlockAdobeNet: Adobe URL Block List - Enable ---
Write-Host "`n[Advanced] Adobe URL Block List - Enable" -ForegroundColor Red
$apply = ($ApplyOnly -eq "" -or $ApplyOnly -like "*Adobe*" -or $ApplyOnly -like "*BlockAdobe*")
if ($apply) {
    Invoke-ScriptSafe -ScriptBlock @'
    $hostsUrl = Invoke-RestMethod -Uri https://github.com/Ruddernation-Designs/Adobe-URL-Block-List/raw/refs/heads/master/hosts
    Add-Content -Path "$Env:SystemRoot\System32\drivers\etc\hosts" -Value $hostsUrl
    ipconfig /flushdns
    Write-Host "Added Adobe url block list from host file"
'@ -Description "Add Adobe URL block list to hosts file"
} else { Write-Log "Skipped by ApplyOnly filter" "SKIP" }

# ============================================================
# RESUMO FINAL
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RESUMO DA EXECUCAO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Aplicados:  $($Script:ChangesApplied)" -ForegroundColor Green
Write-Host "  Ignorados:  $($Script:ChangesSkipped)" -ForegroundColor Yellow
Write-Host "  Falhas:     $($Script:ChangesFailed)" -ForegroundColor Red
Write-Host ""
Write-Host "  Log salvo em: $($Script:LogPath)" -ForegroundColor White
Write-Host ""

Write-Log "Fim da execucao - Applied=$($Script:ChangesApplied) Skipped=$($Script:ChangesSkipped) Failed=$($Script:ChangesFailed)"

if ($WhatIfPreference) {
    Write-Host ">>> Este foi um DRY-RUN (WhatIf). Nenhuma alteracao foi aplicada. <<<" -ForegroundColor Yellow
    Write-Host ">>> Para aplicar, execute sem o parametro -WhatIf <<<" -ForegroundColor Yellow
}
