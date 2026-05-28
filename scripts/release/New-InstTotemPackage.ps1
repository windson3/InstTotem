[CmdletBinding()]
param(
    [string]$OutputDir = "",
    [string]$PackageName = "InstTotem-package.zip",
    [switch]$IncludeUiXaml
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[Package] $Message" -ForegroundColor Cyan
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $projectRoot "dist"
}
$OutputDir = (Resolve-Path -LiteralPath (New-Item -Path $OutputDir -ItemType Directory -Force).FullName).Path

$stageDir = Join-Path $env:TEMP ("InstTotem-stage-" + [guid]::NewGuid().ToString("N"))
New-Item -Path $stageDir -ItemType Directory -Force | Out-Null

try {
    $requiredItems = @(
        "TotemAutomacao.ps1",
        "README.md",
        "assets\images",
        "assets\installers",
        "scripts\launcher.vbs"
    )

    if ($IncludeUiXaml) {
        $requiredItems += "ui\TotemGUI.xaml"
    }

    foreach ($relativePath in $requiredItems) {
        $sourcePath = Join-Path $projectRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Item obrigatorio nao encontrado: $sourcePath"
        }

        $targetPath = Join-Path $stageDir $relativePath
        $targetParent = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $targetParent)) {
            New-Item -Path $targetParent -ItemType Directory -Force | Out-Null
        }

        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Recurse -Force
    }

    $zipPath = Join-Path $OutputDir $PackageName
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }

    Write-Step "Gerando pacote ZIP: $zipPath"
    Compress-Archive -Path (Join-Path $stageDir "*") -DestinationPath $zipPath -Force

    $sha = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToUpperInvariant()
    $shaFileName = [IO.Path]::GetFileNameWithoutExtension($PackageName) + ".sha256"
    $shaFilePath = Join-Path $OutputDir $shaFileName
    $shaLine = "$sha  $PackageName"
    Set-Content -LiteralPath $shaFilePath -Value $shaLine -Encoding ASCII

    Write-Step "Pacote criado com sucesso."
    Write-Host "ZIP: $zipPath"
    Write-Host "SHA: $shaFilePath"
} finally {
    if (Test-Path -LiteralPath $stageDir) {
        Remove-Item -LiteralPath $stageDir -Recurse -Force
    }
}
