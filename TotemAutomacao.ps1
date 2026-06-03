<#
.SYNOPSIS
    TotemAutomacao v4.0 - Automacao para quiosques Gtech Arcade.
.NOTES
    A pasta scripts/ e lida em runtime.
    Cada subpasta em scripts/ vira um botao na sidebar esquerda.
    Ao abrir uma pasta/categoria, os scripts aparecem no painel central.
    A coleta de informacoes do sistema usa APIs leves do .NET/registro.
#>

[CmdletBinding()]
param(
    [switch]$AutoRunAll,
    [switch]$CloseWhenDone,
    [switch]$SmokeTest,
    [ValidateRange(0, 60)]
    [int]$SmokeTestHoldSeconds = 0
)

# ============ AUTO-ELEVACAO ============
if (-not $SmokeTest -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $hostExe = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
    $relaunchArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'))
    if ($AutoRunAll) { $relaunchArgs += '-AutoRunAll' }
    if ($CloseWhenDone) { $relaunchArgs += '-CloseWhenDone' }
    Start-Process -FilePath $hostExe -ArgumentList $relaunchArgs -Verb RunAs
    exit
}

# ============ ASSEMBLIES ============
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

foreach ($timerName in @('SysTimer', 'SmokeTimer')) {
    try {
        $oldTimer = Get-Variable -Scope Script -Name $timerName -ValueOnly -ErrorAction SilentlyContinue
        if ($oldTimer -and $oldTimer -is [System.Windows.Threading.DispatcherTimer]) {
            $oldTimer.Stop()
        }
    } catch {}
}

# ============ PATHS ============
$BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$AssetsPath = Join-Path $BasePath "assets"
$ImagesPath = Join-Path $AssetsPath "images"
$ProgramsPath = Join-Path $AssetsPath "installers"
if (-not (Test-Path -LiteralPath $ProgramsPath)) { $ProgramsPath = Join-Path $BasePath "Programas_Reg" }
$LogsPath = Join-Path $BasePath "logs"
$null = New-Item -ItemType Directory -Path $LogsPath -Force
$LogoPath = Join-Path $ImagesPath "Log-transparent.png"
if (-not (Test-Path -LiteralPath $LogoPath)) { $LogoPath = Join-Path $ImagesPath "Log.png" }
$ScriptsPath = Join-Path $BasePath "scripts"

# ============ COLORS ============
function New-Brush {
    param([Parameter(Mandatory)][string]$Hex)

    $cleanHex = $Hex.TrimStart('#')
    if ($cleanHex.Length -eq 6) { $cleanHex = 'FF' + $cleanHex }
    $a = [Convert]::ToInt32($cleanHex.Substring(0, 2), 16)
    $r = [Convert]::ToInt32($cleanHex.Substring(2, 2), 16)
    $g = [Convert]::ToInt32($cleanHex.Substring(4, 2), 16)
    $b = [Convert]::ToInt32($cleanHex.Substring(6, 2), 16)
    $brush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb($a, $r, $g, $b))
    $brush.Freeze()
    return $brush
}

$BG_Surface   = New-Brush "#191A1B"
$Text_Prim    = New-Brush "#F7F8F8"
$Text_Muted   = New-Brush "#8A8F98"
$Text_Dim     = New-Brush "#62666D"
$Accent       = New-Brush "#C8142E"
$BorderSubtle = New-Brush "#23252A"
$BorderStd    = New-Brush "#34343A"

$Script:ScriptExtensions = @(".ps1", ".bat", ".cmd", ".vbs")
$Script:TextDocumentExtensions = @(".md", ".txt", ".html", ".htm")
$Script:OpenDocumentExtensions = @(".pdf", ".doc", ".docx")
$Script:DocumentExtensions = @($Script:TextDocumentExtensions + $Script:OpenDocumentExtensions)
$Script:PreviewMaxBytes = 64KB
$Script:PreviewMaxLines = 200

# ============ LOG ============
$LogPath = Join-Path $LogsPath "Totem.log"
$Script:MaxLogItems = 300

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $ts = Get-Date -Format "HH:mm:ss"
    Add-Content -LiteralPath $LogPath -Value "[$ts] [$Level] $Message" -Encoding UTF8 -ErrorAction SilentlyContinue
}

Write-Log -Message "Totem v4.0 iniciando..." -Level "INFO"

# ============ LOAD XAML ============
$xamlFile = Join-Path $BasePath "ui\TotemUI.xaml"
if (Test-Path -LiteralPath $xamlFile) {
    $xamlStr = [System.IO.File]::ReadAllText($xamlFile, [System.Text.Encoding]::UTF8)
} else {
    $xamlStr = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Totem" Width="1200" Height="750"><Grid><TextBlock Text="Erro: TotemUI.xaml nao encontrado" Foreground="Red" FontSize="24" VerticalAlignment="Center" HorizontalAlignment="Center"/></Grid></Window>'
}

$xamlStr = $xamlStr.Replace('__LOGO__', $LogoPath)
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlStr))
$window = [Windows.Markup.XamlReader]::Load($reader)
$reader.Close()
$window.Title = "InstTotem - Totem Automacao"
Write-Log -Message "XAML carregado OK" -Level "INFO"

# ============ MAP CONTROLS ============
$E = @{}
foreach ($name in @(
    'btnClose', 'btnMinimize', 'TopBar', 'TopLogo',
    'NavPanel', 'ViewTitle', 'ViewSubtitle', 'ViewPanel',
    'btnRunAll', 'btnApplyView', 'btnUndoView', 'btnSelectAll', 'btnDeselectAll',
    'ProgressBar', 'ProgressText', 'LogList', 'btnClearLog',
    'SysCpuName', 'SysCpuBar', 'SysCpuText',
    'SysRamValue', 'SysRamBar', 'SysRamText',
    'SysDiskValue', 'SysDiskBar', 'SysDiskText'
)) {
    $E[$name] = $window.FindName($name)
}
Write-Log -Message "Controles mapeados" -Level "INFO"

function Add-LogUI {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    Write-Log -Message $Message -Level $Level

    if ($E.LogList) {
        try {
            while ($E.LogList.Items.Count -ge $Script:MaxLogItems) {
                $E.LogList.Items.RemoveAt(0)
            }
            $E.LogList.Items.Add($line) | Out-Null
            $E.LogList.ScrollIntoView($line)
        } catch {}
    }
}

Add-LogUI -Message "Sistema pronto" -Level "OK"

