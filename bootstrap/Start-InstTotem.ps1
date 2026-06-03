[CmdletBinding()]
param(
    [string]$Repository = "windson3/InstTotem",
    [string]$Branch = "main",
    [string]$PackageAssetName = "InstTotem-package.zip",
    [string]$Sha256AssetName = "InstTotem-package.sha256",
    [string]$InstallRoot = "$env:ProgramData\InstTotem",
    [string[]]$MainScriptArgumentList = @(),
    [switch]$SkipHashCheck,
    [switch]$NoDownloadProgress,
    [switch]$NoRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = if ($NoDownloadProgress) { "SilentlyContinue" } else { "Continue" }

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

    $startedAt = Get-Date
    Invoke-WebRequest @requestParams
    $elapsed = (Get-Date) - $startedAt
    $sizeBytes = if (Test-Path -LiteralPath $OutFile) {
        (Get-Item -LiteralPath $OutFile).Length
    } else {
        0
    }
    $sizeMb = [math]::Round(($sizeBytes / 1MB), 2)
    $elapsedSeconds = [math]::Round($elapsed.TotalSeconds, 1)
    Write-Step ("Download concluido: {0} ({1} MB em {2} s)" -f (Split-Path -Leaf $OutFile), $sizeMb, $elapsedSeconds)
}

function Get-HttpStatusCodeFromException {
    param([Parameter(Mandatory = $true)]$Exception)
    if ($Exception -and $Exception.Response) {
        return [int]$Exception.Response.StatusCode
    }
    return $null
}

function Try-GetBranchCommitSha {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$Branch
    )

    $uri = "https://api.github.com/repos/$Repository/commits/$Branch"
    $requestParams = @{
        Uri         = $uri
        Method      = "Get"
        Headers     = @{
            "User-Agent" = "InstTotem-Bootstrap"
            "Accept"     = "application/vnd.github+json"
        }
        ErrorAction = "Stop"
    }

    if ($PSVersionTable.PSVersion.Major -le 5 -and $PSVersionTable.PSEdition -ne "Core") {
        $requestParams.UseBasicParsing = $true
    }

    try {
        $response = Invoke-RestMethod @requestParams
        $sha = "$($response.sha)"
        if ($sha -match "^[A-Fa-f0-9]{40}$") {
            return $sha
        }
    } catch {
        Write-Host "[InstTotem] Aviso: nao foi possivel obter commit do branch '$Branch' ($($_.Exception.Message))." -ForegroundColor Yellow
    }

    return $null
}

function ConvertTo-RawGitHubPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $segments = $RelativePath -split "/"
    $encodedSegments = foreach ($segment in $segments) {
        [System.Uri]::EscapeDataString($segment)
    }
    return ($encodedSegments -join "/")
}

function Test-IsRuntimeSourcePath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $normalized = $RelativePath -replace "\\", "/"
    $normalizedLocal = $normalized.Replace("/", [string][System.IO.Path]::DirectorySeparatorChar)
    $leaf = [System.IO.Path]::GetFileName($normalizedLocal)

    if ($normalized -in @("TotemAutomacao.ps1", "README.md", "ui/TotemUI.xaml")) {
        return $true
    }

    if ($normalized -like "assets/images/*") {
        return $true
    }

    if ($normalized -like "assets/installers/*") {
        return $true
    }

    if ($normalized -like "scripts/*") {
        if ($normalized -like "scripts/Teste*") { return $false }
        if ($normalized -like "scripts/* - Copia*") { return $false }
        if ($leaf -match "\.(tmp|temp|bak|old|orig|log)$") { return $false }
        if ($leaf -like "~$*") { return $false }
        return $true
    }

    return $false
}

