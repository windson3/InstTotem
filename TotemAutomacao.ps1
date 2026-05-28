<#    --------------------------------------------------------------
    TotemAutomacao.ps1
    Totem – Automação para Quiosques Gtech Arcade
    Interface WPF (inspirada no winutil) – tudo em um único script
    --------------------------------------------------------------
#>    
#    ---------- Auto‑elevação ----------
    if (-not ([Security.Principal.WindowsPrincipal] `
              [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
              [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $hostExe = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
        Start-Process -FilePath $hostExe -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', "`"$PSCommandPath`""
        ) -Verb RunAs
        exit
    }
    
#    ---------- Carregar assemblies WPF ----------
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    
#    ---------- Funções auxiliares ----------
    function Show-Popup {
        param([string]$Title, [string]$Message)
        [System.Windows.MessageBox]::Show($Message,$Title,"OK","Information") | Out-Null
    }
    function Invoke-Safe {
        param(
            [Parameter(Mandatory = $true)][scriptblock]$Action,
            [Parameter(Mandatory = $true)][string]$Desc
        )
        try {
            Write-Host "[$Desc] Executando..." -ForegroundColor Cyan
            & $Action 2>&1 | Out-String | Write-Host -ForegroundColor Gray
            $true
        } catch {
            Write-Host "ERRO [$Desc]: $($_.Exception.Message)" -ForegroundColor Red
            $false
        }
    }
    # Preenche o dicionário $Elements com todos os controles que têm x:Name
    function Build-ElementsTable {
        param($Root,$Names)
        $tbl = @{}
        foreach($n in $Names){
            $tbl[$n] = $Root.FindName($n)
        }
        $tbl
    }
    
#    ---------- Paths ----------
    $BasePath      = Split-Path -Parent $MyInvocation.MyCommand.Path
    $AssetsPath    = Join-Path $BasePath "assets"
    $ImagesPath    = Join-Path $AssetsPath "images"
    $InstallersPath = Join-Path $AssetsPath "installers"
    $ProgramasPath = if (Test-Path $InstallersPath) { $InstallersPath } else { Join-Path $BasePath "Programas_Reg" }
    $LogoPath      = if (Test-Path (Join-Path $ImagesPath "Log-transparent.png")) {
        Join-Path $ImagesPath "Log-transparent.png"
    } elseif (Test-Path (Join-Path $BasePath "Imagens\\Log-transparent.png")) {
        Join-Path $BasePath "Imagens\\Log-transparent.png"
    } else {
        Join-Path $BasePath "Imagens\\Log.png"
    }
    
