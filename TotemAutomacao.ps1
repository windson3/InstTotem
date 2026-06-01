<#
.SYNOPSIS
    TotemAutomacao v4.0 - Automatacao para Quiosques Gtech Arcade
    Design: Linear-inspired dark UI com sidebar, cards e log panel

.NOTES
    Paleta Linear:
        BG_Marketing: #010102    BG_Panel: #0F1011    BG_Surface: #191A1B
        Text_Prim: #F7F8F8       Text_Sec: #D0D6E0     Text_Muted: #8A8F98
        Accent: #5E6AD2          Accent_Hover: #7170FF
        Border_Subtle: rgba(255,255,255,0.05)  Border_Std: rgba(255,255,255,0.08)
        Success: #27A644         Warning: #F59E0B       Danger: #DC283C
#>

# ============ AUTO-ELEVACAO ============
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $hostExe = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
    Start-Process -FilePath $hostExe -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
    ) -Verb RunAs
    exit
}

# ============ ASSEMBLIES ============
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

# ============ PATHS ============
$BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AssetsPath = Join-Path $BasePath "assets"
$ImagesPath = Join-Path $AssetsPath "images"
$ProgramsPath = Join-Path $AssetsPath "installers"
if (-not (Test-Path $ProgramsPath)) { $ProgramsPath = Join-Path $BasePath "Programas_Reg" }
$LogsPath = Join-Path $BasePath "logs"
$null = New-Item -ItemType Directory -Path $LogsPath -Force
$LogoPath = Join-Path $ImagesPath "Log-transparent.png"
if (-not (Test-Path $LogoPath)) { $LogoPath = Join-Path $ImagesPath "Log.png" }

# ============ LINEAR COLOR PALETTE ============
# Todas as cores como SolidColorBrush para compatibilidade WPF
function New-Brush($hex) {
    $hex = $hex.TrimStart('#')
    if ($hex.Length -eq 6) { $hex = 'FF' + $hex }
    $a = [Convert]::ToInt32($hex.Substring(0,2), 16)
    $r = [Convert]::ToInt32($hex.Substring(2,2), 16)
    $g = [Convert]::ToInt32($hex.Substring(4,2), 16)
    $b = [Convert]::ToInt32($hex.Substring(6,2), 16)
    $color = [System.Windows.Media.Color]::FromArgb($a, $r, $g, $b)
    $brush = New-Object System.Windows.Media.SolidColorBrush($color)
    $brush.Freeze()
    return $brush
}

$BG_Marketing = New-Brush "#010102"
$BG_Panel     = New-Brush "#0F1011"
$BG_Surface   = New-Brush "#191A1B"
$BG_Hover     = New-Brush "#28282C"
$BG_Active    = New-Brush "#2D0A12"
$Text_Prim    = New-Brush "#F7F8F8"
$Text_Sec     = New-Brush "#D0D6E0"
$Text_Muted   = New-Brush "#8A8F98"
$Text_Dim     = New-Brush "#62666D"
$Accent       = New-Brush "#C8142E"
$AccentHover  = New-Brush "#E03050"
$AccentDark   = New-Brush "#8C0C1E"
$AccentGlow   = New-Brush "#F03C50"
$BorderSubtle = New-Brush "#23252A"
$BorderStd    = New-Brush "#34343A"
$Green        = New-Brush "#27A644"
$Yellow       = New-Brush "#F59E0B"
$Red          = New-Brush "#DC283C"

$LogPath = Join-Path $LogsPath "Totem.log"

function Write-Log {
    param([string]$M, [string]$L = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts] [$L] $M"
    Add-Content -Path $LogPath -Value $line -ErrorAction SilentlyContinue
}

Write-Log "Totem v4.0 iniciando..." "INFO"

# ============ LOAD XAML FROM FILE ============
$xamlFile = Join-Path $BasePath "ui\TotemUI.xaml"
if (Test-Path $xamlFile) {
    $xamlStr = [System.IO.File]::ReadAllText($xamlFile, [System.Text.Encoding]::UTF8)
    Write-Log "XAML carregado de arquivo" "INFO"
} else {
    # Fallback: XAML inline (minimo)
    Write-Log "Arquivo XAML nao encontrado, usando fallback" "WARN"
    $xamlStr = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Totem" Width="1200" Height="750"><Grid><TextBlock Text="Erro: TotemUI.xaml nao encontrado" Foreground="Red" FontSize="24" VerticalAlignment="Center" HorizontalAlignment="Center"/></Grid></Window>'
}