function Invoke-SourceTreeFallback {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$Branch,
        [string]$CommitSha,
        [Parameter(Mandatory = $true)][string]$ExtractDir
    )

    $sourceRef = if ($CommitSha) { $CommitSha } else { $Branch }
    $shortRef = if ($CommitSha) { $CommitSha.Substring(0, 7) } else { $Branch }
    $treeUri = "https://api.github.com/repos/$Repository/git/trees/$sourceRef" + "?recursive=1"
    $requestParams = @{
        Uri         = $treeUri
        Method      = "Get"
        Headers     = @{
            "User-Agent" = "InstTotem-Bootstrap"
            "Accept"     = "application/vnd.github+json"
        }
        ErrorAction = "Stop"
    }

    if ($PSVersionTable.PSVersion.Major -le 5 -and $PSVersionTable.PSEdition -ne "Core") {
        $requestParams.UseBasicParsing = $true
    }

    Write-Step "Pacote ZIP nao encontrado. Baixando arvore limpa do projeto ($shortRef)."
    $tree = Invoke-RestMethod @requestParams
    if ($tree.truncated) {
        throw "A API do GitHub retornou a arvore truncada; nao e seguro montar o runtime por fallback."
    }

    $entries = @($tree.tree | Where-Object {
            $_.type -eq "blob" -and (Test-IsRuntimeSourcePath -RelativePath "$($_.path)")
        } | Sort-Object path)

    if ($entries.Count -eq 0) {
        throw "Nenhum arquivo de runtime encontrado na arvore do repositorio."
    }

    New-Item -Path $ExtractDir -ItemType Directory -Force | Out-Null
    $cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    foreach ($entry in $entries) {
        $relativePath = "$($entry.path)"
        $encodedPath = ConvertTo-RawGitHubPath -RelativePath $relativePath
        $fileUri = "https://raw.githubusercontent.com/$Repository/$sourceRef/$encodedPath"
        if (-not $CommitSha) {
            $fileUri = "$($fileUri)?cb=$cacheBust"
        }

        $relativeLocalPath = $relativePath.Replace("/", [string][System.IO.Path]::DirectorySeparatorChar)
        $targetPath = Join-Path $ExtractDir $relativeLocalPath
        $targetParent = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $targetParent)) {
            New-Item -Path $targetParent -ItemType Directory -Force | Out-Null
        }

        Write-Step "Baixando arquivo do projeto: $relativePath"
        Invoke-Download -Uri $fileUri -OutFile $targetPath
    }

    $mainScript = Join-Path $ExtractDir "TotemAutomacao.ps1"
    if (-not (Test-Path -LiteralPath $mainScript)) {
        throw "Arquivo principal nao encontrado na arvore baixada: $mainScript"
    }

    Get-ChildItem -LiteralPath $ExtractDir -Recurse -Force -File -Filter "*.ps1" |
        ForEach-Object { Ensure-Utf8BomFile -Path $_.FullName }
}

