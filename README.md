# Totem Automacao

Automacao de preparacao de estacoes de quiosque Gtech em Windows, com interface WPF e fluxo unico para instalacao de apps, tweaks e configuracoes operacionais.

## Execucao em Linha Unica (cliente)

Depois de publicar o pacote na Release do GitHub (passos abaixo), envie apenas este comando para o cliente:

```powershell
irm https://raw.githubusercontent.com/windson3/InstTotem/main/i.ps1 | iex
```

Opcao para CMD (sem abrir PowerShell manualmente):

```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/windson3/InstTotem/main/i.ps1 | iex"
```

Para usar o bootstrap direto (com parametros), mantenha:

```powershell
irm https://raw.githubusercontent.com/windson3/InstTotem/main/bootstrap/Start-InstTotem.ps1 | iex
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
|   |-- maintenance/
|   |   |-- ListarProgramasEAtualizacoes.ps1
|   |   |-- LimparEInstalar.ps1
|   |   |-- List-Apaga.ps1
|   |   `-- Instalar-Arcade.bat
|   |-- release/
|   |   `-- New-InstTotemPackage.ps1 # Gera ZIP + SHA256 para Release
|   |-- tests/
|   |   `-- test_xaml.ps1
|   |-- tools/
|   |   |-- generate_skills_pdf.js
|   |   `-- validate_ps1.py
|   `-- legacy/
|       `-- SetupTotemGUI.ps1
|-- ui/
|   |-- TotemUI.xaml
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

## Power Automate Desktop

Para evitar `WindowNotFoundException`, nao use a acao **Pressionar botao da janela** no Power Automate Desktop. Execute o fluxo por PowerShell:

```powershell
powershell.exe -Sta -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Run-InstTotemAuto.ps1"
```

Opcao remota sem clique:

```powershell
$s = irm https://raw.githubusercontent.com/windson3/InstTotem/main/bootstrap/Start-InstTotem.ps1
& ([scriptblock]::Create($s)) -MainScriptArgumentList @('-AutoRunAll','-CloseWhenDone')
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

4. O bootstrap remoto tenta Release e, se nao existir, usa fallback no branch:
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
- O bootstrap extrai em `C:\ProgramData\InstTotem\releases\<timestamp>` e executa o script principal.
- O bootstrap agora mostra progresso de download por padrao (interativo). Para modo silencioso, use o parametro `-NoDownloadProgress` ao executar `Start-InstTotem.ps1` diretamente.
- A pasta `references/` esta ignorada no git para evitar conflito com repositorios embutidos.