#    ---------- XAML embutido ----------
    $Xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            WindowStartupLocation="CenterScreen"
            WindowStyle="None"
            Background="#15171A"
            Width="1060" Height="700"
            Title="Totem Automação">
    
      <Window.Resources>
        <SolidColorBrush x:Key="FgBrush" Color="#F8F8F8"/>
        <SolidColorBrush x:Key="MutedBrush" Color="#C4CBD3"/>
        <SolidColorBrush x:Key="BgBrush" Color="#15171A"/>
        <SolidColorBrush x:Key="PanelBrush" Color="#1D2127"/>
        <SolidColorBrush x:Key="CardBrush" Color="#242930"/>
        <SolidColorBrush x:Key="BorderBrush" Color="#3A414B"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#C70A2E"/>
        <SolidColorBrush x:Key="AccentHoverBrush" Color="#DD1E45"/>
        <SolidColorBrush x:Key="DangerBrush" Color="#8F1329"/>

        <Style x:Key="PanelCard" TargetType="Border">
          <Setter Property="Background" Value="{StaticResource PanelBrush}"/>
          <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
          <Setter Property="BorderThickness" Value="1"/>
          <Setter Property="CornerRadius" Value="10"/>
          <Setter Property="Padding" Value="8"/>
        </Style>

        <Style x:Key="TabToggleStyle" TargetType="ToggleButton">
          <Setter Property="FontSize" Value="13"/>
          <Setter Property="FontWeight" Value="Bold"/>
          <Setter Property="Foreground" Value="{StaticResource MutedBrush}"/>
          <Setter Property="Background" Value="#21242A"/>
          <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
          <Setter Property="Height" Value="34"/>
          <Setter Property="Width" Value="132"/>
          <Setter Property="Margin" Value="0,0,8,0"/>
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="ToggleButton">
                <Border x:Name="B"
                        Background="{TemplateBinding Background}"
                        BorderBrush="{TemplateBinding BorderBrush}"
                        BorderThickness="1"
                        CornerRadius="8"
                        Padding="10,4">
                  <ContentPresenter HorizontalAlignment="Center"
                                    VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="B" Property="Background" Value="#2C3139"/>
                    <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
                    <Setter Property="Cursor" Value="Hand"/>
                  </Trigger>
                  <Trigger Property="IsChecked" Value="True">
                    <Setter TargetName="B" Property="Background" Value="{StaticResource AccentBrush}"/>
                    <Setter TargetName="B" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                    <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Style>
    
        <Style x:Key="ActionButtonStyle" TargetType="Button">
          <Setter Property="FontSize" Value="12.5"/>
          <Setter Property="FontWeight" Value="Bold"/>
          <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
          <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
          <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
          <Setter Property="Height" Value="32"/>
          <Setter Property="Width" Value="180"/>
          <Setter Property="Margin" Value="4"/>
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="Button">
                <Border x:Name="B"
                        Background="{TemplateBinding Background}"
                        BorderBrush="{TemplateBinding BorderBrush}"
                        BorderThickness="1"
                        CornerRadius="8"
                        Padding="10,4">
                  <ContentPresenter HorizontalAlignment="Center"
                                    VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="B" Property="Background" Value="{StaticResource AccentHoverBrush}"/>
                    <Setter TargetName="B" Property="BorderBrush" Value="{StaticResource AccentHoverBrush}"/>
                    <Setter Property="Cursor" Value="Hand"/>
                  </Trigger>
                  <Trigger Property="IsPressed" Value="True">
                    <Setter TargetName="B" Property="Background" Value="#A00725"/>
                    <Setter TargetName="B" Property="BorderBrush" Value="#A00725"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Style>
    
        <Style x:Key="DangerButtonStyle" TargetType="Button">
          <Setter Property="FontSize" Value="12.5"/>
          <Setter Property="FontWeight" Value="Bold"/>
          <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
          <Setter Property="Background" Value="{StaticResource DangerBrush}"/>
          <Setter Property="BorderBrush" Value="{StaticResource DangerBrush}"/>
          <Setter Property="Height" Value="32"/>
          <Setter Property="Width" Value="180"/>
          <Setter Property="Margin" Value="4"/>
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="Button">
                <Border x:Name="B"
                        Background="{TemplateBinding Background}"
                        BorderBrush="{TemplateBinding BorderBrush}"
                        BorderThickness="1"
                        CornerRadius="8"
                        Padding="10,4">
                  <ContentPresenter HorizontalAlignment="Center"
                                    VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="B" Property="Background" Value="#AF1B36"/>
                    <Setter TargetName="B" Property="BorderBrush" Value="#AF1B36"/>
                    <Setter Property="Cursor" Value="Hand"/>
                  </Trigger>
                  <Trigger Property="IsPressed" Value="True">
                    <Setter TargetName="B" Property="Background" Value="#721022"/>
                    <Setter TargetName="B" Property="BorderBrush" Value="#721022"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Style>
    
        <Style x:Key="ToggleSwitchStyle" TargetType="CheckBox">
          <Setter Property="FontSize" Value="14"/>
          <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
          <Setter Property="Margin" Value="8,4"/>
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="CheckBox">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                  <ContentPresenter VerticalAlignment="Center" Margin="4,0"/>
                  <Border x:Name="SwitchBorder" Width="44" Height="22"
                          Background="#505A65" CornerRadius="11" Margin="8,0">
                    <Ellipse x:Name="SwitchDot" Width="16" Height="16"
                             Fill="White" HorizontalAlignment="Left"
                             VerticalAlignment="Center" Margin="3,0"/>
                  </Border>
                </StackPanel>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsChecked" Value="True">
                    <Setter TargetName="SwitchBorder" Property="Background" Value="{StaticResource AccentBrush}"/>
                    <Setter TargetName="SwitchDot" Property="HorizontalAlignment" Value="Right"/>
                  </Trigger>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Cursor" Value="Hand"/>
                    <Setter TargetName="SwitchBorder" Property="Opacity" Value="0.85"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Style>
    
        <Style x:Key="CatLabel" TargetType="Label">
          <Setter Property="FontSize" Value="15"/>
          <Setter Property="FontWeight" Value="Bold"/>
          <Setter Property="Foreground" Value="{StaticResource AccentBrush}"/>
          <Setter Property="Margin" Value="8,14,8,4"/>
        </Style>
    
        <Style x:Key="SubLabel" TargetType="Label">
          <Setter Property="FontSize" Value="12"/>
          <Setter Property="Foreground" Value="{StaticResource MutedBrush}"/>
          <Setter Property="Opacity" Value="0.9"/>
          <Setter Property="Margin" Value="16,2,8,4"/>
        </Style>
    
        <Style x:Key="SepStyle" TargetType="Separator">
          <Setter Property="Background" Value="{StaticResource BorderBrush}"/>
          <Setter Property="Height" Value="1"/>
          <Setter Property="Margin" Value="8,10"/>
        </Style>
      </Window.Resources>
    
      <Border CornerRadius="10" Background="{StaticResource BgBrush}"
              BorderBrush="{StaticResource BorderBrush}" BorderThickness="1">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="62"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
          </Grid.RowDefinitions>
    
          <!-- Title bar -->
          <Grid Grid.Row="0" Background="#111316">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="Auto"/>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Border Height="1" VerticalAlignment="Bottom"
                    Background="{StaticResource AccentBrush}" Opacity="0.8"
                    Grid.ColumnSpan="3"/>
    
            <Border Grid.Column="0" Width="56" Height="56" Margin="10,3,0,3"
                    Background="Transparent" CornerRadius="8">
              <Image Source="$LogoPath"
                     Width="44" Height="44" Stretch="Uniform"
                     VerticalAlignment="Center" HorizontalAlignment="Center"/>
            </Border>
    
            <StackPanel Grid.Column="1" Orientation="Vertical"
                        VerticalAlignment="Center" Margin="12,0">
              <TextBlock Text="Totem v1.0" FontSize="17" FontWeight="Bold"
                         Foreground="{StaticResource FgBrush}"/>
              <TextBlock Text="Automação para Quiosques Gtech Arcade"
                         FontSize="12" Foreground="{StaticResource MutedBrush}"/>
            </StackPanel>
    
            <StackPanel Grid.Column="2" Orientation="Horizontal"
                        VerticalAlignment="Center" Margin="0,0,10,0">
              <Button Grid.Column="2" x:Name="btnClose" Content="X"
                      Width="36" Height="36" FontSize="16"
                      Foreground="{StaticResource FgBrush}" Background="{StaticResource DangerBrush}"
                      BorderBrush="{StaticResource DangerBrush}" BorderThickness="1"
                      Margin="0,0,0,0" Cursor="Hand"/>
            </StackPanel>
          </Grid>
    
          <!-- Tabs -->
          <Grid Grid.Row="1" Margin="12,10,12,8">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Style="{StaticResource PanelCard}" Padding="8,6">
              <StackPanel Orientation="Horizontal">
                <ToggleButton x:Name="tabInstall" Content="Instalar"
                              Style="{StaticResource TabToggleStyle}" IsChecked="True"/>
                <ToggleButton x:Name="tabTweaks" Content="Tweaks"
                              Style="{StaticResource TabToggleStyle}"/>
                <ToggleButton x:Name="tabConfig" Content="Config"
                              Style="{StaticResource TabToggleStyle}"/>
              </StackPanel>
            </Border>

            <Border Grid.Column="1" Style="{StaticResource PanelCard}" Margin="10,0,0,0" Padding="4,6">
              <StackPanel Orientation="Horizontal">
                <Button x:Name="btnApplyAll" Content="Aplicar Tudo"
                        Style="{StaticResource ActionButtonStyle}"
                        Height="34" Width="140"/>
                <Button x:Name="btnUndoAll" Content="Reverter Tudo"
                        Style="{StaticResource DangerButtonStyle}"
                        Height="34" Width="140"/>
              </StackPanel>
            </Border>
          </Grid>
    
          <!-- Content panels -->
          <Grid Grid.Row="2" Margin="12,0,12,12">
            <!-- Instalação -->
            <ScrollViewer x:Name="panelInstall" VerticalScrollBarVisibility="Auto"
                          Background="{StaticResource PanelBrush}">
              <StackPanel Margin="12,8">
                <Label Style="{StaticResource CatLabel}" Content="Programas via Winget"/>
                <Label Style="{StaticResource SubLabel}"
                       Content="Selecione os programas essenciais"/>
                <CheckBox x:Name="chk_powershell7" Content="PowerShell 7"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_notepadpp" Content="Notepad++"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_chrome" Content="Google Chrome"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_anydesk" Content="AnyDesk"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_winrar" Content="WinRAR"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_7zip" Content="7‑Zip"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_vcredist" Content="Visual C++ Redistributable"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <Separator Style="{StaticResource SepStyle}"/>
                <Label Style="{StaticResource CatLabel}" Content="Instaladores Locais"/>
                <CheckBox x:Name="chk_arcade" Content="Arcade.exe (Gtech)"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_gtech" Content="Gtech Launcher Setup"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_p3l" Content="Driver Impressora P3L"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_xboxreg" Content="Registro Xbox (.reg)"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <Separator Style="{StaticResource SepStyle}"/>
                <StackPanel Orientation="Horizontal" Margin="12,16">
                  <Button x:Name="btnInstallSelected" Content="Instalar Selecionados"
                          Style="{StaticResource ActionButtonStyle}"
                          Height="38" Width="220"/>
                  <Button x:Name="btnSelectAllInstall" Content="Selecionar Todos"
                          Style="{StaticResource ActionButtonStyle}"
                          Height="38" Width="180" Background="#333333"/>
                </StackPanel>
              </StackPanel>
            </ScrollViewer>
    
            <!-- Tweaks -->
            <ScrollViewer x:Name="panelTweaks" VerticalScrollBarVisibility="Auto"
                          Visibility="Collapsed"
                          Background="{StaticResource PanelBrush}">
              <StackPanel Margin="12,8">
                <Label Style="{StaticResource CatLabel}" Content="Remover Bloatware (Apps)"/>
                <CheckBox x:Name="chk_rm_edge" Content="Microsoft Edge"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_onedrive" Content="OneDrive"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_teams" Content="Microsoft Teams"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_xbox" Content="Xbox + GameBar + DVR"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_bing" Content="Bing News / Weather"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_clipchamp" Content="Clipchamp"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_solitaire" Content="Solitaire Collection"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_zune" Content="Zune Music / Video"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_maps" Content="Maps / Alarms / SoundRecorder"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_todos" Content="Todos / People / YourPhone"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_rm_feedback" Content="FeedbackHub / GetHelp"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <Separator Style="{StaticResource SepStyle}"/>
                <Label Style="{StaticResource CatLabel}" Content="Serviços do Sistema"/>
                <CheckBox x:Name="chk_svc_diagtrack" Content="DiagTrack (Telemetria)"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_svc_sysmain" Content="SysMain (Superfetch)"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_svc_wsearch" Content="WSearch (Indexação)"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_svc_fax" Content="Fax Service"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_svc_geo" Content="Geolocation Service"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_svc_dlt" Content="Distributed Link Tracking"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <Separator Style="{StaticResource SepStyle}"/>
                <Label Style="{StaticResource CatLabel}" Content="Tarefas Agendadas"/>
                <CheckBox x:Name="chk_task_ceip" Content="Customer Experience (CEIP)"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_task_appraiser" Content="Compatibility Appraiser"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_task_diag" Content="Disk Diagnostic Collector"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_task_location" Content="Location Notifications"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <Separator Style="{StaticResource SepStyle}"/>
                <Label Style="{StaticResource CatLabel}" Content="Tweaks de Registro"/>
                <CheckBox x:Name="chk_reg_gamedvr" Content="Desativar GameDVR / GameBar"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_reg_cortana" Content="Desativar Cortana"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_reg_telemetry" Content="Desativar Telemetria"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_reg_clipboard" Content="Desativar Clipboard History"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <CheckBox x:Name="chk_reg_explorerads" Content="Desativar Ads no Explorer"
                          Style="{StaticResource ToggleSwitchStyle}" IsChecked="True"/>
                <Separator Style="{StaticResource SepStyle}"/>
                <StackPanel Orientation="Horizontal" Margin="12,16">
                  <Button x:Name="btnApplyTweaks" Content="Aplicar Tweaks"
                          Style="{StaticResource ActionButtonStyle}"
                          Height="38" Width="180"/>
                  <Button x:Name="btnUndoAllTweaks" Content="Reverter Tweaks"
                          Style="{StaticResource DangerButtonStyle}"
                          Height="38" Width="180"/>
                </StackPanel>
              </StackPanel>
            </ScrollViewer>
    
            <!-- Configurações -->
            <ScrollViewer x:Name="panelConfig" VerticalScrollBarVisibility="Auto"
                          Visibility="Collapsed"
                          Background="{StaticResource PanelBrush}">
              <StackPanel Margin="12,8">
                <Label Style="{StaticResource CatLabel}" Content="Presets de Debloat"/>
                <StackPanel Orientation="Horizontal" Margin="12,8">
                  <Button x:Name="btnPresetMinimal" Content="Minimal"
                          Style="{StaticResource ActionButtonStyle}"
                          Width="130" Height="36" Background="#333333"/>
                  <Label Content="Básico: serviços + telemetria"
                         Style="{StaticResource SubLabel}"
                         VerticalAlignment="Center" Margin="12,0"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" Margin="12,4">
                  <Button x:Name="btnPresetStandard" Content="Standard"
                          Style="{StaticResource ActionButtonStyle}"
                          Width="130" Height="36" Background="#333333"/>
                  <Label Content="Completo: debloat + privacidade + performance"
                         Style="{StaticResource SubLabel}"
                         VerticalAlignment="Center" Margin="12,0"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" Margin="12,4">
                  <Button x:Name="btnPresetAdvanced" Content="Advanced"
                          Style="{StaticResource ActionButtonStyle}"
                          Width="130" Height="36" Background="#C62828"/>
                  <Label Content="TUDO (use com cuidado)" Style="{StaticResource SubLabel}"
                         VerticalAlignment="Center" Margin="12,0"/>
                </StackPanel>
                <Separator Style="{StaticResource SepStyle}"/>
                <Label Style="{StaticResource CatLabel}" Content="Importar / Exportar Config"/>
                <StackPanel Orientation="Horizontal" Margin="12,8">
                  <Button x:Name="btnImportConfig" Content="Importar"
                          Style="{StaticResource ActionButtonStyle}"
                          Width="160" Height="36" Background="#333333"/>
                  <Button x:Name="btnExportConfig" Content="Exportar"
                          Style="{StaticResource ActionButtonStyle}"
                          Width="160" Height="36" Background="#333333"/>
                </StackPanel>
                <Separator Style="{StaticResource SepStyle}"/>
                <Label Style="{StaticResource CatLabel}" Content="Sistema"/>
                <StackPanel Orientation="Horizontal" Margin="12,8">
                  <Button x:Name="btnCreateRestore" Content="Criar Restore Point"
                          Style="{StaticResource ActionButtonStyle}"
                          Width="220" Height="36" Background="#333333"/>
                  <Button x:Name="btnSystemRepair" Content="Reparar Sistema (sfc+DISM)"
                          Style="{StaticResource ActionButtonStyle}"
                          Width="220" Height="36" Background="#333333"/>
                </StackPanel>
                <Button x:Name="btnPowerShell" Content="Abrir PowerShell"
                        Style="{StaticResource ActionButtonStyle}"
                        Width="220" Height="36" Background="#333333"
                        HorizontalAlignment="Left" Margin="12,4"/>
                <Separator Style="{StaticResource SepStyle}"/>
                <Label Style="{StaticResource CatLabel}" Content="Sobre"/>
                <TextBlock Foreground="#F7F7F7" FontSize="12" Opacity="0.85"
                           Margin="16,4" TextWrapping="Wrap">
    Totem v1.0 – Automação para Quiosques Gtech Arcade
    Desenvolvido por: Windson Carlos
                </TextBlock>
              </StackPanel>
            </ScrollViewer>
          </Grid>
        </Grid>
      </Border>
    </Window>