# ============ SYSTEM INFO ============
function Get-SystemSnapshot {
    $snapshot = [ordered]@{
        CpuName = "N/A"
        CpuCores = 0
        RamText = "N/A"
        RamPct = 0
        DiskText = "N/A"
        DiskTotal = "N/A"
        DiskPct = 0
    }

    try {
        $cpu = Get-ItemProperty -LiteralPath 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -Name ProcessorNameString -ErrorAction Stop
        $snapshot.CpuName = [string]$cpu.ProcessorNameString
    } catch {}

    try {
        $snapshot.CpuCores = [int]$env:NUMBER_OF_PROCESSORS
    } catch {}

    try {
        Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
        $computerInfo = [Microsoft.VisualBasic.Devices.ComputerInfo]::new()
        $ramTotalBytes = [double]$computerInfo.TotalPhysicalMemory
        $ramFreeBytes = [double]$computerInfo.AvailablePhysicalMemory
        $ramUsedBytes = [Math]::Max(0, $ramTotalBytes - $ramFreeBytes)
        $ramTotalGB = [Math]::Round($ramTotalBytes / 1GB, 1)
        $ramUsedGB = [Math]::Round($ramUsedBytes / 1GB, 1)
        $snapshot.RamPct = if ($ramTotalBytes -gt 0) { [Math]::Round(($ramUsedBytes / $ramTotalBytes) * 100, 0) } else { 0 }
        $snapshot.RamText = "$ramUsedGB / $ramTotalGB GB"
    } catch {}

    try {
        $driveRoot = [System.IO.Path]::GetPathRoot("$env:SystemDrive\")
        $drive = [System.IO.DriveInfo]::new($driveRoot)
        if ($drive.IsReady) {
            $diskFreeGB = [Math]::Round($drive.AvailableFreeSpace / 1GB, 1)
            $diskTotalGB = [Math]::Round($drive.TotalSize / 1GB, 1)
            $snapshot.DiskPct = if ($drive.TotalSize -gt 0) { [Math]::Round((($drive.TotalSize - $drive.AvailableFreeSpace) / $drive.TotalSize) * 100, 0) } else { 0 }
            $snapshot.DiskText = "$diskFreeGB GB livres"
            $snapshot.DiskTotal = "de $diskTotalGB GB ($($snapshot.DiskPct)% usado)"
        }
    } catch {}

    return [pscustomobject]$snapshot
}

function Update-SystemInfoUI {
    $Script:SysInfo = Get-SystemSnapshot
    $cpuText = "$($Script:SysInfo.CpuName) ($($Script:SysInfo.CpuCores) cores)"

    if ($E.SysCpuName) { $E.SysCpuName.Text = $cpuText }
    if ($E.SysCpuBar) { $E.SysCpuBar.Value = 0 }
    if ($E.SysCpuText) { $E.SysCpuText.Text = "info" }
    if ($E.SysRamValue) { $E.SysRamValue.Text = $Script:SysInfo.RamText }
    if ($E.SysRamBar) { $E.SysRamBar.Value = [Math]::Min($Script:SysInfo.RamPct, 100) }
    if ($E.SysRamText) { $E.SysRamText.Text = "$($Script:SysInfo.RamPct)% usado" }
    if ($E.SysDiskValue) { $E.SysDiskValue.Text = $Script:SysInfo.DiskText }
    if ($E.SysDiskBar) { $E.SysDiskBar.Value = [Math]::Min($Script:SysInfo.DiskPct, 100) }
    if ($E.SysDiskText) { $E.SysDiskText.Text = $Script:SysInfo.DiskTotal }
}

Update-SystemInfoUI

function Update-SystemInfo {
    Update-SystemInfoUI
}

# ============ VIEW STATE ============
$Script:CurrentView = "dashboard"
$Script:ViewData = @{}

function Clear-View {
    if ($E.ViewPanel) { $E.ViewPanel.Children.Clear() }
}

function Set-ViewTitle {
    param([string]$Text)
    if ($E.ViewTitle) { $E.ViewTitle.Text = $Text }
}

function Set-ViewSubtitle {
    param([string]$Text)
    if ($E.ViewSubtitle) { $E.ViewSubtitle.Text = $Text }
}

function Register-Card {
    param(
        [string]$Key,
        $Toggle,
        [string]$Action,
        [string]$FilePath = "",
        [string]$Category = ""
    )

    $Script:ViewData[$Key] = @{
        Toggle = $Toggle
        Action = $Action
        FilePath = $FilePath
        Category = $Category
    }
}

function Get-StyleOrNull {
    param([string]$Key)

    try {
        return $window.FindResource($Key)
    } catch {
        return $null
    }
}

function New-SectionHeader {
    param([string]$Text)

    $tb = [System.Windows.Controls.TextBlock]::new()
    $tb.Text = $Text.ToUpperInvariant()
    $tb.FontSize = 10
    $tb.FontWeight = "Bold"
    $tb.Foreground = $Text_Muted
    $tb.Margin = "0,8,0,6"
    return $tb
}

function New-InfoText {
    param([string]$Text)

    $tb = [System.Windows.Controls.TextBlock]::new()
    $tb.Text = $Text
    $tb.FontSize = 12
    $tb.Foreground = $Text_Dim
    $tb.Margin = "0,8,0,0"
    $tb.TextWrapping = "Wrap"
    return $tb
}

function New-FolderCard {
    param(
        [string]$Title,
        [string]$Description,
        [bool]$Clickable = $true
    )

    $card = [System.Windows.Controls.Border]::new()
    $card.Background = $BG_Surface
    $card.BorderBrush = $BorderStd
    $card.BorderThickness = "1,1,1,1"
    $card.CornerRadius = "8"
    $card.Padding = "14,12,14,12"
    $card.Margin = "0,0,0,6"
    $card.Cursor = if ($Clickable) { [System.Windows.Input.Cursors]::Hand } else { [System.Windows.Input.Cursors]::Arrow }

    $panel = [System.Windows.Controls.StackPanel]::new()
    $titleBlock = [System.Windows.Controls.TextBlock]::new()
    $titleBlock.Text = $Title
    $titleBlock.FontSize = 13
    $titleBlock.FontWeight = "SemiBold"
    $titleBlock.Foreground = $Text_Prim
    $panel.Children.Add($titleBlock) | Out-Null

    $descBlock = [System.Windows.Controls.TextBlock]::new()
    $descBlock.Text = $Description
    $descBlock.FontSize = 10.5
    $descBlock.Foreground = $Text_Muted
    $panel.Children.Add($descBlock) | Out-Null

    $card.Child = $panel
    return $card
}

function New-CategoryTag {
    param(
        [string]$Name,
        [string]$Folder
    )

    return [pscustomobject]@{
        Name = $Name
        Folder = $Folder
    }
}

function New-DocumentTag {
    param(
        [string]$Name,
        [string]$FilePath,
        [string]$Extension
    )

    return [pscustomobject]@{
        Name = $Name
        FilePath = $FilePath
        Extension = $Extension
        Type = "DocumentOpen"
    }
}

function Open-CategoryFromSender {
    param($Sender)

    if (-not $Sender -or -not $Sender.Tag) {
        Add-LogUI -Message "Clique ignorado: item sem pasta associada." -Level "WARN"
        return
    }

    $categoryName = [string]$Sender.Tag.Name
    $folderPath = [string]$Sender.Tag.Folder
    Build-CategoryView -CategoryName $categoryName -FolderPath $folderPath
}

function Open-DocumentFromSender {
    param($Sender)

    if (-not $Sender -or -not $Sender.Tag -or -not $Sender.Tag.FilePath) {
        Add-LogUI -Message "Clique ignorado: documento sem arquivo associado." -Level "WARN"
        return
    }

    Open-DocumentFile -FilePath ([string]$Sender.Tag.FilePath) | Out-Null
}

function Read-TextPreview {
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return "Arquivo nao encontrado."
    }

    try {
        $fileInfo = Get-Item -LiteralPath $FilePath -ErrorAction Stop
        $byteCount = [int][Math]::Min([int64]$Script:PreviewMaxBytes, [int64]$fileInfo.Length)
        if ($byteCount -le 0) {
            return "[Arquivo vazio]"
        }

        $buffer = [byte[]]::new($byteCount)
        $stream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $read = $stream.Read($buffer, 0, $byteCount)
        } finally {
            $stream.Dispose()
        }

        $text = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $read)
        $lines = @($text -split "`r?`n")
        if ($lines.Count -gt $Script:PreviewMaxLines) {
            $lines = $lines[0..($Script:PreviewMaxLines - 1)]
            return (($lines -join [Environment]::NewLine) + [Environment]::NewLine + "[Preview limitado]")
        }

        if ($fileInfo.Length -gt $Script:PreviewMaxBytes) {
            return (($lines -join [Environment]::NewLine) + [Environment]::NewLine + "[Preview limitado]")
        }

        return ($lines -join [Environment]::NewLine)
    } catch {
        return "Nao foi possivel ler o preview: $($_.Exception.Message)"
    }
}

