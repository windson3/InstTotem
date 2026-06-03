[CmdletBinding()]
param(
    [string]$OutputDir = "",
    [string]$PackageName = "InstTotem-package.zip"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[Package] $Message" -ForegroundColor Cyan
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptRoot "..")).Path

function Copy-PackageItem {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$StageDir
    )

    $hasWildcard = $RelativePath.IndexOfAny([char[]]"*?") -ge 0
    if ($hasWildcard) {
        $searchPath = Join-Path $projectRoot $RelativePath
        $matches = @(Get-ChildItem -Path $searchPath -File -ErrorAction SilentlyContinue)
        if ($matches.Count -ne 1) {
            throw "Padrao obrigatorio deve encontrar 1 arquivo, encontrou $($matches.Count): $searchPath"
        }
        $sourcePath = $matches[0].FullName
        $relativeTargetPath = Join-Path (Split-Path -Parent $RelativePath) $matches[0].Name
    } else {
        $sourcePath = Join-Path $projectRoot $RelativePath
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Arquivo obrigatorio nao encontrado: $sourcePath"
        }
        $relativeTargetPath = $RelativePath
    }

    $targetPath = Join-Path $StageDir $relativeTargetPath
    $targetParent = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $targetParent)) {
        New-Item -Path $targetParent -ItemType Directory -Force | Out-Null
    }

    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
}

function Test-IsPackageJunk {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $normalized = $RelativePath -replace '/', '\'
    $leaf = Split-Path -Path $normalized -Leaf

    if ($normalized -match '^scripts\\Teste') { return $true }
    if ($normalized -match '^scripts\\.* - Copia') { return $true }
    if ($leaf -match '\.(tmp|temp|bak|old|orig|log)$') { return $true }
    if ($leaf -like '~$*') { return $true }
    return $false
}

function Copy-PackageTree {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$StageDir
    )

    $sourceRoot = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
        throw "Pasta obrigatoria nao encontrada: $sourceRoot"
    }

    $sourceRootResolved = (Resolve-Path -LiteralPath $sourceRoot).Path
    Get-ChildItem -LiteralPath $sourceRootResolved -Recurse -Force -File | ForEach-Object {
        $relativeFile = $_.FullName.Substring($projectRoot.Length + 1)
        if (Test-IsPackageJunk -RelativePath $relativeFile) {
            return
        }

        $targetPath = Join-Path $StageDir $relativeFile
        $targetParent = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $targetParent)) {
            New-Item -Path $targetParent -ItemType Directory -Force | Out-Null
        }

        Copy-Item -LiteralPath $_.FullName -Destination $targetPath -Force
    }
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $projectRoot "dist"
}
$OutputDir = (Resolve-Path -LiteralPath (New-Item -Path $OutputDir -ItemType Directory -Force).FullName).Path

$stageDir = Join-Path $env:TEMP ("InstTotem-stage-" + [guid]::NewGuid().ToString("N"))
New-Item -Path $stageDir -ItemType Directory -Force | Out-Null

try {
    $packageManifest = @(
        "TotemAutomacao.ps1",
        "README.md",
        "assets\\images\\Log-transparent.png",
        "assets\\images\\Log.png",
        "assets\\installers\\Arcade.exe",
        "assets\\installers\\Gtech Arcade Launcher Setup.exe",
        "assets\\installers\\P3L_WIN_DRIVER_272.exe",
        "assets\\installers\\vcredist_2015_2019_x64.exe",
        "assets\\installers\\XBox*.reg",
        "ui\\TotemUI.xaml"
    )

    foreach ($relativePath in $packageManifest) {
        Copy-PackageItem -RelativePath $relativePath -StageDir $stageDir
    }
    Copy-PackageTree -RelativePath "scripts" -StageDir $stageDir

    $zipPath = Join-Path $OutputDir $PackageName
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }

    Write-Step "Gerando pacote ZIP: $zipPath"
    Compress-Archive -Path (Join-Path $stageDir "*") -DestinationPath $zipPath -Force

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($zipPath)
        try {
            $hashBytes = $sha256.ComputeHash($stream)
        } finally {
            $stream.Dispose()
        }
    } finally {
        $sha256.Dispose()
    }
    $sha = ([System.BitConverter]::ToString($hashBytes) -replace "-", "").ToUpperInvariant()
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