"@
    
#   ---------- Carregar XAML ----------
    $reader  = New-Object System.Xml.XmlNodeReader ([xml]$Xaml)
    $window  = [Windows.Markup.XamlReader]::Load($reader)
    
    # Lista de todos os nomes que usamos no script
    $allNames = @(
      "tabInstall","tabTweaks","tabConfig",
      "panelInstall","panelTweaks","panelConfig",
      "btnApplyAll","btnUndoAll",
      "btnInstallSelected","btnSelectAllInstall",
      "btnApplyTweaks","btnUndoAllTweaks",
      "btnPresetMinimal","btnPresetStandard","btnPresetAdvanced",
      "btnImportConfig","btnExportConfig",
      "btnCreateRestore","btnSystemRepair","btnPowerShell",
      "btnClose",
      "chk_powershell7","chk_notepadpp","chk_chrome","chk_anydesk",
      "chk_winrar","chk_7zip","chk_vcredist",
      "chk_arcade","chk_gtech","chk_p3l","chk_xboxreg",
      "chk_rm_edge","chk_rm_onedrive","chk_rm_teams","chk_rm_xbox",
      "chk_rm_bing","chk_rm_clipchamp","chk_rm_solitaire","chk_rm_zune",
      "chk_rm_maps","chk_rm_todos","chk_rm_feedback",
      "chk_svc_diagtrack","chk_svc_sysmain","chk_svc_wsearch",
      "chk_svc_fax","chk_svc_geo","chk_svc_dlt",
      "chk_task_ceip","chk_task_appraiser","chk_task_diag","chk_task_location",
      "chk_reg_gamedvr","chk_reg_cortana","chk_reg_telemetry",
      "chk_reg_clipboard","chk_reg_explorerads"
    )
    
    $Elements = Build-ElementsTable $window $allNames
    $missing = $allNames | Where-Object { -not $Elements[$_] }
    if ($missing.Count -gt 0) {
        $msg = "Falha ao localizar controles XAML: $($missing -join ', ')"
        Write-Host $msg -ForegroundColor Red
        Show-Popup "Erro de UI" $msg
        exit 1
    }
    Write-Host ("Elementos encontrados: {0} / {1}" -f ($Elements.Values | Where-Object { $_ } | Measure-Object).Count, $allNames.Count)
    
