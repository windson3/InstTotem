[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
$bootstrapUri = "https://raw.githubusercontent.com/windson3/InstTotem/main/bootstrap/Start-InstTotem.ps1?cb=$cacheBust"
$bootstrapSource = Invoke-RestMethod -Uri $bootstrapUri -ErrorAction Stop
& ([scriptblock]::Create($bootstrapSource))