# Replace logo placeholder
$xamlStr = $xamlStr.Replace('__LOGO__', $LogoPath)

# Parse via XmlReader (mais tolerante que [xml])
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlStr))
$window = [Windows.Markup.XamlReader]::Load($reader)
$reader.Close()

Write-Log "XAML carregado OK" "INFO"

# ============ MAP CONTROLS ============
$E = @{}
$controlNames = @(
    'btnClose', 'btnMinimize', 'TopLogo',
    'side_dashboard', 'side_install', 'side_tweaks', 'side_services',
    'side_registry', 'side_presets', 'side_backup', 'side_restore',
    'side_repair', 'side_settings',
    'ViewTitle', 'ViewPanel',
    'btnRunAll', 'btnApplyView', 'btnUndoView',
    'btnSelectAll', 'btnDeselectAll',
    'ProgressBar', 'ProgressText', 'LogList', 'btnClearLog'
)

foreach ($n in $controlNames) {
    $E[$n] = $window.FindName($n)
}

Write-Log "Controles mapeados" "INFO"

# ============ LOG FUNCTION (thread-safe) ============
$Script:UIErrors = @()

function Add-LogUI {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "OK"    { "OK" }
        "ERR"   { "ERRO" }
        "WARN"  { "AVISO" }
        default { $Level }
    }
    $line = "[$ts] [$color] $Message"
    Write-Log -M $Message -L $Level

    if ($E.LogList) {
        try {
            $E.LogList.Items.Add($line) | Out-Null
            $E.LogList.ScrollIntoView($E.LogList.Items[$E.LogList.Items.Count - 1])
        } catch {}
    }
}

Add-LogUI "Sistema pronto" "OK"

# ============ VIEW SYSTEM ============
$Script:CurrentView = "dashboard"
$Script:ViewData = @{}

function Clear-View { $E.ViewPanel.Children.Clear() }
function Set-ViewTitle($Title) { $E.ViewTitle.Text = $Title }

function Register-Card($Key, $Toggle, $Action) {
    $Script:ViewData[$Key] = @{ Toggle = $Toggle; Action = $Action }
}

# ============ BUILD VIEWS ============
function Build-DashboardView {
    Clear-View
    Set-ViewTitle "Dashboard"
    $Script:CurrentView = "dashboard"

    # System info cards
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $os = Get-CimInstance Win32_OperatingSystem
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"

        $cpuName = $cpu.Name
        $cpuCores = $cpu.NumberOfLogicalProcessors
        $ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1GB, 1)
        $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1GB, 1)
        $ramPct = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100)
        $diskFree = [math]::Round($disk.FreeSpace / 1GB, 1)
        $diskTotal = [math]::Round($disk.Size / 1GB, 1)
        $diskPct = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100)
    } catch {
        $cpuName = "N/A"
        $cpuCores = 0
        $ramUsed = 0; $ramTotal = 0; $ramPct = 0
        $diskFree = 0; $diskTotal = 0; $diskPct = 0
    }

    # Info cards row
    $infoGrid = New-Object System.Windows.Controls.Grid
    $infoGrid.Margin = "0,0,0,16"
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = "1*"
    $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = "1*"
    $c3 = New-Object System.Windows.Controls.ColumnDefinition; $c3.Width = "1*"
    $infoGrid.ColumnDefinitions.Add($c1) | Out-Null
    $infoGrid.ColumnDefinitions.Add($c2) | Out-Null
    $infoGrid.ColumnDefinitions.Add($c3) | Out-Null

    $cpuCard = New-InfoCard -Title "CPU" -Value "$cpuName" -Sub "${cpuCores} cores" -AccentColor $Accent
    [System.Windows.Controls.Grid]::SetColumn($cpuCard, 0)
    $infoGrid.Children.Add($cpuCard) | Out-Null

    $ramCard = New-InfoCard -Title "RAM" -Value "${ramUsed} / ${ramTotal} GB" -Sub "${ramPct}% usado" -AccentColor $Accent
    [System.Windows.Controls.Grid]::SetColumn($ramCard, 1)
    $infoGrid.Children.Add($ramCard) | Out-Null

    $diskCard = New-InfoCard -Title "DISCO" -Value "${diskFree} GB livres" -Sub "de ${diskTotal} GB (${diskPct}% usado)" -AccentColor $Accent
    [System.Windows.Controls.Grid]::SetColumn($diskCard, 2)
    $infoGrid.Children.Add($diskCard) | Out-Null

    $E.ViewPanel.Children.Add($infoGrid) | Out-Null

    # Quick actions header
    $hdr = New-SectionHeader -Text "Acoes Rapidas"
    $E.ViewPanel.Children.Add($hdr) | Out-Null

    $quickItems = @(
        @{ T = "Instalar Programas"; D = "Chrome, 7-Zip, Notepad++, WinRAR via Winget"; K = "quick_install" },
        @{ T = "Otimizacao Standard";  D = "Remove bloatware + tweaks de privacidade"; K = "quick_standard" },
        @{ T = "Limpeza de Disco";     D = "Temp, cache, logs antigos"; K = "quick_clean" },
        @{ T = "Ponto de Restauracao"; D = "Criar ponto antes das alteracoes"; K = "quick_restore" }
    )
    foreach ($item in $quickItems) {
        $card = New-ToggleCard -Title $item.T -Desc $item.D -Checked $true
        $E.ViewPanel.Children.Add($card.Card) | Out-Null
        Register-Card -Key $item.K -Toggle $card.Toggle -Action $item.K
    }
    Add-LogUI "Dashboard carregado" "OK"
}