function Convert-HtmlToPreviewMarkup {
    param([string]$Html)

    $text = $Html
    $text = [regex]::Replace($text, '(?is)<script\b[^>]*>.*?</script>', '')
    $text = [regex]::Replace($text, '(?is)<style\b[^>]*>.*?</style>', '')
    $text = [regex]::Replace($text, '(?is)<h1\b[^>]*>(.*?)</h1>', "`n# `$1`n")
    $text = [regex]::Replace($text, '(?is)<h2\b[^>]*>(.*?)</h2>', "`n## `$1`n")
    $text = [regex]::Replace($text, '(?is)<h3\b[^>]*>(.*?)</h3>', "`n### `$1`n")
    $text = [regex]::Replace($text, '(?is)<h4\b[^>]*>(.*?)</h4>', "`n#### `$1`n")
    $text = [regex]::Replace($text, '(?is)<strong\b[^>]*>(.*?)</strong>', '**$1**')
    $text = [regex]::Replace($text, '(?is)<b\b[^>]*>(.*?)</b>', '**$1**')
    $text = [regex]::Replace($text, '(?is)<em\b[^>]*>(.*?)</em>', '*$1*')
    $text = [regex]::Replace($text, '(?is)<i\b[^>]*>(.*?)</i>', '*$1*')
    $text = [regex]::Replace($text, '(?is)<code\b[^>]*>(.*?)</code>', '`$1`')
    $text = [regex]::Replace($text, '(?is)<pre\b[^>]*>(.*?)</pre>', "`n``` `n`$1`n``` `n")
    $text = [regex]::Replace($text, '(?is)<li\b[^>]*>(.*?)</li>', "`n- `$1")
    $text = [regex]::Replace($text, '(?is)</p\s*>', "`n`n")
    $text = [regex]::Replace($text, '(?is)<br\s*/?>', "`n")
    $text = [regex]::Replace($text, '(?is)</div\s*>', "`n")
    $text = [regex]::Replace($text, '(?is)</section\s*>', "`n")
    $text = [regex]::Replace($text, '(?is)<a\b[^>]*href=["'']?([^"''>\s]+)["'']?[^>]*>(.*?)</a>', '[$2]($1)')
    $text = [regex]::Replace($text, '(?is)<[^>]+>', '')
    return [System.Net.WebUtility]::HtmlDecode($text)
}

function Convert-MarkdownLineToPreviewMarkup {
    param([string]$Line)

    $text = $Line

    $text = [regex]::Replace($text, '\[!\[([^\]]*)\]\([^)]+\)\]\(([^)]+)\)', '[$1]($2)')
    $text = [regex]::Replace($text, '!\[([^\]]*)\]\([^)]+\)', '[Imagem: $1](#)')

    $text = [regex]::Replace($text, '(?is)<h1\b[^>]*>(.*?)</h1>', '# $1')
    $text = [regex]::Replace($text, '(?is)<h2\b[^>]*>(.*?)</h2>', '## $1')
    $text = [regex]::Replace($text, '(?is)<h3\b[^>]*>(.*?)</h3>', '### $1')
    $text = [regex]::Replace($text, '(?is)<h4\b[^>]*>(.*?)</h4>', '#### $1')
    $text = [regex]::Replace($text, '(?is)<h5\b[^>]*>(.*?)</h5>', '##### $1')
    $text = [regex]::Replace($text, '(?is)<h6\b[^>]*>(.*?)</h6>', '###### $1')
    $text = [regex]::Replace($text, '(?is)<strong\b[^>]*>(.*?)</strong>', '**$1**')
    $text = [regex]::Replace($text, '(?is)<b\b[^>]*>(.*?)</b>', '**$1**')
    $text = [regex]::Replace($text, '(?is)<em\b[^>]*>(.*?)</em>', '*$1*')
    $text = [regex]::Replace($text, '(?is)<i\b[^>]*>(.*?)</i>', '*$1*')
    $text = [regex]::Replace($text, '(?is)<code\b[^>]*>(.*?)</code>', '`$1`')
    $text = [regex]::Replace($text, '(?is)<a\b[^>]*href=["'']?([^"''>\s]+)["'']?[^>]*>(.*?)</a>', '[$2]($1)')
    $text = [regex]::Replace($text, '(?is)<li\b[^>]*>(.*?)</li>', '- $1')
    $text = [regex]::Replace($text, '(?is)<br\s*/?>', "`n")
    $text = [regex]::Replace($text, '(?is)<hr\s*/?>', "`n---`n")
    $text = [regex]::Replace($text, '(?is)</?(div|section|article|main|header|footer|center|span|p|ul|ol)\b[^>]*>', '')

    return $text
}

function Convert-MarkdownToPreviewMarkup {
    param([string]$Markdown)

    $cleanMarkdown = [regex]::Replace($Markdown, '(?is)<!--.*?-->', '')
    $lines = @($cleanMarkdown -split "`r?`n")
    $convertedLines = [System.Collections.Generic.List[string]]::new()
    $inCodeBlock = $false

    foreach ($line in $lines) {
        if ($line.Trim().StartsWith('```')) {
            $inCodeBlock = -not $inCodeBlock
            $convertedLines.Add($line) | Out-Null
            continue
        }

        if ($inCodeBlock) {
            $convertedLines.Add($line) | Out-Null
            continue
        }

        $convertedLines.Add((Convert-MarkdownLineToPreviewMarkup -Line $line)) | Out-Null
    }

    return [System.Net.WebUtility]::HtmlDecode(($convertedLines -join [Environment]::NewLine))
}

function Add-FormattedInlineText {
    param(
        [System.Windows.Documents.Paragraph]$Paragraph,
        [string]$Text
    )

    if ([string]::IsNullOrEmpty($Text)) { return }

    $pattern = '(~~[^~]+~~|\*\*[^*]+\*\*|__[^_]+__|\*[^*]+\*|_[^_]+_|`[^`]+`|\[[^\]]+\]\([^)]+\)|https?://[^\s]+)'
    $tokenMatches = [regex]::Matches($Text, $pattern)
    $lastIndex = 0

    foreach ($tokenMatch in $tokenMatches) {
        if ($tokenMatch.Index -gt $lastIndex) {
            $Paragraph.Inlines.Add([System.Windows.Documents.Run]::new($Text.Substring($lastIndex, $tokenMatch.Index - $lastIndex))) | Out-Null
        }

        $token = $tokenMatch.Value
        if ($token.StartsWith('~~') -and $token.EndsWith('~~')) {
            $run = [System.Windows.Documents.Run]::new($token.Substring(2, $token.Length - 4))
            $run.TextDecorations = [System.Windows.TextDecorations]::Strikethrough
            $Paragraph.Inlines.Add($run) | Out-Null
        } elseif (($token.StartsWith('**') -and $token.EndsWith('**')) -or ($token.StartsWith('__') -and $token.EndsWith('__'))) {
            $run = [System.Windows.Documents.Run]::new($token.Substring(2, $token.Length - 4))
            $bold = [System.Windows.Documents.Bold]::new($run)
            $Paragraph.Inlines.Add($bold) | Out-Null
        } elseif (($token.StartsWith('*') -and $token.EndsWith('*')) -or ($token.StartsWith('_') -and $token.EndsWith('_'))) {
            $run = [System.Windows.Documents.Run]::new($token.Substring(1, $token.Length - 2))
            $italic = [System.Windows.Documents.Italic]::new($run)
            $Paragraph.Inlines.Add($italic) | Out-Null
        } elseif ($token.StartsWith('`') -and $token.EndsWith('`')) {
            $run = [System.Windows.Documents.Run]::new($token.Substring(1, $token.Length - 2))
            $run.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
            $run.Background = New-Brush "#191A1B"
            $run.Foreground = $Text_Prim
            $Paragraph.Inlines.Add($run) | Out-Null
        } elseif ($token -match '^\[([^\]]+)\]\(([^)]+)\)$') {
            $linkMatch = [regex]::Match($token, '^\[([^\]]+)\]\(([^)]+)\)$')
            $run = [System.Windows.Documents.Run]::new($linkMatch.Groups[1].Value)
            $run.Foreground = $Accent
            $Paragraph.Inlines.Add($run) | Out-Null
        } elseif ($token -match '^https?://') {
            $run = [System.Windows.Documents.Run]::new($token)
            $run.Foreground = $Accent
            $Paragraph.Inlines.Add($run) | Out-Null
        } else {
            $Paragraph.Inlines.Add([System.Windows.Documents.Run]::new($token)) | Out-Null
        }

        $lastIndex = $tokenMatch.Index + $tokenMatch.Length
    }

    if ($lastIndex -lt $Text.Length) {
        $Paragraph.Inlines.Add([System.Windows.Documents.Run]::new($Text.Substring($lastIndex))) | Out-Null
    }
}

