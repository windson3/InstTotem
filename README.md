# Totem Automacao

Automacao de preparacao de estacoes de quiosque Gtech em Windows, com interface WPF e fluxo unico para instalacao de apps, tweaks e configuracoes operacionais.

## Visao Geral

Este projeto centraliza em um unico script a rotina de preparacao do Totem:
- Instalacao de aplicativos via `winget`
- Execucao de instaladores locais
- Aplicacao de tweaks de sistema
- Presets de configuracao para acelerar setup

## Estrutura do Projeto

```text
InstTotem/
|-- TotemAutomacao.ps1          # Script principal (GUI WPF embutida)
|-- README.md
|-- CONTEXT.md
|-- assets/
|   |-- images/                 # Logos e imagens da interface
|   `-- installers/             # Instaladores locais (.exe, .reg, etc.)
|-- scripts/
|   |-- launcher.vbs            # Atalho para abrir o script principal oculto
|   |-- tests/
|   |   `-- test_xaml.ps1       # Smoke test do XAML externo
|   `-- legacy/
|       `-- SetupTotemGUI.ps1   # Versao antiga da GUI (referencia)
|-- ui/
|   `-- TotemGUI.xaml           # XAML de referencia para design/testes
|-- docs/
|   `-- adr/                    # Decisoes de arquitetura
`-- references/
    `-- AppRef/                 # Projetos de referencia (nao usados em runtime)
```

## Requisitos

- Windows 10 ou 11
- PowerShell 5.1+ (ou PowerShell 7)
- Permissao de Administrador
- `winget` disponivel no sistema

## Como Executar

No diretorio do projeto:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\TotemAutomacao.ps1
```

Opcao com launcher:

```powershell
wscript .\scripts\launcher.vbs
```

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

## Convencoes de Pastas

- Coloque novos instaladores em `assets/installers/`
- Coloque logos/imagens em `assets/images/`
- Coloque scripts auxiliares em `scripts/`
- Evite arquivos soltos na raiz

## Notas

- O runtime oficial e `TotemAutomacao.ps1`.
- A pasta `references/AppRef` existe para estudo/comparacao visual e tecnica.
- A GUI principal usa XAML embutido no script; `ui/TotemGUI.xaml` fica como referencia de manutencao.