function New-InfoCard {
    param($Title, $Value, $Sub, $AccentColor)
    $card = New-Object System.Windows.Controls.Border
    $card.Background = $BG_Surface
    $card.CornerRadius = "8"
    $card.Padding = "16"
    $card.Margin = "0,0,8,0"
    $card.BorderBrush = $BorderStd
    $card.BorderThickness = "1,1,1,1"

    $sp = New-Object System.Windows.Controls.StackPanel

    $titleRow = New-Object System.Windows.Controls.TextBlock
    $titleRow.Text = $Title
    $titleRow.FontSize = "10"
    $titleRow.FontWeight = "Bold"
    $titleRow.Foreground = $Text_Muted
    $titleRow.Margin = "0,0,0,8"
    $sp.Children.Add($titleRow) | Out-Null

    $valBlock = New-Object System.Windows.Controls.TextBlock
    $valBlock.Text = $Value
    $valBlock.FontSize = "13"
    $valBlock.FontWeight = "SemiBold"
    $valBlock.Foreground = $Text_Prim
    $valBlock.TextWrapping = "Wrap"
    $sp.Children.Add($valBlock) | Out-Null

    $subBlock = New-Object System.Windows.Controls.TextBlock
    $subBlock.Text = $Sub
    $subBlock.FontSize = "11"
    $subBlock.Foreground = $Text_Dim
    $subBlock.Margin = "0,4,0,0"
    $sp.Children.Add($subBlock) | Out-Null

    $card.Child = $sp
    return $card
}

function New-SectionHeader {
    param([string]$Text)
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text.ToUpper()
    $tb.FontSize = "10"
    $tb.FontWeight = "Bold"
    $tb.Foreground = $Text_Muted
    $tb.Margin = "0,8,0,6"
    return $tb
}

