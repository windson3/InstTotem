#--------------------------------------------------------------
# SetupTotemGUI.ps1
# GUI inspirada no winutil (https://christitus.com/windev)
# ----------------------------------------------------------

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptDir "..\\..")).Path
$candidateTransparent = Join-Path $projectRoot "assets\\images\\Log-transparent.png"
$candidateFallback = Join-Path $projectRoot "assets\\images\\Log.png"
$script:logoPath = if (Test-Path $candidateTransparent) { $candidateTransparent } else { $candidateFallback }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$bgColor     = [System.Drawing.Color]::FromArgb(30,30,30)
$panelColor  = [System.Drawing.Color]::FromArgb(45,45,45)
$accentColor = [System.Drawing.Color]::FromArgb(0,122,204)
$fontFamily  = "Segoe UI"

function New-GuiCheckBox {
    param([string]$Text,[int]$X,[int]$Y,[bool]$Checked=$false)
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $Text
    $cb.AutoSize = $true
    $cb.Location = New-Object System.Drawing.Point($X,$Y)
    $cb.ForeColor = [System.Drawing.Color]::White
    $cb.BackColor = $panelColor
    $cb.Font = New-Object System.Drawing.Font($fontFamily,10)
    $cb.Checked = $Checked
    return $cb
}

function New-GuiButton {
    param([string]$Text,[int]$X,[int]$Y,[int]$Width=200,[int]$Height=35,[scriptblock]$OnClick)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Size = New-Object System.Drawing.Size($Width,$Height)
    $btn.Location = New-Object System.Drawing.Point($X,$Y)
    $btn.FlatStyle = "Flat"
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.BackColor = $accentColor
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font($fontFamily,10,[System.Drawing.FontStyle]::Bold)
    if ($OnClick) { $btn.Add_Click($OnClick) }
    return $btn
}

function Show-GuiMessage {
    param([string]$msg)
    [System.Windows.Forms.MessageBox]::Show($msg,"Totem","OK","Information") | Out-Null
}

# === Janela Principal ===
$frm = New-Object System.Windows.Forms.Form
$frm.Text = "Totem - Automacao"
$frm.Size = New-Object System.Drawing.Size(960,620)
$frm.StartPosition = "CenterScreen"
$frm.BackColor = $bgColor
$frm.Font = New-Object System.Drawing.Font($fontFamily,9)

# === Logo ===
if (Test-Path $logoPath) {
    $logoPic = New-Object System.Windows.Forms.PictureBox
    $logoPic.ImageLocation = $logoPath
    $logoPic.SizeMode = "Zoom"
    $logoPic.Size = New-Object System.Drawing.Size(120,60)
    $logoPic.Location = New-Object System.Drawing.Point(15,10)
    $frm.Controls.Add($logoPic) | Out-Null
}

# === TabControl ===
$tab = New-Object System.Windows.Forms.TabControl
$tab.Size = New-Object System.Drawing.Size(920,520)
$tab.Location = New-Object System.Drawing.Point(20,80)
$tab.Alignment = "Top"
$tab.BackColor = $bgColor
$tab.ForeColor = [System.Drawing.Color]::White

# ============================
# Aba 1: Instalacao
# ============================
$tabInst = New-Object System.Windows.Forms.TabPage
$tabInst.Text = "Instalacao"
$tabInst.BackColor = $bgColor

$lbl1 = New-Object System.Windows.Forms.Label
$lbl1.Text = "Programas para Instalar"
$lbl1.ForeColor = $accentColor
$lbl1.Font = New-Object System.Drawing.Font($fontFamily,12,[System.Drawing.FontStyle]::Bold)
$lbl1.Location = New-Object System.Drawing.Point(20,15)
$lbl1.AutoSize = $true
$tabInst.Controls.Add($lbl1) | Out-Null

$progWinget = @(
    "Microsoft PowerShell 7",
    "Notepad++",
    "Google Chrome",
    "AnyDesk",
    "WinRAR",
    "7-Zip"
)

$y = 50
$script:checksWinget = @()
foreach ($p in $progWinget) {
    $cb = New-GuiCheckBox -Text "[winget] $p" -X 20 -Y $y
    $script:checksWinget += $cb
    $tabInst.Controls.Add($cb) | Out-Null
    $y += 28
}

