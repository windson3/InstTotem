[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Try-GetMainCommitSha {
    $requestParams = @{
        Uri         = "https://api.github.com/repos/windson3/InstTotem/commits/main"
        Method      = "Get"
        Headers     = @{
            "User-Agent" = "InstTotem-Installer"
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
        Write-Host "[InstTotem] Aviso: nao foi possivel resolver o commit main. Usando branch main." -ForegroundColor Yellow
    }

    return $null
}

$selfUri = "https://raw.githubusercontent.com/windson3/InstTotem/main/i.ps1"
if (-not (Test-IsAdministrator)) {
    $cacheBustSelf = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $selfCommand = "iwr -useb `"$selfUri?cb=$cacheBustSelf`" | iex"
    Start-Process powershell.exe -Verb RunAs -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $selfCommand)
    return
}

if ($PSVersionTable.PSEdition -ne "Core") {
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

$cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$bootstrapRef = Try-GetMainCommitSha
if ([string]::IsNullOrWhiteSpace($bootstrapRef)) {
    $bootstrapRef = "main"
    $bootstrapUri = "https://raw.githubusercontent.com/windson3/InstTotem/$bootstrapRef/bootstrap/Start-InstTotem.ps1?cb=$cacheBust"
} else {
    $bootstrapUri = "https://raw.githubusercontent.com/windson3/InstTotem/$bootstrapRef/bootstrap/Start-InstTotem.ps1"
}
$bootstrapSource = Invoke-RestMethod -Uri $bootstrapUri -ErrorAction Stop
& ([scriptblock]::Create($bootstrapSource))