function New-ToggleCard {
    param([string]$Title, [string]$Desc, [bool]$Checked = $true)

    $card = New-Object System.Windows.Controls.Border
    $card.Background = $BG_Surface
    $card.BorderBrush = $BorderStd
    $card.BorderThickness = "1,1,1,1"
    $card.CornerRadius = "8"
    $card.Padding = "14,12,14,12"
    $card.Margin = "0,0,0,6"
    $card.Cursor = [System.Windows.Input.Cursors]::Hand

    $grid = New-Object System.Windows.Controls.Grid
    $col1 = New-Object System.Windows.Controls.ColumnDefinition; $col1.Width = "36"
    $col2 = New-Object System.Windows.Controls.ColumnDefinition; $col2.Width = "*"
    $col3 = New-Object System.Windows.Controls.ColumnDefinition; $col3.Width = "50"
    $grid.ColumnDefinitions.Add($col1) | Out-Null
    $grid.ColumnDefinitions.Add($col2) | Out-Null
    $grid.ColumnDefinitions.Add($col3) | Out-Null

    # Checkbox icon
    $icon = New-Object System.Windows.Controls.TextBlock
    $icon.Text = "[]"
    $icon.FontSize = "18"
    $icon.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $icon.Foreground = $(if ($Checked) { $Accent } else { $Text_Dim })
    $icon.VerticalAlignment = "Center"
    $icon.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($icon, 0)

    # Text
    $textPanel = New-Object System.Windows.Controls.StackPanel
    $textPanel.VerticalAlignment = "Center"
    $textPanel.Margin = "8,0,0,0"
    [System.Windows.Controls.Grid]::SetColumn($textPanel, 1)

    $titleBlock = New-Object System.Windows.Controls.TextBlock
    $titleBlock.Text = $Title
    $titleBlock.FontSize = "13"
    $titleBlock.FontWeight = "SemiBold"
    $titleBlock.Foreground = $Text_Prim
    $textPanel.Children.Add($titleBlock) | Out-Null

    $descBlock = New-Object System.Windows.Controls.TextBlock
    $descBlock.Text = $Desc
    $descBlock.FontSize = "10.5"
    $descBlock.Foreground = $Text_Muted
    $textPanel.Children.Add($descBlock) | Out-Null

    # Toggle
    $toggle = New-Object System.Windows.Controls.CheckBox
    $toggle.IsChecked = $Checked
    $toggle.VerticalAlignment = "Center"
    $toggle.HorizontalAlignment = "Center"
    $toggle.Style = $window.FindResource("CardToggle")
    [System.Windows.Controls.Grid]::SetColumn($toggle, 2)

    $grid.Children.Add($icon) | Out-Null
    $grid.Children.Add($textPanel) | Out-Null
    $grid.Children.Add($toggle) | Out-Null
    $card.Child = $grid

    # Toggle event to update icon color
    $accentBrush = New-Brush "#C8142E"
    $dimBrush = New-Brush "#62666D"
    $toggle.Add_Checked({
        param($s, $e)
        if ($icon -and $icon.Dispatcher) {
            $icon.Dispatcher.Invoke([action]{ $icon.Foreground = $accentBrush })
        }
    })
    $toggle.Add_Unchecked({
        param($s, $e)
        if ($icon -and $icon.Dispatcher) {
            $icon.Dispatcher.Invoke([action]{ $icon.Foreground = $dimBrush })
        }
    })

    return @{ Card = $card; Toggle = $toggle }
}

function Build-InstallView {
    Clear-View
    Set-ViewTitle "Instalacao de Programas"
    $Script:CurrentView = "install"

    $hdr = New-SectionHeader "Programas Winget (Online)"
    $E.ViewPanel.Children.Add($hdr) | Out-Null

    $wingetItems = @(
        @{ T = "PowerShell 7";  D = "Terminal moderno e poderoso"; P = "Microsoft.PowerShell" },
        @{ T = "Google Chrome"; D = "Navegador web rapido"; P = "Google.Chrome" },
        @{ T = "Notepad++";     D = "Editor de texto avancado"; P = "Notepad++.Notepad++" },
        @{ T = "7-Zip";         D = "Compactador de arquivos"; P = "7zip.7zip" },
        @{ T = "WinRAR";        D = "Gerenciador de arquivos"; P = "RARLab.WinRAR" },
        @{ T = "AnyDesk";       D = "Acesso remoto leve"; P = "AnyDesk.AnyDesk" },
        @{ T = "VCRedist x64";  D = "Runtime Visual C++"; P = "Microsoft.VCRedist.2015+.x64" }
    )
    foreach ($item in $wingetItems) {
        $card = New-ToggleCard -Title $item.T -Desc $item.D -Checked $true
        $E.ViewPanel.Children.Add($card.Card) | Out-Null
        Register-Card -Key ("winget_" + $item.P) -Toggle $card.Toggle -Action "Winget"
    }

    $hdr2 = New-SectionHeader "Instaladores Locais"
    $E.ViewPanel.Children.Add($hdr2) | Out-Null

    $localItems = @(
        @{ T = "Arcade.exe";            D = "Executavel principal da Gtech"; F = "Arcade.exe" },
        @{ T = "Gtech Launcher Setup"; D = "Instalador do launcher completo"; F = "Gtech Arcade Launcher Setup.exe" },
        @{ T = "Driver P3L";           D = "Driver impressora CUSTOM P3L"; F = "P3L_WIN_DRIVER_272.exe" },
        @{ T = "Xbox Registry";        D = "Registro para controles Xbox"; F = "XBox alteracao Registro.reg" }
    )
    foreach ($item in $localItems) {
        $exists = Test-Path (Join-Path $ProgramsPath $item.F)
        $suffix = if (-not $exists) { " [NAO ENCONTRADO]" } else { "" }
        $card = New-ToggleCard -Title ($item.T + $suffix) -Desc $item.D -Checked $exists
        $E.ViewPanel.Children.Add($card.Card) | Out-Null
        Register-Card -Key ("local_" + $item.F) -Toggle $card.Toggle -Action "Local"
    }
    Add-LogUI "View Instalacao carregada" "OK"
}