function Invoke-DownloadWithFallback {
    param(
        [Parameter(Mandatory = $true)][string[]]$Uris,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $errors = @()
    for ($i = 0; $i -lt $Uris.Count; $i++) {
        $uri = $Uris[$i]
        try {
            Write-Step "Baixando ${Label} (origem $($i + 1)/$($Uris.Count)): $uri"
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

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Path)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $hashBytes = $sha256.ComputeHash($stream)
        } finally {
            $stream.Dispose()
        }
    } finally {
        $sha256.Dispose()
    }

    return ([System.BitConverter]::ToString($hashBytes) -replace "-", "").ToUpperInvariant()
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
    $rawBranchBase = "https://raw.githubusercontent.com/$Repository/$Branch"
    $downloadSources = @()
    $downloadSources += [pscustomobject]@{
        Name       = "GitHub Release (latest)"
        PackageUri = "$releaseBase/$PackageAssetName"
        ShaUri     = "$releaseBase/$Sha256AssetName"
    }

    $branchCommitSha = Try-GetBranchCommitSha -Repository $Repository -Branch $Branch
    if ($branchCommitSha) {
        $rawCommitBase = "https://raw.githubusercontent.com/$Repository/$branchCommitSha"
        $downloadSources += [pscustomobject]@{
            Name       = "Raw commit $($branchCommitSha.Substring(0, 7))"
            PackageUri = "$rawCommitBase/dist/$PackageAssetName"
            ShaUri     = "$rawCommitBase/dist/$Sha256AssetName"
        }
    }

    $cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $downloadSources += [pscustomobject]@{
        Name       = "Raw branch (cache-bust)"
        PackageUri = "$rawBranchBase/dist/$($PackageAssetName)?cb=$cacheBust"
        ShaUri     = "$rawBranchBase/dist/$($Sha256AssetName)?cb=$cacheBust"
    }

    $downloadDir = Join-Path $InstallRoot "downloads"
    $releasesDir = Join-Path $InstallRoot "releases"
    $runId = Get-Date -Format "yyyyMMdd-HHmmss"
    $extractDir = Join-Path $releasesDir $runId
    $latestPointerPath = Join-Path $InstallRoot "latest-release.txt"
    $packagePath = Join-Path $downloadDir $PackageAssetName
    $sha256Path = Join-Path $downloadDir $Sha256AssetName

    New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
    New-Item -Path $releasesDir -ItemType Directory -Force | Out-Null

    $packageSource = $null
    $hashSource = $null
    $hashVerified = $false
    $installedFromSourceTree = $false
    $downloadErrors = @()

    for ($i = 0; $i -lt $downloadSources.Count; $i++) {
        $source = $downloadSources[$i]
        try {
            Write-Step ("Tentando origem {0}/{1}: {2}" -f ($i + 1), $downloadSources.Count, $source.Name)
            Write-Step "Baixando ${PackageAssetName}: $($source.PackageUri)"
            Invoke-Download -Uri $source.PackageUri -OutFile $packagePath
            $packageSource = $source.PackageUri

            if ($SkipHashCheck) {
                $hashVerified = $false
                break
            }

            Write-Step "Baixando ${Sha256AssetName}: $($source.ShaUri)"
            Invoke-Download -Uri $source.ShaUri -OutFile $sha256Path
            $hashSource = $source.ShaUri

            $expectedHash = Get-ExpectedHashFromFile -Path $sha256Path
            $actualHash = Get-Sha256Hex -Path $packagePath

            if ($actualHash -ne $expectedHash) {
                throw "Hash divergente. Esperado: $expectedHash | Atual: $actualHash"
            }

            $hashVerified = $true
            Write-Step "Hash SHA256 validado com sucesso. (pacote: $packageSource | hash: $hashSource)"
            break
        } catch {
            $status = Get-HttpStatusCodeFromException -Exception $_.Exception
            $msg = if ($status) { "HTTP $status" } else { $_.Exception.Message }
            Write-Host "[InstTotem] Falha na origem '$($source.Name)' ($msg)." -ForegroundColor Yellow
            $downloadErrors += "$($source.Name) => $msg"
        }
    }

    if ($packageSource -and -not $SkipHashCheck -and -not $hashVerified) {
        throw "Falha na validacao de hash. Tentativas: $($downloadErrors -join '; ')"
    }

    New-Item -Path $extractDir -ItemType Directory -Force | Out-Null

    if ($packageSource) {
        Write-Step "Extraindo pacote para: $extractDir"
        Expand-Archive -LiteralPath $packagePath -DestinationPath $extractDir -Force
    } else {
        Write-Host "[InstTotem] Aviso: pacote nao disponivel nas origens configuradas. Tentativas: $($downloadErrors -join '; ')" -ForegroundColor Yellow
        Invoke-SourceTreeFallback -Repository $Repository -Branch $Branch -CommitSha $branchCommitSha -ExtractDir $extractDir
        $installedFromSourceTree = $true
    }

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
    } elseif ($installedFromSourceTree) {
        Write-Step "Executando TotemAutomacao.ps1 (arvore limpa do GitHub)."
    } else {
        Write-Step "Executando TotemAutomacao.ps1."
    }

    & $mainScript @MainScriptArgumentList
} catch {
    Write-Host "[InstTotem] ERRO: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
