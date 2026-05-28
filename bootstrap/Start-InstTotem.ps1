[CmdletBinding()]
param(
    [string]$Repository = "windson3/InstTotem",
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

function Get-ExpectedHashFromFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $raw = (Get-Content -LiteralPath $Path -Raw).Trim()
    $m = [regex]::Match($raw, "([A-Fa-f0-9]{64})")
    if (-not $m.Success) {
        throw "Arquivo de hash invalido: $Path"
    }
    return $m.Groups[1].Value.ToUpperInvariant()
}

try {
    if ($PSVersionTable.PSEdition -ne "Core") {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    $releaseBase = "https://github.com/$Repository/releases/latest/download"
    $packageUrl = "$releaseBase/$PackageAssetName"
    $sha256Url = "$releaseBase/$Sha256AssetName"

    $downloadDir = Join-Path $InstallRoot "downloads"
    $extractDir = Join-Path $InstallRoot "current"
    $packagePath = Join-Path $downloadDir $PackageAssetName
    $sha256Path = Join-Path $downloadDir $Sha256AssetName

    New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null

    Write-Step "Baixando pacote: $PackageAssetName"
    Invoke-Download -Uri $packageUrl -OutFile $packagePath

    $hashVerified = $false
    if (-not $SkipHashCheck) {
        try {
            Write-Step "Baixando hash: $Sha256AssetName"
            Invoke-Download -Uri $sha256Url -OutFile $sha256Path

            $expectedHash = Get-ExpectedHashFromFile -Path $sha256Path
            $actualHash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToUpperInvariant()

            if ($actualHash -ne $expectedHash) {
                throw "Hash divergente. Esperado: $expectedHash | Atual: $actualHash"
            }
            $hashVerified = $true
            Write-Step "Hash SHA256 validado com sucesso."
        } catch {
            throw "Falha na validacao de hash: $($_.Exception.Message)"
        }
    }

    if (Test-Path -LiteralPath $extractDir) {
        Remove-Item -LiteralPath $extractDir -Recurse -Force
    }
    New-Item -Path $extractDir -ItemType Directory -Force | Out-Null

    Write-Step "Extraindo pacote para: $extractDir"
    Expand-Archive -LiteralPath $packagePath -DestinationPath $extractDir -Force

    $mainScript = Join-Path $extractDir "TotemAutomacao.ps1"
    if (-not (Test-Path -LiteralPath $mainScript)) {
        throw "Arquivo principal nao encontrado no pacote: $mainScript"
    }

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