function New-PreviewParagraph {
    param(
        [string]$Text,
        [double]$FontSize = 12,
        [object]$FontWeight = $null,
        [object]$Foreground = $null,
        [string]$Margin = "0,0,0,6",
        [switch]$Code
    )

    $paragraph = [System.Windows.Documents.Paragraph]::new()
    $paragraph.Margin = $Margin
    $paragraph.FontSize = $FontSize
    $paragraph.Foreground = if ($Foreground) { $Foreground } else { $Text_Muted }
    if ($FontWeight) { $paragraph.FontWeight = $FontWeight }
    if ($Code) {
        $paragraph.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
        $paragraph.Background = New-Brush "#0A0A0F"
        $paragraph.Padding = "8"
        $paragraph.BorderBrush = $BorderSubtle
        $paragraph.BorderThickness = "1,1,1,1"
        $paragraph.Inlines.Add([System.Windows.Documents.Run]::new($Text)) | Out-Null
    } else {
        Add-FormattedInlineText -Paragraph $paragraph -Text $Text
    }
    return $paragraph
}

function New-HorizontalRuleBlock {
    $border = [System.Windows.Controls.Border]::new()
    $border.Height = 1
    $border.Margin = "0,10,0,10"
    $border.Background = $BorderSubtle

    $container = [System.Windows.Documents.BlockUIContainer]::new($border)
    $container.Margin = "0"
    return $container
}

function Split-MarkdownTableRow {
    param([string]$Line)

    $trimmed = $Line.Trim()
    if ($trimmed.StartsWith('|')) { $trimmed = $trimmed.Substring(1) }
    if ($trimmed.EndsWith('|')) { $trimmed = $trimmed.Substring(0, $trimmed.Length - 1) }
    return @($trimmed -split '\|' | ForEach-Object { $_.Trim() })
}

function Test-MarkdownTableSeparator {
    param([string]$Line)

    $cells = Split-MarkdownTableRow -Line $Line
    if ($cells.Count -eq 0) { return $false }
    foreach ($cell in $cells) {
        if ($cell -notmatch '^:?-{3,}:?$') {
            return $false
        }
    }
    return $true
}

function New-MarkdownTableBlock {
    param(
        [string[]]$Header,
        [string[][]]$Rows
    )

    $table = [System.Windows.Documents.Table]::new()
    $table.CellSpacing = 0
    $table.Margin = "0,8,0,10"
    $table.BorderBrush = $BorderSubtle
    $table.BorderThickness = "1,1,1,1"

    for ($i = 0; $i -lt $Header.Count; $i++) {
        $column = [System.Windows.Documents.TableColumn]::new()
        $column.Width = [System.Windows.GridLength]::Auto
        $table.Columns.Add($column) | Out-Null
    }

    $group = [System.Windows.Documents.TableRowGroup]::new()
    $table.RowGroups.Add($group) | Out-Null

    $headerRow = [System.Windows.Documents.TableRow]::new()
    $headerRow.Background = New-Brush "#0A0A0F"
    foreach ($headerCell in $Header) {
        $paragraph = New-PreviewParagraph -Text $headerCell -FontWeight "Bold" -Foreground $Text_Prim -Margin "0"
        $cell = [System.Windows.Documents.TableCell]::new($paragraph)
        $cell.Padding = "8,6,8,6"
        $cell.BorderBrush = $BorderSubtle
        $cell.BorderThickness = "0,0,1,1"
        $headerRow.Cells.Add($cell) | Out-Null
    }
    $group.Rows.Add($headerRow) | Out-Null

    foreach ($row in $Rows) {
        $tableRow = [System.Windows.Documents.TableRow]::new()
        for ($i = 0; $i -lt $Header.Count; $i++) {
            $value = if ($i -lt $row.Count) { $row[$i] } else { "" }
            $paragraph = New-PreviewParagraph -Text $value -Margin "0"
            $cell = [System.Windows.Documents.TableCell]::new($paragraph)
            $cell.Padding = "8,6,8,6"
            $cell.BorderBrush = $BorderSubtle
            $cell.BorderThickness = "0,0,1,1"
            $tableRow.Cells.Add($cell) | Out-Null
        }
        $group.Rows.Add($tableRow) | Out-Null
    }

    return $table
}

