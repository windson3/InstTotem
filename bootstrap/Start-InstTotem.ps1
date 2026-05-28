[CmdletBinding()]
param(
    [string]$Repository = "windson3/InstTotem",
    [string]$Branch = "main",
    [string]$PackageAssetName = "InstTotem-package.zip",
    [string]$Sha256AssetName = "InstTotem-package.sha256",
    [string]$InstallRoot = "$env:ProgramData\InstTotem",
    [switch]$SkipHashCheck,
    [switch]$NoRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Step {
    param([string]$Message)
    Write-Host "[InstTotem] $Message" -ForegroundColor Cyan
}

function Invoke-Download {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile
    )

    $requestParams = @{
        Uri         = $Uri
        OutFile     = $OutFile
        ErrorAction = "Stop"
    }

    if ($PSVersionTable.PSVersion.Major -le 5 -and $PSVersionTable.PSEdition -ne "Core") {
        $requestParams.UseBasicParsing = $true
    }

    Invoke-WebRequest @requestParams
}

function Get-HttpStatusCodeFromException {
    param([Parameter(Mandatory = $true)]$Exception)
    if ($Exception -and $Exception.Response) {
        return [int]$Exception.Response.StatusCode
    }
    return $null
}

function Invoke-DownloadWithFallback {
    param(
        [Parameter(Mandatory = $true)][string[]]$Uris,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $errors = @()
    foreach ($uri in $Uris) {
        try {
            Write-Step "Baixando ${Label}: $uri"
            Invoke-Download -Uri $uri -OutFile $OutFile
            return $uri
        } catch {
            $status = Get-HttpStatusCodeFromException -Exception $_.Exception
            $msg = if ($status) { "HTTP $status" } else { $_.Exception.Message }
            Write-Host "[InstTotem] Falha em $uri ($msg). Tentando proxima origem..." -ForegroundColor Yellow
            $errors += "$uri => $msg"
        }
    }

    throw "Nao foi possivel baixar $Label. Tentativas: $($errors -join '; ')"
}

function Get-ExpectedHashFromFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $raw = (Get-Content -LiteralPath $Path -Raw).Trim()
    $m = [regex]::Match($raw, "([A-Fa-f0-9]{64})")
    if (-not $m.Success) {
        throw "Arquivo de hash invalido: $Path"
    }
    return $m.Groups[1].Value.ToUpperInvariant()
}

function Ensure-Utf8BomFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    if ($hasBom) {
        return
    }

    try {
        $utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
        $text = $utf8Strict.GetString($bytes)
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($Path, $text, $utf8Bom)
        Write-Step "Encoding normalizado para UTF-8 BOM: $Path"
    } catch {
        throw "Falha ao normalizar encoding de ${Path}: $($_.Exception.Message)"
    }
}

function Remove-OldReleasesBestEffort {
    param(
        [Parameter(Mandatory = $true)][string]$ReleasesDir,
        [int]$Keep = 3
    )

    if (-not (Test-Path -LiteralPath $ReleasesDir)) {
        return
    }

    $dirs = Get-ChildItem -LiteralPath $ReleasesDir -Directory |
        Sort-Object LastWriteTime -Descending

    if ($dirs.Count -le $Keep) {
        return
    }

    $toRemove = $dirs | Select-Object -Skip $Keep
    foreach ($dir in $toRemove) {
        try {
            Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Host "[InstTotem] Aviso: nao foi possivel remover release antiga '$($dir.FullName)' ($($_.Exception.Message))" -ForegroundColor Yellow
        }
    }
}

try {
    if ($PSVersionTable.PSEdition -ne "Core") {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    $releaseBase = "https://github.com/$Repository/releases/latest/download"
    $rawBase = "https://raw.githubusercontent.com/$Repository/$Branch"
    $packageCandidates = @(
        "$releaseBase/$PackageAssetName",
        "$rawBase/dist/$PackageAssetName"
    )
    $shaCandidates = @(
        "$releaseBase/$Sha256AssetName",
        "$rawBase/dist/$Sha256AssetName"
    )

    $downloadDir = Join-Path $InstallRoot "downloads"
    $releasesDir = Join-Path $InstallRoot "releases"
    $runId = Get-Date -Format "yyyyMMdd-HHmmss"
    $extractDir = Join-Path $releasesDir $runId
    $latestPointerPath = Join-Path $InstallRoot "latest-release.txt"
    $packagePath = Join-Path $downloadDir $PackageAssetName
    $sha256Path = Join-Path $downloadDir $Sha256AssetName

    New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
    New-Item -Path $releasesDir -ItemType Directory -Force | Out-Null

    $packageSource = Invoke-DownloadWithFallback -Uris $packageCandidates -OutFile $packagePath -Label $PackageAssetName

    $hashVerified = $false
    if (-not $SkipHashCheck) {
        try {
            $hashSource = Invoke-DownloadWithFallback -Uris $shaCandidates -OutFile $sha256Path -Label $Sha256AssetName

            $expectedHash = Get-ExpectedHashFromFile -Path $sha256Path
            $actualHash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToUpperInvariant()

            if ($actualHash -ne $expectedHash) {
                throw "Hash divergente. Esperado: $expectedHash | Atual: $actualHash"
            }
            $hashVerified = $true
            Write-Step "Hash SHA256 validado com sucesso. (pacote: $packageSource | hash: $hashSource)"
        } catch {
            throw "Falha na validacao de hash: $($_.Exception.Message)"
        }
    }

    New-Item -Path $extractDir -ItemType Directory -Force | Out-Null

    Write-Step "Extraindo pacote para: $extractDir"
    Expand-Archive -LiteralPath $packagePath -DestinationPath $extractDir -Force

    $mainScript = Join-Path $extractDir "TotemAutomacao.ps1"
    if (-not (Test-Path -LiteralPath $mainScript)) {
        throw "Arquivo principal nao encontrado no pacote: $mainScript"
    }
    Ensure-Utf8BomFile -Path $mainScript
    Set-Content -LiteralPath $latestPointerPath -Value $extractDir -Encoding UTF8
    Remove-OldReleasesBestEffort -ReleasesDir $releasesDir -Keep 3

    if ($NoRun) {
        Write-Step "Pacote preparado com sucesso (NoRun). Script principal: $mainScript"
        return
    }

    if ($hashVerified) {
        Write-Step "Executando TotemAutomacao.ps1 (pacote validado)."
    } else {
        Write-Step "Executando TotemAutomacao.ps1."
    }

    & $mainScript
} catch {
    Write-Host "[InstTotem] ERRO: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
