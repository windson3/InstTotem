Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$basePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = (Resolve-Path (Join-Path $basePath "..\\..")).Path
$xamlPath = Join-Path $projectPath "ui\\TotemGUI.xaml"

if (-not (Test-Path $xamlPath)) {
    Write-Host "ERRO: XAML nao encontrado em $xamlPath" -ForegroundColor Red
    [System.Windows.MessageBox]::Show("XAML nao encontrado", "Erro")
    exit
}

[xml]$xaml = Get-Content $xamlPath -Encoding UTF8
Write-Host "XAML parsed OK"

$reader = New-Object System.Xml.XmlNodeReader $xaml
$win = [Windows.Markup.XamlReader]::Load($reader)
Write-Host "Window loaded. Title: $($win.Title)"

$names = @("tabInstall","tabTweaks","tabConfig","panelInstall","btnClose","chk_powershell7","chk_chrome","btnApplyTweaks","btnPresetMinimal")
foreach ($n in $names) {
    $el = $win.FindName($n)
    Write-Host "  $n : $(if($el){'OK'}else{'NOT FOUND'})"
}

$win.Close()
Write-Host "ALL OK"