function New-FormattedPreviewDocument {
    param(
        [string]$Content,
        [string]$Extension
    )

    $source = if ($Extension -in @(".html", ".htm")) {
        Convert-HtmlToPreviewMarkup -Html $Content
    } elseif ($Extension -eq ".md") {
        Convert-MarkdownToPreviewMarkup -Markdown $Content
    } else {
        $Content
    }
    $document = [System.Windows.Documents.FlowDocument]::new()
    $document.PagePadding = "0"
    $document.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $document.Foreground = $Text_Muted
    $document.Background = New-Brush "#0F1011"

    $lines = @($source -split "`r?`n")
    $inCodeBlock = $false
    $codeLines = [System.Collections.Generic.List[string]]::new()

    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $rawLine = $lines[$lineIndex]
        $line = $rawLine.TrimEnd()

        if ($line.Trim().StartsWith('```')) {
            if ($inCodeBlock) {
                $document.Blocks.Add((New-PreviewParagraph -Text ($codeLines -join [Environment]::NewLine) -Code -Margin "0,4,0,8")) | Out-Null
                $codeLines.Clear()
                $inCodeBlock = $false
            } else {
                $inCodeBlock = $true
            }
            continue
        }

        if ($inCodeBlock) {
            $codeLines.Add($line) | Out-Null
            continue
        }

        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            $document.Blocks.Add((New-PreviewParagraph -Text " " -Margin "0,0,0,4")) | Out-Null
            continue
        }

        if ($trimmed -match '^\|.*\|$' -and ($lineIndex + 1) -lt $lines.Count -and (Test-MarkdownTableSeparator -Line $lines[$lineIndex + 1])) {
            $header = Split-MarkdownTableRow -Line $trimmed
            $rows = @()
            $lineIndex += 2
            while ($lineIndex -lt $lines.Count -and $lines[$lineIndex].Trim() -match '^\|.*\|$') {
                $rows += ,(Split-MarkdownTableRow -Line $lines[$lineIndex])
                $lineIndex++
            }
            $lineIndex--
            $document.Blocks.Add((New-MarkdownTableBlock -Header $header -Rows $rows)) | Out-Null
            continue
        }

        if ($trimmed -match '^(#{1,6})\s+(.+)$') {
            $level = $Matches[1].Length
            $title = $Matches[2]
            $size = switch ($level) { 1 { 21 } 2 { 18 } 3 { 16 } 4 { 14 } 5 { 13 } default { 12.5 } }
            $margin = if ($level -le 2) { "0,12,0,8" } else { "0,8,0,6" }
            $document.Blocks.Add((New-PreviewParagraph -Text $title -FontSize $size -FontWeight "Bold" -Foreground $Text_Prim -Margin $margin)) | Out-Null
            if ($level -le 2) {
                $document.Blocks.Add((New-HorizontalRuleBlock)) | Out-Null
            }
            continue
        }

        if ($trimmed -match '^(-{3,}|\*{3,}|_{3,})$') {
            $document.Blocks.Add((New-HorizontalRuleBlock)) | Out-Null
            continue
        }

        if ($trimmed -match '^[-+*]\s+\[(x|X| )\]\s+(.+)$') {
            $state = if ($Matches[1].Trim().Length -gt 0) { "[x]" } else { "[ ]" }
            $document.Blocks.Add((New-PreviewParagraph -Text ("$state " + $Matches[2]) -Margin "12,0,0,4")) | Out-Null
            continue
        }

        if ($trimmed -match '^[-+*]\s+(.+)$') {
            $document.Blocks.Add((New-PreviewParagraph -Text ("- " + $Matches[1]) -Margin "12,0,0,4")) | Out-Null
            continue
        }

        if ($trimmed -match '^\d+\.\s+(.+)$') {
            $document.Blocks.Add((New-PreviewParagraph -Text $trimmed -Margin "12,0,0,4")) | Out-Null
            continue
        }

        if ($trimmed -match '^>\s?(.+)$') {
            $document.Blocks.Add((New-PreviewParagraph -Text ("| " + $Matches[1]) -Foreground $Text_Dim -Margin "10,0,0,6")) | Out-Null
            continue
        }

        $document.Blocks.Add((New-PreviewParagraph -Text $trimmed -Margin "0,0,0,6")) | Out-Null
    }

    if ($inCodeBlock -and $codeLines.Count -gt 0) {
        $document.Blocks.Add((New-PreviewParagraph -Text ($codeLines -join [Environment]::NewLine) -Code -Margin "0,4,0,8")) | Out-Null
    }

    return $document
}

function New-TextPreviewCard {
    param($File)

    $card = [System.Windows.Controls.Border]::new()
    $card.Background = $BG_Surface
    $card.BorderBrush = $BorderStd
    $card.BorderThickness = "1,1,1,1"
    $card.CornerRadius = "8"
    $card.Padding = "14,12,14,12"
    $card.Margin = "0,0,0,8"

    $panel = [System.Windows.Controls.StackPanel]::new()

    $titleBlock = [System.Windows.Controls.TextBlock]::new()
    $titleBlock.Text = $File.Name
    $titleBlock.FontSize = 13
    $titleBlock.FontWeight = "SemiBold"
    $titleBlock.Foreground = $Text_Prim
    $panel.Children.Add($titleBlock) | Out-Null

    $descBlock = [System.Windows.Controls.TextBlock]::new()
    $descBlock.Text = switch ($File.Extension.ToLowerInvariant()) {
        ".md" { "Preview formatado de Markdown" }
        ".html" { "Preview formatado de HTML" }
        ".htm" { "Preview formatado de HTML" }
        default { "Preview de documento de texto" }
    }
    $descBlock.FontSize = 10.5
    $descBlock.Foreground = $Text_Muted
    $descBlock.Margin = "0,0,0,8"
    $panel.Children.Add($descBlock) | Out-Null

    $previewBox = [System.Windows.Controls.RichTextBox]::new()
    $previewBox.Document = New-FormattedPreviewDocument -Content (Read-TextPreview -FilePath $File.FullName) -Extension $File.Extension.ToLowerInvariant()
    $previewBox.Background = New-Brush "#0F1011"
    $previewBox.BorderBrush = $BorderSubtle
    $previewBox.BorderThickness = "1,1,1,1"
    $previewBox.Padding = "8"
    $previewBox.Height = 190
    $previewBox.IsReadOnly = $true
    $previewBox.VerticalScrollBarVisibility = "Auto"
    $previewBox.HorizontalScrollBarVisibility = "Disabled"
    $panel.Children.Add($previewBox) | Out-Null

    $card.Child = $panel
    return $card
}

function New-OpenDocumentCard {
    param($File)

    $description = switch ($File.Extension.ToLowerInvariant()) {
        ".pdf" { "Documento PDF - abrir no aplicativo padrao" }
        ".doc" { "Documento Word - abrir no aplicativo padrao" }
        ".docx" { "Documento Word - abrir no aplicativo padrao" }
        default { "Documento - abrir no aplicativo padrao" }
    }

    $card = New-FolderCard -Title $File.Name -Description $description -Clickable $true
    $card.Tag = New-DocumentTag -Name $File.Name -FilePath $File.FullName -Extension $File.Extension.ToLowerInvariant()
    $card.ToolTip = $File.FullName
    $card.Add_MouseLeftButtonUp({ param($sender, $eventArgs) Open-DocumentFromSender -Sender $sender })
    return $card
}

function New-ToggleCard {
    param(
        [string]$Title,
        [string]$Description,
        [bool]$Checked
    )

    $card = [System.Windows.Controls.Border]::new()
    $card.Background = $BG_Surface
    $card.BorderBrush = $BorderStd
    $card.BorderThickness = "1,1,1,1"
    $card.CornerRadius = "8"
    $card.Padding = "14,12,14,12"
    $card.Margin = "0,0,0,6"
    $card.Cursor = [System.Windows.Input.Cursors]::Hand

    $grid = [System.Windows.Controls.Grid]::new()
    $grid.ColumnDefinitions.Add([System.Windows.Controls.ColumnDefinition]::new()) | Out-Null
    $grid.ColumnDefinitions[0].Width = "36"
    $grid.ColumnDefinitions.Add([System.Windows.Controls.ColumnDefinition]::new()) | Out-Null
    $grid.ColumnDefinitions[1].Width = "*"
    $grid.ColumnDefinitions.Add([System.Windows.Controls.ColumnDefinition]::new()) | Out-Null
    $grid.ColumnDefinitions[2].Width = "50"

    $icon = [System.Windows.Controls.TextBlock]::new()
    $icon.Text = "[]"
    $icon.FontSize = 18
    $icon.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $icon.Foreground = if ($Checked) { $Accent } else { $Text_Dim }
    $icon.VerticalAlignment = "Center"
    $icon.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($icon, 0)

    $textPanel = [System.Windows.Controls.StackPanel]::new()
    $textPanel.VerticalAlignment = "Center"
    $textPanel.Margin = "8,0,0,0"
    [System.Windows.Controls.Grid]::SetColumn($textPanel, 1)

    $titleBlock = [System.Windows.Controls.TextBlock]::new()
    $titleBlock.Text = $Title
    $titleBlock.FontSize = 13
    $titleBlock.FontWeight = "SemiBold"
    $titleBlock.Foreground = $Text_Prim
    $textPanel.Children.Add($titleBlock) | Out-Null

    $descBlock = [System.Windows.Controls.TextBlock]::new()
    $descBlock.Text = $Description
    $descBlock.FontSize = 10.5
    $descBlock.Foreground = $Text_Muted
    $descBlock.TextWrapping = "Wrap"
    $textPanel.Children.Add($descBlock) | Out-Null

    $toggle = [System.Windows.Controls.CheckBox]::new()
    $toggle.IsChecked = $Checked
    $toggle.VerticalAlignment = "Center"
    $toggle.HorizontalAlignment = "Center"
    $toggleStyle = Get-StyleOrNull -Key "CardToggle"
    if ($toggleStyle) { $toggle.Style = $toggleStyle }
    [System.Windows.Controls.Grid]::SetColumn($toggle, 2)

    $grid.Children.Add($icon) | Out-Null
    $grid.Children.Add($textPanel) | Out-Null
    $grid.Children.Add($toggle) | Out-Null
    $card.Child = $grid

    $accentBrush = $Accent
    $dimBrush = $Text_Dim
    $toggle.Add_Checked({ $icon.Foreground = $accentBrush }.GetNewClosure())
    $toggle.Add_Unchecked({ $icon.Foreground = $dimBrush }.GetNewClosure())
    $card.Add_MouseLeftButtonUp({
        $toggle.IsChecked = -not [bool]$toggle.IsChecked
    }.GetNewClosure())

    return @{
        Card = $card
        Toggle = $toggle
    }
}