function Build-TweaksView {
    Clear-View
    Set-ViewTitle "Tweaks do Sistema"
    $Script:CurrentView = "tweaks"

    $hdr = New-SectionHeader "Remover Bloatware"
    $E.ViewPanel.Children.Add($hdr) | Out-Null

    $bloatItems = @(
        @{ T = "Microsoft Edge"; D = "Navegador (pode afetar componentes)" },
        @{ T = "OneDrive"; D = "Sincronizacao em nuvem" },
        @{ T = "Microsoft Teams"; D = "Comunicacao (alto consumo de RAM)" },
        @{ T = "Xbox + GameBar + DVR"; D = "Jogos e gravacao de tela" },
        @{ T = "Bing News / Weather"; D = "Widgets de noticias e clima" },
        @{ T = "Clipchamp"; D = "Editor de video" },
        @{ T = "Solitaire Collection"; D = "Jogo de cartas" },
        @{ T = "Zune Music / Video"; D = "Media player legado" },
        @{ T = "Maps / Alarms / Recorder"; D = "Apps de utilidade" },
        @{ T = "Todos / People / YourPhone"; D = "Apps de produtividade" },
        @{ T = "FeedbackHub / GetHelp"; D = "Telemetria e suporte" }
    )
    foreach ($item in $bloatItems) {
        $card = New-ToggleCard -Title $item.T -Desc $item.D -Checked $true
        $E.ViewPanel.Children.Add($card.Card) | Out-Null
        Register-Card -Key ("bloat_" + $item.T) -Toggle $card.Toggle -Action "Bloat"
    }
    Add-LogUI "View Tweaks carregada" "OK"
}

