Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$basePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = (Resolve-Path (Join-Path $basePath "..")).Path
$xamlPath = Join-Path $projectPath "ui\\TotemUI.xaml"

if (-not (Test-Path $xamlPath)) {
    Write-Host "ERRO: XAML nao encontrado em $xamlPath" -ForegroundColor Red
    [System.Windows.MessageBox]::Show("XAML nao encontrado", "Erro")
    exit
}

$logoPath = Join-Path $projectPath "assets\\images\\Log-transparent.png"
if (-not (Test-Path -LiteralPath $logoPath)) {
    $logoPath = Join-Path $projectPath "assets\\images\\Log.png"
}

$xamlText = [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8)
$xamlText = $xamlText.Replace('__LOGO__', $logoPath)
$xmlCheck = [xml]$xamlText
Write-Host "XAML parsed OK"

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlText))
try {
    $win = [Windows.Markup.XamlReader]::Load($reader)
} finally {
    $reader.Close()
}
Write-Host "Window loaded. Title: $($win.Title)"

$names = @(
    "btnClose", "btnMinimize", "TopBar", "TopLogo",
    "NavPanel", "ViewTitle", "ViewSubtitle", "ViewPanel",
    "btnRunAll", "btnApplyView", "btnUndoView", "btnSelectAll", "btnDeselectAll",
    "ProgressBar", "ProgressText", "LogList", "btnClearLog",
    "SysCpuName", "SysCpuBar", "SysCpuText",
    "SysRamValue", "SysRamBar", "SysRamText",
    "SysDiskValue", "SysDiskBar", "SysDiskText"
)
$missing = @()
foreach ($n in $names) {
    $el = $win.FindName($n)
    if ($el) {
        Write-Host "  $n : OK"
    } else {
        Write-Host "  $n : NOT FOUND" -ForegroundColor Red
        $missing += $n
    }
}

$win.Close()
if ($missing.Count -gt 0) {
    throw "Controles nao encontrados: $($missing -join ', ')"
}
Write-Host "ALL OK"