# ============ DISCOVER FILES ============
function Get-ScriptCategories {
    $categories = [System.Collections.Generic.List[object]]::new()

    if (-not (Test-Path -LiteralPath $ScriptsPath)) {
        return @()
    }

    $folders = Get-ChildItem -LiteralPath $ScriptsPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name

    foreach ($folder in $folders) {
        $items = [System.Collections.Generic.List[object]]::new()
        $childItems = @(Get-ChildItem -LiteralPath $folder.FullName -Force -ErrorAction SilentlyContinue)
        $documentItems = @($childItems | Where-Object {
            -not $_.PSIsContainer -and $Script:DocumentExtensions.Contains($_.Extension.ToLowerInvariant())
        })
        $files = Get-ChildItem -LiteralPath $folder.FullName -File -ErrorAction SilentlyContinue |
            Where-Object { $Script:ScriptExtensions.Contains($_.Extension.ToLowerInvariant()) } |
            Sort-Object Name

        foreach ($file in $files) {
            $items.Add([pscustomobject]@{
                Name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                FileName = $file.Name
                FilePath = $file.FullName
                Extension = $file.Extension.ToLowerInvariant()
            }) | Out-Null
        }

        $categories.Add([pscustomobject]@{
            Name = $folder.Name
            Folder = $folder.FullName
            ItemCount = $childItems.Count
            DocumentCount = $documentItems.Count
            Scripts = $items.ToArray()
        }) | Out-Null
    }

    return $categories.ToArray()
}

function Get-ScriptFilesInFolder {
    param([string]$FolderPath)

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $FolderPath -File -ErrorAction SilentlyContinue |
        Where-Object { $Script:ScriptExtensions.Contains($_.Extension.ToLowerInvariant()) } |
        Sort-Object Name)
}

function Get-DocumentFilesInFolder {
    param([string]$FolderPath)

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $FolderPath -File -ErrorAction SilentlyContinue |
        Where-Object { $Script:DocumentExtensions.Contains($_.Extension.ToLowerInvariant()) } |
        Sort-Object Name)
}

function Get-FolderChildren {
    param([string]$FolderPath)

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $FolderPath -Force -ErrorAction SilentlyContinue |
        Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name)
}

# ============ BUILD VIEWS ============
function Build-DashboardView {
    Clear-View
    Set-ViewTitle -Text "Dashboard"
    Set-ViewSubtitle -Text "Pastas em scripts"
    $Script:CurrentView = "dashboard"
    $Script:ViewData = @{}

    if (-not $E.ViewPanel) { return }

    $E.ViewPanel.Children.Add((New-SectionHeader -Text "Pastas em scripts")) | Out-Null
    $categories = Get-ScriptCategories

    if ($categories.Count -eq 0) {
        $E.ViewPanel.Children.Add((New-InfoText -Text "Nenhuma pasta encontrada em scripts.")) | Out-Null
        Add-LogUI -Message "Dashboard carregado sem pastas" -Level "WARN"
        return
    }

    foreach ($category in $categories) {
        $categoryName = [string]$category.Name
        $folderPath = [string]$category.Folder
        $scriptCount = [int]$category.Scripts.Count
        $documentCount = [int]$category.DocumentCount
        $itemCount = [int]$category.ItemCount
        $card = New-FolderCard -Title $categoryName -Description "$scriptCount script(s), $documentCount documento(s), $itemCount item(ns)"
        $card.Tag = New-CategoryTag -Name $categoryName -Folder $folderPath
        $card.ToolTip = $folderPath
        $card.Add_MouseLeftButtonUp({ param($sender, $eventArgs) Open-CategoryFromSender -Sender $sender })
        $E.ViewPanel.Children.Add($card) | Out-Null
    }

    Add-LogUI -Message "Dashboard carregado ($($categories.Count) pasta(s))" -Level "OK"
}

function Build-CategoryView {
    param(
        [string]$CategoryName,
        [string]$FolderPath
    )

    Clear-View
    Set-ViewTitle -Text $CategoryName
    Set-ViewSubtitle -Text $FolderPath
    $Script:CurrentView = $CategoryName
    $Script:ViewData = @{}

    if (-not $E.ViewPanel) { return }

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        $E.ViewPanel.Children.Add((New-InfoText -Text "Pasta nao encontrada: $FolderPath")) | Out-Null
        Add-LogUI -Message "Pasta nao encontrada: $FolderPath" -Level "WARN"
        return
    }

    $allFiles = Get-ScriptFilesInFolder -FolderPath $FolderPath
    $documentFiles = Get-DocumentFilesInFolder -FolderPath $FolderPath
    $folderChildren = Get-FolderChildren -FolderPath $FolderPath

    if ($folderChildren.Count -eq 0) {
        $E.ViewPanel.Children.Add((New-SectionHeader -Text "Conteudo da pasta")) | Out-Null
        $E.ViewPanel.Children.Add((New-InfoText -Text "Pasta vazia: nenhum item encontrado.")) | Out-Null
        Add-LogUI -Message "Categoria '$CategoryName' vazia" -Level "WARN"
        return
    }

    $E.ViewPanel.Children.Add((New-SectionHeader -Text "Scripts executaveis")) | Out-Null

    if ($allFiles.Count -eq 0) {
        $E.ViewPanel.Children.Add((New-InfoText -Text "Nenhum script executavel encontrado nesta pasta.")) | Out-Null
    } else {
        foreach ($scriptFile in $allFiles) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($scriptFile.Name)
            $extension = $scriptFile.Extension.ToLowerInvariant()
            $description = switch ($extension) {
                ".ps1" { "PowerShell Script" }
                ".bat" { "Batch Script" }
                ".cmd" { "Command Script" }
                ".vbs" { "VBScript" }
                default { "Script" }
            }
            $safeKey = ($CategoryName + "_" + $baseName) -replace '[^a-zA-Z0-9_]', '_'
            $card = New-ToggleCard -Title $baseName -Description $description -Checked $true
            $E.ViewPanel.Children.Add($card.Card) | Out-Null
            Register-Card -Key $safeKey -Toggle $card.Toggle -Action "Script" -FilePath $scriptFile.FullName -Category $CategoryName
        }
    }

    if ($documentFiles.Count -gt 0) {
        $E.ViewPanel.Children.Add((New-SectionHeader -Text "Documentos")) | Out-Null
        foreach ($documentFile in $documentFiles) {
            $extension = $documentFile.Extension.ToLowerInvariant()
            if ($Script:TextDocumentExtensions.Contains($extension)) {
                $E.ViewPanel.Children.Add((New-TextPreviewCard -File $documentFile)) | Out-Null
            } else {
                $E.ViewPanel.Children.Add((New-OpenDocumentCard -File $documentFile)) | Out-Null
            }
        }
    }

    $otherItems = @($folderChildren | Where-Object {
        $_.PSIsContainer -or (
            -not $Script:ScriptExtensions.Contains($_.Extension.ToLowerInvariant()) -and
            -not $Script:DocumentExtensions.Contains($_.Extension.ToLowerInvariant())
        )
    })
    if ($otherItems.Count -gt 0) {
        $E.ViewPanel.Children.Add((New-SectionHeader -Text "Outros itens")) | Out-Null
        foreach ($child in $otherItems) {
            $kind = if ($child.PSIsContainer) { "Pasta" } else { "Arquivo nao suportado" }
            $card = New-FolderCard -Title $child.Name -Description $kind -Clickable $false
            $card.ToolTip = $child.FullName
            $E.ViewPanel.Children.Add($card) | Out-Null
        }
    }

    Add-LogUI -Message "Categoria '$CategoryName' carregada ($($allFiles.Count) script(s), $($documentFiles.Count) documento(s), $($folderChildren.Count) item(ns))" -Level "OK"
}