function Build-ServicesView {
    Clear-View
    Set-ViewTitle "Servicos do Sistema"
    $Script:CurrentView = "services"

    $hdr = New-SectionHeader "Servicos para Desativar"
    $E.ViewPanel.Children.Add($hdr) | Out-Null

    $svcItems = @(
        @{ T = "DiagTrack"; D = "Telemetria e rastreamento"; N = "DiagTrack" },
        @{ T = "SysMain (Superfetch)"; D = "Pre-carga de aplicativos"; N = "SysMain" },
        @{ T = "WSearch (Indexacao)"; D = "Indexacao de busca"; N = "WSearch" },
        @{ T = "Fax Service"; D = "Servico de fax (obsoleto)"; N = "Fax" },
        @{ T = "Geolocation"; D = "Servico de geolocalizacao"; N = "lfsvc" },
        @{ T = "Distributed Link Tracking"; D = "Rastreamento NTFS"; N = "TrkWks" }
    )
    foreach ($item in $svcItems) {
        $card = New-ToggleCard -Title $item.T -Desc $item.D -Checked $true
        $E.ViewPanel.Children.Add($card.Card) | Out-Null
        Register-Card -Key ("svc_" + $item.N) -Toggle $card.Toggle -Action "Service"
    }

    $hdr2 = New-SectionHeader "Tarefas Agendadas"
    $E.ViewPanel.Children.Add($hdr2) | Out-Null

    $taskItems = @(
        @{ T = "Customer Experience (CEIP)"; D = "Telemetria de uso"; P = "\Microsoft\Windows\Customer Experience Improvement Program\"; N = "Consolidator" },
        @{ T = "Compatibility Appraiser"; D = "Analise de compatibilidade"; P = "\Microsoft\Windows\Application Experience\"; N = "Microsoft Compatibility Appraiser" },
        @{ T = "Disk Diagnostic Collector"; D = "Coleta de diagnostico"; P = "\Microsoft\Windows\DiskDiagnostic\"; N = "Microsoft-Windows-DiskDiagnosticDataCollector" },
        @{ T = "Location Notifications"; D = "Notificacoes de localizacao"; P = "\Microsoft\Windows\Location\"; N = "Notifications" }
    )
    foreach ($item in $taskItems) {
        $card = New-ToggleCard -Title $item.T -Desc $item.D -Checked $true
        $E.ViewPanel.Children.Add($card.Card) | Out-Null
        Register-Card -Key ("task_" + $item.N) -Toggle $card.Toggle -Action "Task"
    }
    Add-LogUI "View Servicos carregada" "OK"
}

function Build-RegistryView {
    Clear-View
    Set-ViewTitle "Tweaks de Registro"
    $Script:CurrentView = "registry"

    $hdr = New-SectionHeader "Otimizacao"
    $E.ViewPanel.Children.Add($hdr) | Out-Null

    $regItems = @(
        @{ T = "Desativar GameDVR / GameBar"; D = "Remove gravacao automatica de jogos" },
        @{ T = "Desativar Cortana"; D = "Remove assistente virtual" },
        @{ T = "Desativar Telemetria"; D = "Impede coleta de dados" },
        @{ T = "Desativar Clipboard History"; D = "Remove historial da area de transferencia" },
        @{ T = "Desativar Ads no Explorer"; D = "Remove sugestoes no Explorer" }
    )
    foreach ($item in $regItems) {
        $card = New-ToggleCard -Title $item.T -Desc $item.D -Checked $true
        $E.ViewPanel.Children.Add($card.Card) | Out-Null
        Register-Card -Key ("reg_" + $item.T) -Toggle $card.Toggle -Action "Registry"
    }
    Add-LogUI "View Registro carregada" "OK"
}

function Build-PresetsView {
    Clear-View
    Set-ViewTitle "Presets"
    $Script:CurrentView = "presets"

    $presets = @(
        @{ T = "Preset Minimal"; D = "Telemetria + servicos basicos"; L = "minimal" },
        @{ T = "Preset Standard"; D = "Bloatware + tweaks + privacidade"; L = "standard" },
        @{ T = "Preset Advanced"; D = "TUDO - usar com cautela!"; L = "advanced" }
    )
    foreach ($p in $presets) {
        $card = New-Object System.Windows.Controls.Border
        $card.Background = $BG_Surface
        $card.BorderBrush = $BorderStd
        $card.BorderThickness = "1,1,1,1"
        $card.CornerRadius = "8"
        $card.Padding = "16"
        $card.Margin = "0,0,0,8"
        $card.Cursor = [System.Windows.Input.Cursors]::Hand
        $card.Tag = $p.L

        $sp = New-Object System.Windows.Controls.StackPanel
        $tTitle = New-Object System.Windows.Controls.TextBlock
        $tTitle.Text = $p.T
        $tTitle.FontSize = "14"
        $tTitle.FontWeight = "SemiBold"
        $tTitle.Foreground = $Text_Prim
        $sp.Children.Add($tTitle) | Out-Null

        $tDesc = New-Object System.Windows.Controls.TextBlock
        $tDesc.Text = $p.D
        $tDesc.FontSize = "11"
        $tDesc.Foreground = $Text_Muted
        $sp.Children.Add($tDesc) | Out-Null

        $card.Child = $sp
        $card.Add_MouseLeftButtonDown({
            param($s, $e)
            Apply-Preset -Level $s.Tag
        })
        $E.ViewPanel.Children.Add($card) | Out-Null
    }
}

function Build-BackupView {
    Clear-View
    Set-ViewTitle "Backup"
    $Script:CurrentView = "backup"
    $hdr = New-SectionHeader "Opcoes de Backup"
    $E.ViewPanel.Children.Add($hdr) | Out-Null
}

function Build-RestoreView {
    Clear-View
    Set-ViewTitle "Restauracao"
    $Script:CurrentView = "restore"
}

function Build-RepairView {
    Clear-View
    Set-ViewTitle "Reparo do SO"
    $Script:CurrentView = "repair"
}

function Build-SettingsView {
    Clear-View
    Set-ViewTitle "Configuracoes"
    $Script:CurrentView = "settings"

    $infoCard = New-Object System.Windows.Controls.Border
    $infoCard.Background = $BG_Surface
    $infoCard.CornerRadius = "8"
    $infoCard.Padding = "16"
    $sp = New-Object System.Windows.Controls.StackPanel

    $lines = @(
        "Totem v4.0",
        "Automacao para Quiosques Gtech Arcade",
        "",
        "Desenvolvido por: Windson Carlos",
        "Compatibilidade: Windows 10/11",
        "Requisitos: Admin + PowerShell 5.1+",
        "Design: Linear-inspired dark UI"
    )
    foreach ($l in $lines) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = $l
        $tb.FontSize = "11.5"
        $tb.Foreground = $Text_Muted
        $tb.Margin = "0,2,0,2"
        $sp.Children.Add($tb) | Out-Null
    }
    $infoCard.Child = $sp
    $E.ViewPanel.Children.Add($infoCard) | Out-Null
}

# ============ NAVIGATION ============
$ViewMap = @{
    side_dashboard = { Build-DashboardView }
    side_install   = { Build-InstallView }
    side_tweaks    = { Build-TweaksView }
    side_services  = { Build-ServicesView }
    side_registry  = { Build-RegistryView }
    side_presets   = { Build-PresetsView }
    side_backup    = { Build-BackupView }
    side_restore   = { Build-RestoreView }
    side_repair    = { Build-RepairView }
    side_settings  = { Build-SettingsView }
}

$SideButtons = @('side_dashboard','side_install','side_tweaks','side_services','side_registry','side_presets','side_backup','side_restore','side_repair','side_settings')

function Highlight-SideBtn($ActiveKey) {
    foreach ($key in $SideButtons) {
        $btn = $E[$key]
        if ($null -eq $btn) { continue }
        if ($key -eq $ActiveKey) {
            $brush = New-Object System.Windows.Media.SolidColorBrush(([System.Windows.Media.Color]::FromArgb(255, 45, 10, 18)))
            $btn.Background = $brush
        } else {
            $brush = New-Object System.Windows.Media.SolidColorBrush(([System.Windows.Media.Color]::FromArgb(255, 16, 16, 22)))
            $btn.Background = $brush
        }
    }
}

foreach ($key in $ViewMap.Keys) {
    $btn = $E[$key]
    if ($null -eq $btn) { continue }
    $btn.Add_Click({
        $Script:ViewData = @{}
        $clicked = $this.Name
        Highlight-SideBtn -ActiveKey $clicked
        & $ViewMap[$clicked]
    })
}

# ============ DEFAULT VIEW ============
Highlight-SideBtn -ActiveKey "side_dashboard"
Build-DashboardView

# ============ WINDOW CONTROLS ============
$E.btnClose.Add_Click({ $window.Close() })
$E.btnMinimize.Add_Click({ $window.WindowState = "Minimized" })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# ============ SELECT/DESELECT ALL ============
$E.btnSelectAll.Add_Click({
    foreach ($k in $Script:ViewData.Keys) {
        $Script:ViewData[$k].Toggle.IsChecked = $true
    }
    Add-LogUI "Todos selecionados" "INFO"
})
$E.btnDeselectAll.Add_Click({
    foreach ($k in $Script:ViewData.Keys) {
        $Script:ViewData[$k].Toggle.IsChecked = $false
    }
    Add-LogUI "Todos desmarcados" "INFO"
})

# ============ APPLY ============
$E.btnApplyView.Add_Click({
    $selected = $Script:ViewData.GetEnumerator() | Where-Object { $_.Value.Toggle.IsChecked }
    $total = $selected.Count
    if ($total -eq 0) {
        [System.Windows.MessageBox]::Show("Nenhuma opcao selecionada.", "Aviso", "OK", "Warning") | Out-Null
        return
    }
    Add-LogUI "Aplicando $total itens..." "INFO"
    $done = 0
    foreach ($entry in $selected) {
        $done++
        $pctVal = [math]::Round($done / $total * 100)
        $pctDisplay = "$done / $total ($pctVal%)"
        $E.ProgressBar.Value = $pctVal
        $E.ProgressText.Text = $pctDisplay

        $key = $entry.Key
        $action = $entry.Value.Action
        switch ($action) {
            "Winget" {
                $pkg = $key -replace "^winget_", ""
                Add-LogUI "Instalando: $pkg" "INFO"
                try {
                    $proc = Start-Process -FilePath "winget" -ArgumentList "install","--id",$pkg,"--accept-package-agreements","--accept-source-agreements","--silent" -Wait -PassThru -NoNewWindow
                    if ($proc.ExitCode -eq 0) { Add-LogUI "OK: $pkg" "OK" } else { Add-LogUI "FALHA: $pkg" "ERR" }
                } catch { Add-LogUI "ERRO: $pkg" "ERR" }
            }
            "Local" {
                $f = $key -replace "^local_", ""
                $exePath = Join-Path $ProgramsPath $f
                if (Test-Path $exePath) {
                    Add-LogUI "Executando: $f" "INFO"
                    try {
                        $ext = [System.IO.Path]::GetExtension($exePath).ToLower()
                        $args = if ($ext -eq ".reg") { @("/s", "`"$exePath`"") } else { @("/S","/quiet","/norestart") }
                        $exe = if ($ext -eq ".reg") { "regedit.exe" } else { $exePath }
                        Start-Process -FilePath $exe -ArgumentList $args -Wait -NoNewWindow | Out-Null
                        Add-LogUI "OK: $f" "OK"
                    } catch { Add-LogUI "ERRO: $f" "ERR" }
                } else { Add-LogUI "Nao encontrado: $f" "WARN" }
            }
            "Bloat" {
                $appName = $key -replace "^bloat_", ""
                Add-LogUI "Removendo: $appName" "INFO"
                try {
                    $pkgs = Get-AppxPackage -AllUsers -Name "*$appName*" -ErrorAction SilentlyContinue
                    foreach ($p in $pkgs) {
                        Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                        Add-LogUI "Removido: $($p.Name)" "OK"
                    }
                    if (-not $pkgs) { Add-LogUI "Nao encontrado: $appName" "WARN" }
                } catch { Add-LogUI "ERRO ao remover: $appName" "ERR" }
            }
            "Service" {
                $svcName = $key -replace "^svc_", ""
                Add-LogUI "Desativando: $svcName" "INFO"
                try {
                    Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
                    Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                    Add-LogUI "Desativado: $svcName" "OK"
                } catch { Add-LogUI "ERRO: $svcName" "ERR" }
            }
            "Task" {
                $taskN = $key -replace "^task_", ""
                Add-LogUI "Desativando tarefa: $taskN" "INFO"
                try {
                    $taskPath = $entry.Value.TaskPath
                    Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskN -ErrorAction SilentlyContinue | Out-Null
                    Add-LogUI "Desativada: $taskN" "OK"
                } catch { Add-LogUI "ERRO: $taskN" "ERR" }
            }
            "Registry" {
                $regKey = $key -replace "^reg_", ""
                Add-LogUI "Registro: $regKey" "INFO"
                try {
                    switch -Wildcard ($regKey) {
                        "*GameDVR*" {
                            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'ShowStartupPanel' -Value 0 -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -ErrorAction SilentlyContinue
                        }
                        "*Cortana*" {
                            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0 -ErrorAction SilentlyContinue
                        }
                        "*Telemetria*" {
                            $pPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
                            if (-not (Test-Path $pPath)) { New-Item -Path $pPath -Force | Out-Null }
                            Set-ItemProperty -Path $pPath -Name 'AllowTelemetry' -Value 0 -ErrorAction SilentlyContinue
                        }
                        "*Clipboard*" {
                            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value 0 -ErrorAction SilentlyContinue
                        }
                        "*Explorer*" {
                            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Value 0 -ErrorAction SilentlyContinue
                        }
                    }
                    Add-LogUI "Registro OK: $regKey" "OK"
                } catch { Add-LogUI "ERRO: $regKey" "ERR" }
            }
        }
    }
    $E.ProgressBar.Value = 100
    $E.ProgressText.Text = "Concluido!"
    Add-LogUI "Finalizado! $done itens." "OK"
})

# ============ UNDO ============
$E.btnUndoView.Add_Click({
    Add-LogUI "Revertendo..." "WARN"
    @("DiagTrack","SysMain","WSearch","Fax","lfsvc","TrkWks") | ForEach-Object {
        Set-Service -Name $_ -StartupType Automatic -ErrorAction SilentlyContinue
        Add-LogUI "Restaurado: $_" "OK"
    }
    $E.ProgressBar.Value = 100
    $E.ProgressText.Text = "Revertido!"
})

# ============ RUN ALL ============
$E.btnRunAll.Add_Click({
    Add-LogUI "=== EXECUTAR TUDO ===" "INFO"
    $E.btnSelectAll.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
    $E.btnApplyView.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
})

# ============ CLEAR LOG ============
$E.btnClearLog.Add_Click({ $E.LogList.Items.Clear() })

# ============ PRESETS ============
function Apply-Preset($Level) {
    foreach ($k in $Script:ViewData.Keys) { $Script:ViewData[$k].Toggle.IsChecked = $false }
    switch ($Level) {
        "minimal" {
            @("bloat_FeedbackHub / GetHelp","svc_DiagTrack","svc_SysMain","svc_WSearch") | ForEach-Object {
                if ($Script:ViewData[$_]) { $Script:ViewData[$_].Toggle.IsChecked = $true }
            }
        }
        "standard" {
            foreach ($k in $Script:ViewData.Keys) { $Script:ViewData[$k].Toggle.IsChecked = $true }
        }
        "advanced" {
            foreach ($k in $Script:ViewData.Keys) { $Script:ViewData[$k].Toggle.IsChecked = $true }
            Add-LogUI "AVANCADO: todas as opcoes marcadas!" "WARN"
        }
    }
    [System.Windows.MessageBox]::Show("Preset '$Level' aplicado. Clique em 'Aplicar' para executar.", "Preset", "OK", "Information") | Out-Null
}

# ============ SHOW ============
Add-LogUI "Interface carregada!" "OK"
try {
    $window.ShowDialog() | Out-Null
} catch {
    Add-LogUI ("ERRO FATAL: " + $_.Exception.Message) "ERR"
}
