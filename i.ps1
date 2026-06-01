[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSEdition -ne "Core") {
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

$bootstrapUri = "https://raw.githubusercontent.com/windson3/InstTotem/main/bootstrap/Start-InstTotem.ps1"
$bootstrapSource = Invoke-RestMethod -Uri $bootstrapUri -ErrorAction Stop
& ([scriptblock]::Create($bootstrapSource))