function Build-Navigation {
    if (-not $E.NavPanel) { return }

    $categories = Get-ScriptCategories
    $E.NavPanel.Children.Clear()

    $sideStyle = Get-StyleOrNull -Key "SideBtnStyle"

    $dashBtn = [System.Windows.Controls.Button]::new()
    $dashBtn.Content = "  Dashboard"
    if ($sideStyle) { $dashBtn.Style = $sideStyle }
    $dashBtn.Add_Click({
        $Script:ViewData = @{}
        Build-DashboardView
    })
    $E.NavPanel.Children.Add($dashBtn) | Out-Null

    $separator = [System.Windows.Controls.Border]::new()
    $separator.Height = 1
    $separator.Background = $BorderSubtle
    $separator.Margin = "6,8"
    $E.NavPanel.Children.Add($separator) | Out-Null

    foreach ($category in $categories) {
        $categoryName = [string]$category.Name
        $folderPath = [string]$category.Folder

        $btn = [System.Windows.Controls.Button]::new()
        $btn.Content = ("  " + $categoryName)
        $btn.Tag = New-CategoryTag -Name $categoryName -Folder $folderPath
        $btn.ToolTip = $folderPath
        if ($sideStyle) { $btn.Style = $sideStyle }
        $btn.Add_Click({
            param($sender, $eventArgs)
            $Script:ViewData = @{}
            Open-CategoryFromSender -Sender $sender
        })
        $E.NavPanel.Children.Add($btn) | Out-Null
    }

    Write-Log -Message "Navegacao: $($categories.Count) categoria(s)" -Level "INFO"
}

# ============ EXECUTION ============
function Open-DocumentFile {
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath)) {
        Add-LogUI -Message "Documento nao encontrado: $FilePath" -Level "WARN"
        return $false
    }

    $fileName = Split-Path -Path $FilePath -Leaf
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    if (-not $Script:OpenDocumentExtensions.Contains($extension)) {
        Add-LogUI -Message "Documento sem abertura automatica: $fileName" -Level "WARN"
        return $false
    }

    if ($SmokeTest) {
        Add-LogUI -Message "Abrindo documento: $fileName (smoke test)" -Level "INFO"
        return $true
    }

    try {
        Start-Process -FilePath $FilePath -ErrorAction Stop | Out-Null
        Add-LogUI -Message "Abrindo documento: $fileName" -Level "INFO"
        return $true
    } catch {
        Add-LogUI -Message "ERRO ao abrir documento: $fileName - $($_.Exception.Message)" -Level "ERR"
        return $false
    }
}

function Invoke-ScriptEntry {
    param($Entry)

    $filePath = [string]$Entry.FilePath
    if (-not (Test-Path -LiteralPath $filePath)) {
        Add-LogUI -Message "Nao encontrado: $filePath" -Level "WARN"
        return $false
    }

    $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
    $fileName = Split-Path -Path $filePath -Leaf
    Add-LogUI -Message "Executando: $fileName" -Level "INFO"

    if ($SmokeTest) {
        Add-LogUI -Message "OK: $fileName (smoke test)" -Level "OK"
        return $true
    }

    try {
        $process = $null
        switch ($extension) {
            ".ps1" {
                $process = Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ('"' + $filePath + '"')) -Wait -PassThru -NoNewWindow
            }
            ".bat" {
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", ('"' + $filePath + '"')) -Wait -PassThru -NoNewWindow
            }
            ".cmd" {
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", ('"' + $filePath + '"')) -Wait -PassThru -NoNewWindow
            }
            ".vbs" {
                $process = Start-Process -FilePath "cscript.exe" -ArgumentList @("//Nologo", ('"' + $filePath + '"')) -Wait -PassThru -NoNewWindow
            }
            default {
                Add-LogUI -Message "Extensao ignorada: $fileName" -Level "WARN"
                return $false
            }
        }

        if ($process -and $process.ExitCode -eq 0) {
            Add-LogUI -Message "OK: $fileName" -Level "OK"
            return $true
        }

        Add-LogUI -Message "FALHA: $fileName" -Level "ERR"
        return $false
    } catch {
        Add-LogUI -Message "ERRO: $fileName - $($_.Exception.Message)" -Level "ERR"
        return $false
    }
}

function Invoke-SelectedScripts {
    $selected = @($Script:ViewData.GetEnumerator() | Where-Object { $_.Value.Action -eq "Script" -and $_.Value.Toggle.IsChecked })
    $total = $selected.Count

    if ($total -eq 0) {
        [System.Windows.MessageBox]::Show("Nenhuma opcao selecionada.", "Aviso", "OK", "Warning") | Out-Null
        return
    }

    Add-LogUI -Message "Aplicando $total item(ns)..." -Level "INFO"
    $done = 0
    foreach ($entry in $selected) {
        $done++
        $percent = [Math]::Round(($done / $total) * 100)
        if ($E.ProgressBar) { $E.ProgressBar.Value = $percent }
        if ($E.ProgressText) { $E.ProgressText.Text = "$done / $total ($percent%)" }
        Invoke-ScriptEntry -Entry $entry.Value | Out-Null
    }

    if ($E.ProgressBar) { $E.ProgressBar.Value = 100 }
    if ($E.ProgressText) { $E.ProgressText.Text = "Concluido!" }
    Add-LogUI -Message "Finalizado! $done item(ns)." -Level "OK"
}

function Invoke-AllScripts {
    $categories = Get-ScriptCategories
    $entries = [System.Collections.Generic.List[object]]::new()

    foreach ($category in $categories) {
        foreach ($script in $category.Scripts) {
            $entries.Add($script) | Out-Null
        }
    }

    if ($entries.Count -eq 0) {
        Add-LogUI -Message "Nenhum script encontrado para executar." -Level "WARN"
        return
    }

    Add-LogUI -Message "=== EXECUTAR TUDO ===" -Level "INFO"
    $done = 0
    foreach ($entry in $entries) {
        $done++
        $percent = [Math]::Round(($done / $entries.Count) * 100)
        if ($E.ProgressBar) { $E.ProgressBar.Value = $percent }
        if ($E.ProgressText) { $E.ProgressText.Text = "$done / $($entries.Count) ($percent%)" }
        Invoke-ScriptEntry -Entry $entry | Out-Null
    }

    Add-LogUI -Message "Execucao completa" -Level "OK"
}