#    ---------- Eventos de abas ----------
    $Elements["tabInstall"].Add_Click({
        $Elements["panelInstall"].Visibility = "Visible"
        $Elements["panelTweaks"].Visibility  = "Collapsed"
        $Elements["panelConfig"].Visibility  = "Collapsed"
    })
    $Elements["tabTweaks"].Add_Click({
        $Elements["panelInstall"].Visibility = "Collapsed"
        $Elements["panelTweaks"].Visibility  = "Visible"
        $Elements["panelConfig"].Visibility  = "Collapsed"
    })
    $Elements["tabConfig"].Add_Click({
        $Elements["panelInstall"].Visibility = "Collapsed"
        $Elements["panelTweaks"].Visibility  = "Collapsed"
        $Elements["panelConfig"].Visibility  = "Visible"
    })
    
#    ----- Botão fechar e arrastar a janela -----
    $Elements["btnClose"].Add_Click({ $window.Close() })
    $window.Add_MouseLeftButtonDown({ $window.DragMove() })
    
#    ----- Selecionar todos os programas de instalação -----
    $Elements["btnSelectAllInstall"].Add_Click({
        $lista = @(
            "chk_powershell7","chk_notepadpp","chk_chrome","chk_anydesk",
            "chk_winrar","chk_7zip","chk_vcredist",
            "chk_arcade","chk_gtech","chk_p3l","chk_xboxreg"
        )
        foreach($c in $lista){ $Elements[$c].IsChecked = $true }
    })
    