$y += 10
$lblLocal = New-Object System.Windows.Forms.Label
$lblLocal.Text = "Programas Locais (Totem)"
$lblLocal.ForeColor = [System.Drawing.Color]::FromArgb(255,165,0)
$lblLocal.Font = New-Object System.Drawing.Font($fontFamily,11,[System.Drawing.FontStyle]::Bold)
$lblLocal.Location = New-Object System.Drawing.Point(20,$y)
$lblLocal.AutoSize = $true
$tabInst.Controls.Add($lblLocal) | Out-Null
$y += 30

$progTotem = @(
    "Arcade (Gtech) - Instalador Local",
    "P3L Driver - Impressora Termica",
    "vcredist 2015-2019 x64"
)
$script:checksTotem = @()
foreach ($p in $progTotem) {
    $cb = New-GuiCheckBox -Text $p -X 20 -Y $y
    $script:checksTotem += $cb
    $tabInst.Controls.Add($cb) | Out-Null
    $y += 28
}

$btnInstall = New-GuiButton -Text "Instalar Selecionados" -X 20 -Y ($y+20) -OnClick {
    $s1 = $script:checksWinget | Where-Object { $_.Checked }
    $s2 = $script:checksTotem | Where-Object { $_.Checked }
    if ($s1.Count -eq 0 -and $s2.Count -eq 0) {
        Show-GuiMessage "Nenhum programa selecionado."
        return
    }
    $list = @()
    foreach ($s in $s1) { $list += "  [winget] $($s.Text)" }
    foreach ($s in $s2) { $list += "  [local] $($s.Text)" }
    Show-GuiMessage "Instalaria:`n$($list -join "`n")"
}
$tabInst.Controls.Add($btnInstall) | Out-Null

$btnSelAll = New-GuiButton -Text "Selecionar Todos" -X 240 -Y ($y+20) -Width 160 -OnClick {
    foreach ($cb in $script:checksWinget) { $cb.Checked = $true }
    foreach ($cb in $script:checksTotem) { $cb.Checked = $true }
}
$tabInst.Controls.Add($btnSelAll) | Out-Null

# ============================
# Aba 2: Debloat
# ============================
$tabDebloat = New-Object System.Windows.Forms.TabPage
$tabDebloat.Text = "Debloat"
$tabDebloat.BackColor = $bgColor

$lbl2 = New-Object System.Windows.Forms.Label
$lbl2.Text = "Remover Bloatware / Otimizar Windows"
$lbl2.ForeColor = $accentColor
$lbl2.Font = New-Object System.Drawing.Font($fontFamily,12,[System.Drawing.FontStyle]::Bold)
$lbl2.Location = New-Object System.Drawing.Point(20,15)
$lbl2.AutoSize = $true
$tabDebloat.Controls.Add($lbl2) | Out-Null

$tweakGroups = @(
    @{Name="Bloatware Apps"; Items=@(
        "Microsoft Edge",
        "Microsoft OneDrive",
        "Microsoft Teams",
        "Xbox + GameBar + GameDVR",
        "BingNews / BingWeather / BingSearch",
        "Clipchamp",
        "Solitaire Collection",
        "Zune Music / Zune Video",
        "Maps / Alarms / Camera / SoundRecorder",
        "Todos / People / Phone Link / YourPhone",
        "FeedbackHub / GetHelp / Mail / Calendar"
    )},
    @{Name="Servicos para Desativar"; Items=@(
        "DiagTrack (telemetria)",
        "SysMain / Superfetch",
        "WSearch (indexacao)",
        "Fax Service",
        "Geolocation Service",
        "Distributed Link Tracking"
    )},
    @{Name="Tarefas Agendadas"; Items=@(
        "Desativar CEIP / telemetria",
        "Desativar Compatibility Appraiser",
        "Desativar Disk Diagnostic",
        "Desativar Location notifications"
    )},
    @{Name="Registro (Registry)"; Items=@(
        "Desativar GameDVR / GameBar",
        "Desativar Cortana",
        "Desativar Telemetria",
        "Desativar Clipboard History",
        "Desativar ads no File Explorer"
    )}
)

$y = 55
$script:allDebChecks = @()
foreach ($grp in $tweakGroups) {
    $lblG = New-Object System.Windows.Forms.Label
    $lblG.Text = $grp.Name
    $lblG.ForeColor = [System.Drawing.Color]::FromArgb(255,165,0)
    $lblG.Font = New-Object System.Drawing.Font($fontFamily,10,[System.Drawing.FontStyle]::Bold)
    $lblG.Location = New-Object System.Drawing.Point(20,$y)
    $lblG.AutoSize = $true
    $tabDebloat.Controls.Add($lblG) | Out-Null
    $y += 25

    foreach ($item in $grp.Items) {
        $cb = New-GuiCheckBox -Text $item -X 40 -Y $y -Checked $true
        $script:allDebChecks += $cb
        $tabDebloat.Controls.Add($cb) | Out-Null
        $y += 24
    }
    $y += 8
}

$btnAppDeb = New-GuiButton -Text "Aplicar Debloat" -X 20 -Y ($y+10) -OnClick {
    $sel = $script:allDebChecks | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) {
        Show-GuiMessage "Nenhuma opcao selecionada."
        return
    }
    Show-GuiMessage "Executaria debloat para $($sel.Count) itens."
}
$tabDebloat.Controls.Add($btnAppDeb) | Out-Null

$btnUndoDeb = New-GuiButton -Text "Reverter" -X 240 -Y ($y+10) -Width 130 -OnClick {
    Show-GuiMessage "Reverteria todas as mudancas usando -Revert nos scripts."
}
$tabDebloat.Controls.Add($btnUndoDeb) | Out-Null

$btnSelDeb = New-GuiButton -Text "Marcar Todos" -X 390 -Y ($y+10) -Width 130 -OnClick {
    foreach ($cb in $script:allDebChecks) { $cb.Checked = $true }
}
$tabDebloat.Controls.Add($btnSelDeb) | Out-Null

# ============================
# Aba 3: Sobre
# ============================
$tabAbout = New-Object System.Windows.Forms.TabPage
$tabAbout.Text = "Sobre"
$tabAbout.BackColor = $bgColor

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = @"

  Totem - Automacao para Quiosques Gtech Arcade
  Versao: 1.0.0

  Esta ferramenta reune:
    - Instalacao de programas essenciais (winget + locais)
    - Remocao de bloatware e desativacao de servicos
    - Tweaks de privacidade, desempenho e seguranca
    - Otimizacao do Windows para totens/quiosques

  Baseado em:
    - Win-Debloat-Tools (LeDragoX)
    - Windows10Debloater (Sycnex)
    - winutil (Chris Titus Tech)

  Desenvolvido por: $env:USERNAME
"@
$lblInfo.ForeColor = [System.Drawing.Color]::White
$lblInfo.Font = New-Object System.Drawing.Font($fontFamily,10)
$lblInfo.AutoSize = $false
$lblInfo.Size = New-Object System.Drawing.Size(800,350)
$lblInfo.Location = New-Object System.Drawing.Point(20,20)
$tabAbout.Controls.Add($lblInfo) | Out-Null

# ============================
# Montar tudo
# ============================
$tab.TabPages.Add($tabInst)    | Out-Null
$tab.TabPages.Add($tabDebloat) | Out-Null
$tab.TabPages.Add($tabAbout)   | Out-Null
$frm.Controls.Add($tab)        | Out-Null

# Botao fechar X
$lblX = New-Object System.Windows.Forms.Label
$lblX.Text = "X"
$lblX.ForeColor = [System.Drawing.Color]::FromArgb(200,50,50)
$lblX.Font = New-Object System.Drawing.Font($fontFamily,14,[System.Drawing.FontStyle]::Bold)
$lblX.Location = New-Object System.Drawing.Point(910,12)
$lblX.AutoSize = $true
$lblX.Cursor = "Hand"
$lblX.Add_Click({ $frm.Close() })
$frm.Controls.Add($lblX) | Out-Null
$lblX.BringToFront()

$frm.Add_Shown({ $frm.Activate() })
[System.Windows.Forms.Application]::Run($frm)