# ============ EVENTS ============
if ($E.btnApplyView) { $E.btnApplyView.Add_Click({ Invoke-SelectedScripts }) }
if ($E.btnUndoView) { $E.btnUndoView.Add_Click({ Add-LogUI -Message "Reverter nao possui acao configurada nesta versao." -Level "WARN" }) }
if ($E.btnRunAll) {
    $E.btnRunAll.Add_Click({
        Invoke-AllScripts
        if ($CloseWhenDone) { $window.Close() }
    })
}
if ($E.btnSelectAll) {
    $E.btnSelectAll.Add_Click({
        foreach ($key in @($Script:ViewData.Keys)) {
            $Script:ViewData[$key].Toggle.IsChecked = $true
        }
        Add-LogUI -Message "Todos selecionados" -Level "INFO"
    })
}
if ($E.btnDeselectAll) {
    $E.btnDeselectAll.Add_Click({
        foreach ($key in @($Script:ViewData.Keys)) {
            $Script:ViewData[$key].Toggle.IsChecked = $false
        }
        Add-LogUI -Message "Todos desmarcados" -Level "INFO"
    })
}
if ($E.btnClearLog) { $E.btnClearLog.Add_Click({ if ($E.LogList) { $E.LogList.Items.Clear() } }) }
if ($E.btnClose) { $E.btnClose.Add_Click({ $window.Close() }) }
if ($E.btnMinimize) { $E.btnMinimize.Add_Click({ $window.WindowState = "Minimized" }) }
if ($E.TopBar) {
    $E.TopBar.Add_MouseLeftButtonDown({
        try { $window.DragMove() } catch {}
    })
}

# ============ SMOKE CHECKS ============
function Test-ContainsControlType {
    param(
        $Root,
        [type]$ControlType
    )

    if ($Root -is $ControlType) {
        return $true
    }

    if ($Root -is [System.Windows.Controls.Panel]) {
        foreach ($child in $Root.Children) {
            if (Test-ContainsControlType -Root $child -ControlType $ControlType) {
                return $true
            }
        }
    }

    if ($Root -is [System.Windows.Controls.ContentControl] -and $Root.Content) {
        if (Test-ContainsControlType -Root $Root.Content -ControlType $ControlType) {
            return $true
        }
    }

    if ($Root -is [System.Windows.Controls.Decorator] -and $Root.Child) {
        if (Test-ContainsControlType -Root $Root.Child -ControlType $ControlType) {
            return $true
        }
    }

    return $false
}

function Invoke-SmokeChecks {
    $requiredControls = @('NavPanel', 'ViewPanel', 'ViewTitle', 'ViewSubtitle', 'btnApplyView')
    foreach ($controlName in $requiredControls) {
        if (-not $E[$controlName]) {
            throw "Controle obrigatorio nao encontrado no XAML: $controlName"
        }
    }

    $markdownPreviewContent = @'
# Preview
<div align="center">
[![Status dos Testes](https://img.shields.io/badge/tests-ok-brightgreen)](https://github.com)
C:\ProgramData\InstTotem\<timestamp>
</div>
'@
    $markdownPreview = New-FormattedPreviewDocument -Content $markdownPreviewContent -Extension ".md"
    $markdownRange = [System.Windows.Documents.TextRange]::new($markdownPreview.ContentStart, $markdownPreview.ContentEnd)
    $markdownText = $markdownRange.Text
    if ($markdownText -match '<div' -or $markdownText -match '!\[' -or $markdownText -match 'img\.shields\.io') {
        throw "Falha no preview Markdown: HTML ou badge bruto apareceu no painel."
    }
    if ($markdownText -notmatch '<timestamp>') {
        throw "Falha no preview Markdown: placeholder com sinal de menor/maior foi removido."
    }

    Build-Navigation
    Build-DashboardView

    $navButtons = @($E.NavPanel.Children | Where-Object { $_ -is [System.Windows.Controls.Button] })
    foreach ($button in $navButtons) {
        $buttonText = ([string]$button.Content).Trim()
        if ($buttonText -eq "Dashboard") { continue }

        $button.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
        if ($E.ViewTitle.Text -ne $buttonText) {
            throw "Falha no clique da sidebar: esperado '$buttonText', recebido '$($E.ViewTitle.Text)'"
        }
        if (-not $button.Tag -or $E.ViewSubtitle.Text -ne [string]$button.Tag.Folder) {
            throw "Falha no caminho da sidebar para '$buttonText'."
        }
        if ($E.ViewPanel.Children.Count -eq 0) {
            throw "Falha no conteudo da sidebar para '$buttonText': painel vazio."
        }
    }

    foreach ($category in (Get-ScriptCategories)) {
        Build-CategoryView -CategoryName $category.Name -FolderPath $category.Folder
        $scriptFiles = Get-ScriptFilesInFolder -FolderPath $category.Folder
        $documentFiles = Get-DocumentFilesInFolder -FolderPath $category.Folder
        if ($Script:ViewData.Count -ne $scriptFiles.Count) {
            throw "Falha na selecao de '$($category.Name)': esperado $($scriptFiles.Count) script(s), recebido $($Script:ViewData.Count)."
        }

        $textDocs = @($documentFiles | Where-Object { $Script:TextDocumentExtensions.Contains($_.Extension.ToLowerInvariant()) })
        if ($textDocs.Count -gt 0 -and -not (Test-ContainsControlType -Root $E.ViewPanel -ControlType ([System.Windows.Controls.RichTextBox]))) {
            throw "Falha no preview de documento de texto em '$($category.Name)'."
        }

        $openDocs = @($documentFiles | Where-Object { $Script:OpenDocumentExtensions.Contains($_.Extension.ToLowerInvariant()) })
        foreach ($document in $openDocs) {
            if (-not (Open-DocumentFile -FilePath $document.FullName)) {
                throw "Falha no card de abertura de documento em '$($category.Name)': $($document.Name)."
            }
        }
    }

    Build-DashboardView
}

# ============ SHOW ============
try {
    if ($SmokeTest) {
        Invoke-SmokeChecks
    } else {
        Build-Navigation
        Build-DashboardView
    }

    Add-LogUI -Message "Interface carregada!" -Level "OK"

    if ($AutoRunAll) {
        Invoke-AllScripts
        if ($CloseWhenDone) {
            if ($SmokeTest) { Write-Output "SmokeTest OK" }
            return
        }
    }

    if ($SmokeTest) {
        $delaySeconds = if ($SmokeTestHoldSeconds -gt 0) { $SmokeTestHoldSeconds } else { 1 }
        $Script:SmokeTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $Script:SmokeTimer.Interval = [TimeSpan]::FromSeconds($delaySeconds)
        $Script:SmokeTimer.Add_Tick({
            $Script:SmokeTimer.Stop()
            $window.Close()
        })
        $Script:SmokeTimer.Start()
    }

    $window.ShowDialog() | Out-Null
    if ($SmokeTest) { Write-Output "SmokeTest OK" }
} catch {
    Add-LogUI -Message ("ERRO FATAL: " + $_.Exception.Message) -Level "ERR"
    if ($SmokeTest) {
        Write-Error $_.Exception.Message
        exit 1
    }
}