#    ----- Instalar os itens selecionados -----
    $Elements["btnInstallSelected"].Add_Click({
        $resultado = @()
        $wingetMap = @{
            chk_powershell7 = "Microsoft.PowerShell"
            chk_notepadpp   = "Notepad++.Notepad++"
            chk_chrome      = "Google.Chrome"
            chk_anydesk     = "AnyDesk.AnyDesk"
            chk_winrar      = "RARLab.WinRAR"
            chk_7zip        = "7zip.7zip"
            chk_vcredist    = "Microsoft.VCRedist.2015+.x64"
        }
    
        foreach($k in $wingetMap.Keys){
            if($Elements[$k].IsChecked){
                $pkg = $wingetMap[$k]
                $ok = Invoke-Safe -Desc $pkg -Action {
                    winget install --accept-package-agreements --accept-source-agreements $pkg
                }
                $resultado += "$pkg : $(if($ok){'OK'}else{'FAIL'})"
            }
        }
    
        if($Elements["chk_arcade"].IsChecked){
            $exe = Join-Path $ProgramasPath "Arcade.exe"
            if(Test-Path $exe){
                Invoke-Safe -Desc "Arcade" -Action { Start-Process -FilePath $exe -Wait }
                $resultado += "Arcade.exe : OK"
            }else{ $resultado += "Arcade.exe : NOT FOUND" }
        }
        if($Elements["chk_gtech"].IsChecked){
            $exe = Join-Path $ProgramasPath "Gtech Arcade Launcher Setup.exe"
            if(Test-Path $exe){
                Invoke-Safe -Desc "Gtech" -Action { Start-Process -FilePath $exe -Wait }
                $resultado += "Gtech Launcher : OK"
            }else{ $resultado += "Gtech Launcher : NOT FOUND" }
        }
        if($Elements["chk_p3l"].IsChecked){
            $exe = Join-Path $ProgramasPath "P3L_WIN_DRIVER_272.exe"
            if(Test-Path $exe){
                Invoke-Safe -Desc "P3L" -Action { Start-Process -FilePath $exe -Wait }
                $resultado += "P3L Driver : OK"
            }else{ $resultado += "P3L Driver : NOT FOUND" }
        }
        if($Elements["chk_xboxreg"].IsChecked){
            $reg = Join-Path $ProgramasPath "XBox alteracao Registro.reg"
            if(Test-Path $reg){
                Invoke-Safe -Desc "XboxReg" -Action {
                    Start-Process -FilePath regedit.exe -ArgumentList @('/s',"`"$reg`"") -Wait
                }
                $resultado += "Xbox Registry : OK"
            }else{ $resultado += "Xbox Registry : NOT FOUND" }
        }
    
        Show-Popup "Resultado da Instalação" ($resultado -join "`n")
    })
    
#    ----- Aplicar Tweaks -----
    $Elements["btnApplyTweaks"].Add_Click({
        $out = @()
    
        # ---- Remover apps bloat ----
        $apps = @()
        if($Elements["chk_rm_edge"].IsChecked){
            $apps += "Microsoft.Edge","Microsoft.EdgeWebView2Runtime"
        }
        if($Elements["chk_rm_onedrive"].IsChecked){ $apps += "Microsoft.OneDrive" }
        if($Elements["chk_rm_teams"].IsChecked){ $apps += "Microsoft.Teams" }
        if($Elements["chk_rm_xbox"].IsChecked){
            $apps += "Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay","Microsoft.GamingApp"
        }
        if($Elements["chk_rm_bing"].IsChecked){
            $apps += "Microsoft.BingNews","Microsoft.BingWeather"
        }
        if($Elements["chk_rm_clipchamp"].IsChecked){ $apps += "Clipchamp.Clipchamp" }
        if($Elements["chk_rm_solitaire"].IsChecked){ $apps += "Microsoft.MicrosoftSolitaireCollection" }
        if($Elements["chk_rm_zune"].IsChecked){ $apps += "Microsoft.ZuneMusic","Microsoft.ZuneVideo" }
        if($Elements["chk_rm_maps"].IsChecked){
            $apps += "Microsoft.WindowsAlarms","Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder"
        }
        if($Elements["chk_rm_todos"].IsChecked){
            $apps += "Microsoft.Todos","Microsoft.People","Microsoft.YourPhone"
        }
        if($Elements["chk_rm_feedback"].IsChecked){
            $apps += "Microsoft.WindowsFeedbackHub","Microsoft.GetHelp"
        }
        foreach($a in $apps){
            Invoke-Safe -Desc $a -Action {
                winget uninstall --disable-interactivity --accept-source-agreements $a
            }
        }
        $out += "Apps removidos: $($apps.Count)"
    
        # ---- Desativar serviços ----
        $svcs = @()
        if($Elements["chk_svc_diagtrack"].IsChecked){ $svcs += "DiagTrack" }
        if($Elements["chk_svc_sysmain"].IsChecked){ $svcs += "SysMain" }
        if($Elements["chk_svc_wsearch"].IsChecked){ $svcs += "WSearch" }
        if($Elements["chk_svc_fax"].IsChecked){ $svcs += "Fax" }
        if($Elements["chk_svc_geo"].IsChecked){ $svcs += "lfsvc" }
        if($Elements["chk_svc_dlt"].IsChecked){ $svcs += "TrkWks" }
    
        foreach($s in $svcs){
            Invoke-Safe -Desc $s -Action {
                Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
                Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
            }
        }
        $out += "Serviços desativados: $($svcs.Count)"
    
        # ---- Tarefas agendadas ----
        $tasks = @()
        if($Elements["chk_task_ceip"].IsChecked){
            $tasks += "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
        }
        if($Elements["chk_task_appraiser"].IsChecked){
            $tasks += "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
        }
        if($Elements["chk_task_diag"].IsChecked){
            $tasks += "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
        }
        if($Elements["chk_task_location"].IsChecked){
            $tasks += "\Microsoft\Windows\Location\Notifications"
        }
        foreach($t in $tasks){
            $taskName = Split-Path -Path $t -Leaf
            $taskPath = Split-Path -Path $t -Parent
            if ([string]::IsNullOrWhiteSpace($taskPath)) {
                $taskPath = "\"
            } else {
                $taskPath = "\" + $taskPath.Trim('\') + "\"
            }
            Invoke-Safe -Desc $t -Action {
                Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
            }
        }
        $out += "Tarefas desativadas: $($tasks.Count)"
    
        # ---- Registro ----
        if($Elements["chk_reg_gamedvr"].IsChecked){
            Invoke-Safe -Desc "RegGameBar" -Action {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'ShowStartupPanel' -Value 0 -ErrorAction SilentlyContinue
            }
            Invoke-Safe -Desc "RegGameDVR" -Action {
                Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -ErrorAction SilentlyContinue
            }
            $out += "Reg GameDVR ok"
        }
        if($Elements["chk_reg_cortana"].IsChecked){
            Invoke-Safe -Desc "RegCortana" -Action {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0 -ErrorAction SilentlyContinue
            }
            $out += "Reg Cortana ok"
        }
        if($Elements["chk_reg_telemetry"].IsChecked){
            Invoke-Safe -Desc "RegTelemetry" -Action {
                New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Force -ErrorAction SilentlyContinue | Out-Null
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -ErrorAction SilentlyContinue
            }
            $out += "Reg Telemetry ok"
        }
        if($Elements["chk_reg_clipboard"].IsChecked){
            Invoke-Safe -Desc "RegClipboard" -Action {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value 0 -ErrorAction SilentlyContinue
            }
            $out += "Reg Clipboard ok"
        }
        if($Elements["chk_reg_explorerads"].IsChecked){
            Invoke-Safe -Desc "RegExplorerAds" -Action {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Value 0 -ErrorAction SilentlyContinue
            }
            $out += "Reg ExplorerAds ok"
        }
    
        Show-Popup "Tweaks Aplicados" ($out -join "`n")
    })
    
#    ----- Reverter Tweaks -----
    $Elements["btnUndoAllTweaks"].Add_Click({
        $out = @()
        foreach($s in @("DiagTrack","SysMain","WSearch","Fax","lfsvc","TrkWks")){
            Invoke-Safe -Desc "Undo $s" -Action {
                Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
            }
        }
        Invoke-Safe -Desc "UndoRegGameBar" -Action {
            Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'ShowStartupPanel' -ErrorAction SilentlyContinue
        }
        Invoke-Safe -Desc "UndoRegTelemetry" -Action {
            Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
        }
        $out += "Serviços e registry revertidos"
        Show-Popup "Tweaks Revertidos" ($out -join "`n")
    })
    
#    ----- Presets -----
    function Set-Preset{
        param([hashtable]$map)
        foreach($k in $map.Keys){
            if($Elements[$k]){ $Elements[$k].IsChecked = $map[$k] }
        }
    }
    $Elements["btnPresetMinimal"].Add_Click({
        Set-Preset @{
            chk_rm_edge=$true;   chk_rm_onedrive=$true;   chk_rm_teams=$true;   chk_rm_xbox=$true;
            chk_rm_bing=$true;   chk_rm_clipchamp=$true;  chk_rm_solitaire=$true; chk_rm_zune=$true;
            chk_rm_maps=$false;  chk_rm_todos=$false;    chk_rm_feedback=$true;
            chk_svc_diagtrack=$true; chk_svc_sysmain=$true; chk_svc_wsearch=$true;
            chk_svc_fax=$false;   chk_svc_geo=$false;    chk_svc_dlt=$false;
            chk_task_ceip=$true;  chk_task_appraiser=$false; chk_task_diag=$false; chk_task_location=$false;
            chk_reg_gamedvr=$true; chk_reg_cortana=$true; chk_reg_telemetry=$true;
            chk_reg_clipboard=$false; chk_reg_explorerads=$false
        }
        Show-Popup "Preset Minimal" "Aplicado – vá à aba Tweaks e clique em Aplicar."
    })
    $Elements["btnPresetStandard"].Add_Click({
        Set-Preset @{
            chk_rm_edge=$true;   chk_rm_onedrive=$true;   chk_rm_teams=$true;   chk_rm_xbox=$true;
            chk_rm_bing=$true;   chk_rm_clipchamp=$true;  chk_rm_solitaire=$true; chk_rm_zune=$true;
            chk_rm_maps=$true;   chk_rm_todos=$true;     chk_rm_feedback=$true;
            chk_svc_diagtrack=$true; chk_svc_sysmain=$true; chk_svc_wsearch=$true;
            chk_svc_fax=$true;   chk_svc_geo=$true;      chk_svc_dlt=$true;
            chk_task_ceip=$true;  chk_task_appraiser=$true; chk_task_diag=$true; chk_task_location=$true;
            chk_reg_gamedvr=$true; chk_reg_cortana=$true; chk_reg_telemetry=$true;
            chk_reg_clipboard=$true; chk_reg_explorerads=$true
        }
        Show-Popup "Preset Standard" "Aplicado – vá à aba Tweaks e clique em Aplicar."
    })
    $Elements["btnPresetAdvanced"].Add_Click({
        $todos = @(
            "chk_rm_edge","chk_rm_onedrive","chk_rm_teams","chk_rm_xbox",
            "chk_rm_bing","chk_rm_clipchamp","chk_rm_solitaire","chk_rm_zune",
            "chk_rm_maps","chk_rm_todos","chk_rm_feedback",
            "chk_svc_diagtrack","chk_svc_sysmain","chk_svc_wsearch",
            "chk_svc_fax","chk_svc_geo","chk_svc_dlt",
            "chk_task_ceip","chk_task_appraiser","chk_task_diag","chk_task_location",
            "chk_reg_gamedvr","chk_reg_cortana","chk_reg_telemetry",
            "chk_reg_clipboard","chk_reg_explorerads"
        )
        $map = @{}
        foreach($k in $todos){ $map[$k] = $true }
        Set-Preset $map
        Show-Popup "Preset Advanced" "Todas as opções ativadas – use com EXTREMA cautela!"
    })
    
#    ----- Importar / Exportar Config ----------
    $Elements["btnImportConfig"].Add_Click({
        $dlg = New-Object Microsoft.Win32.OpenFileDialog
        $dlg.Filter = "JSON (*.json)|*.json|All files (*.*)|*.*"
        if($dlg.ShowDialog()){
            Show-Popup "Importar Config" "Arquivo escolhido: $($dlg.FileName)"
            # Aqui você pode ler o JSON e aplicar os estados – deixado como placeholder
        }
    })
    $Elements["btnExportConfig"].Add_Click({
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Filter = "JSON (*.json)|*.json"
        $dlg.FileName = "totem-config.json"
        if($dlg.ShowDialog()){
            Show-Popup "Exportar Config" "Arquivo salvo: $($dlg.FileName)"
            # Placeholder para gerar JSON com estados atuais
        }
    })
    
#    ----- Botões de ação global -----
    $Elements["btnCreateRestore"].Add_Click({
        Invoke-Safe -Desc "RestorePoint" -Action {
            Checkpoint-Computer -Description 'Totem' -RestorePointType 'MODIFY_SETTINGS'
        }
        Show-Popup "Ponto de Restauração" "Criado com sucesso."
    })
    $Elements["btnSystemRepair"].Add_Click({
        Invoke-Safe -Desc "SFC" -Action { sfc /scannow }
        Invoke-Safe -Desc "DISM" -Action { DISM /Online /Cleanup-Image /RestoreHealth }
        Show-Popup "Reparo do Sistema" "Comandos executados – verifique a console para detalhes."
    })
    $Elements["btnPowerShell"].Add_Click({
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass"
    })
    
#    ----- Aplicar tudo / Reverter tudo (grupo) -----
    $Elements["btnApplyAll"].Add_Click({
        $Elements["btnInstallSelected"].RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
        Start-Sleep -Seconds 1
        $Elements["btnApplyTweaks"].RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
    })
    $Elements["btnUndoAll"].Add_Click({
        $Elements["btnUndoAllTweaks"].RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
    })
    
#    ----- Exibir a GUI -----
    $window.ShowDialog() | Out-Null
