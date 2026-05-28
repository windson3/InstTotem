# Totem Automacao

Automacao de preparacao de estacoes de quiosque Gtech em Windows, com interface WPF e fluxo unico para instalacao de apps, tweaks e configuracoes operacionais.

## Execucao em Linha Unica (cliente)

Depois de publicar o pacote na Release do GitHub (passos abaixo), envie apenas este comando para o cliente:

```powershell
irm https://raw.githubusercontent.com/windson3/InstTotem/main/bootstrap/Start-InstTotem.ps1 | iex
```

Opcao para CMD (sem abrir PowerShell manualmente):

```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/windson3/InstTotem/main/bootstrap/Start-InstTotem.ps1 | iex"
```

## Visao Geral

Este projeto centraliza em um unico script a rotina de preparacao do Totem:
- Instalacao de aplicativos via `winget`
- Execucao de instaladores locais (`Gtech Arcade Launcher Setup.exe`, `vcredist_2015_2019_x64.exe`, `P3L_WIN_DRIVER_272.exe`, `.reg`, etc.)
- Aplicacao de tweaks de sistema
- Presets de configuracao para acelerar setup

## Estrutura do Projeto

```text
InstTotem/
|-- TotemAutomacao.ps1
|-- README.md
|-- CONTEXT.md
|-- bootstrap/
|   `-- Start-InstTotem.ps1          # Bootstrap remoto (irm | iex)
|-- assets/
|   |-- images/
|   `-- installers/
|-- scripts/
|   |-- launcher.vbs
|   |-- release/
|   |   `-- New-InstTotemPackage.ps1 # Gera ZIP + SHA256 para Release
|   |-- tests/
|   |   `-- test_xaml.ps1
|   `-- legacy/
|       `-- SetupTotemGUI.ps1
|-- ui/
|   `-- TotemGUI.xaml
|-- docs/
|   `-- adr/
`-- references/                      # referencia local (ignorada no git)
```

## Requisitos

- Windows 10 ou 11
- PowerShell 5.1+ (ou PowerShell 7)
- Permissao de Administrador
- `winget` disponivel no sistema
- Internet (para modo linha unica)

## Como Executar Localmente

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\TotemAutomacao.ps1
```

Opcao com launcher:

```powershell
wscript .\scripts\launcher.vbs
```

## Publicar para Execucao Remota

1. Gere o pacote de release:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release\New-InstTotemPackage.ps1
```

2. O script gera em `dist/`:
- `InstTotem-package.zip`
- `InstTotem-package.sha256`

3. Crie uma Release no GitHub (`windson3/InstTotem`) e anexe esses dois arquivos.

4. O bootstrap remoto baixa automaticamente:
- `https://github.com/windson3/InstTotem/releases/latest/download/InstTotem-package.zip`
- `https://github.com/windson3/InstTotem/releases/latest/download/InstTotem-package.sha256`

5. Envie ao cliente a linha unica da secao inicial.

## Testes Rapidos

Teste de parse do script principal:

```powershell
$null = [System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path .\TotemAutomacao.ps1),
  [ref]$null,
  [ref]$null
)
```

Teste de carga do XAML de referencia:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\tests\test_xaml.ps1
```

## Notas

- O runtime oficial e `TotemAutomacao.ps1`.
- O bootstrap extrai em `C:\ProgramData\InstTotem\current` e executa o script principal.
- A pasta `references/` esta ignorada no git para evitar conflito com repositorios embutidos.
