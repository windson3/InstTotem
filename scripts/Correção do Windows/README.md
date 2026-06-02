# 🎯 AUTOMAÇÃO PLAYWRIGHT CORPORATIVA - CERTEIRO APP

<div align="center">

[![Status dos Testes](https://img.shields.io/badge/tests-11%2F11%20passing-brightgreen?style=for-the-badge)](https://github.com)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green?style=for-the-badge&logo=node.js)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3.3-blue?style=for-the-badge&logo=typescript)](https://www.typescriptlang.org)
[![Playwright](https://img.shields.io/badge/Playwright-1.60%2B-critical?style=for-the-badge&logo=playwright)](https://playwright.dev)
[![Workers](https://img.shields.io/badge/workers-2%20(configurável)-orange?style=for-the-badge)](#)
[![Cross-Browser](https://img.shields.io/badge/browsers-Chromium%20%7C%20Firefox%20%7C%20WebKit-purple?style=for-the-badge)](#)

**Sistema de automação end-to-end para testes do Certeiro App**  
Desenvolvido pelo **Suporte N2 OfficeCom**

[📖 Manual Completo](docs/MANUAL_COMPLETO.md) • [📚 Guia de Estudo](docs/GUIA_DE_ESTUDO.md) • [🚀 Início Rápido](#-início-rápido)

</div>

---

## 📑 Sumário

- [3. Introdução](#3-introdução)
- [4. Informações Técnicas](#4-informações-técnicas)
- [5. Início Rápido](#5-início-rápido)
- [6. Novidades da Versão 1.1](#6-novidades-da-versão-11)
- [7. Próximos Passos](#7-próximos-passos)
- [8. Equipe](#8-equipe)

---

## 3 INTRODUÇÃO

### 3.1 Objetivo

O **Certeiro App - Automação Playwright Corporativa** é um framework completo de testes end-to-end desenvolvido com **Playwright** e **TypeScript** para automação profissional da plataforma Certeiro (sistema de apostas esportivas).

### 3.2 Status do Projeto

- ✅ **11/11 testes passando** (E2E + Smoke + Profile)
- ✅ **17 testes unitários** para utilitários de email
- ✅ **Múltiplos navegadores**: Chromium (mobile/desktop), Firefox, WebKit
- ✅ **3 OTP Providers**: Mock, Mailbox, Manual
- ✅ **Page Object Model**: Login, Dashboard, Bets, Account, Withdrawals
- ✅ **Fixtures reutilizáveis**: `fixtures/base.ts` com auth automático
- ✅ **Configuração centralizada**: timeouts, delays, caminhos em `config/`
- ✅ **Cross-browser**: Smoke tests rodam em Chromium, Firefox e WebKit
- ✅ **Qualidade**: ESLint + Prettier configurados

### 3.3 Características Principais

| Aspecto | Detalhe |
|---------|---------|
| **Testes E2E** | 6 testes (login, bets, delete-account, exploração) |
| **Testes Unitários** | 17 (utils/email.ts) |
| **Testes Smoke** | 3 (login, dashboard, navegação) |
| **Testes Profile** | 2 (perfil, conta) |
| **Navegadores** | Chromium, Firefox, WebKit |
| **Dispositivos** | Pixel 7 (padrão), iPhone 13, Galaxy S9+ |
| **Workers** | 2 (configurável via env PLAYWRIGHT_WORKERS) |
| **Autenticação** | Fixture automática + storageState |
| **Arquitetura** | Page Object Model + Factory + Strategy |
| **Exploração** | Automática, Manual, Recorder |

---

## 4 INFORMAÇÕES TÉCNICAS

### 4.1 Stack Tecnológico

| Tecnologia | Versão | Propósito |
|-----------|--------|-----------|
| **Playwright** | 1.60+ | Framework de testes E2E |
| **TypeScript** | 5.3.3 | Linguagem com tipagem estática |
| **Node.js** | 18+ (ver `.nvmrc`) | Runtime JavaScript |
| **npm** | 9+ | Gerenciador de pacotes |
| **Tesseract.js** | 5.0.0 | OCR para extração de texto |
| **ESLint** | 9.x | Análise estática de código |
| **Prettier** | 3.x | Formatação consistente |

### 4.2 Pré-requisitos

**Obrigatórios:**
- Node.js 18.0.0 ou superior
- npm 9.0.0 ou superior
- Windows 10+, macOS 10.14+, ou Linux (Ubuntu 18.04+)
- Conexão à internet (para download de navegadores)

**Verificação rápida:**
```bash
node --version    # v18.x.x ou superior
npm --version     # 9.x.x ou superior
```

### 4.3 Estrutura de Diretórios (v1.1)

```
certeiro-app-teste/
├── config/                       # Configurações centralizadas
│   ├── app-config.ts             # Agregador central
│   ├── constants.ts              # Constantes (Email, OTP, UI)
│   ├── env.ts                    # Leitura segura de variáveis de ambiente
│   ├── projects.ts               # Definições centralizadas de projetos
│   ├── test-settings.ts          # Ajustes de testes
│   ├── timeouts.ts               # Timeouts e delays
│   └── urls.ts                   # URLs e caminhos
├── data/                         # Dados persistentes (gerado)
│   └── auth.json                 # Estado de autenticação
├── docs/                         # Documentação
│   ├── GUIA_DE_ESTUDO.md         # Referência técnica
│   ├── MANUAL_COMPLETO.md        # Manual completo
│   ├── TUTORIAL_CERTEIRO_APP.docx  # Tutorial Word com screenshots
│   └── tutorial/                 # Screenshots do tutorial (9 imagens)
├── fixtures/                     # Fixtures Playwright
│   └── base.ts                   # Fixtures reutilizáveis (auth, pages, setup)
├── pages/                        # Page Objects (POM)
│   ├── AccountPage.ts            # Gerenciamento de conta/perfil
│   ├── BetsPage.ts               # Fluxo de palpites (NOVO)
│   ├── DashboardPage.ts          # Dashboard e navegação
│   ├── LoginPage.ts              # Login e autenticação
│   ├── WithdrawalsPage.ts        # Carteira e saque
│   └── components/
│       └── OtpModal.ts           # Componente de OTP
├── providers/otp/                # OTP Providers
│   ├── MailboxOtpProvider.ts
│   ├── ManualOtpProvider.ts
│   ├── MockOtpProvider.ts
│   ├── OtpProvider.ts            # Interface
│   └── OtpProviderFactory.ts     # Factory
├── scripts/                      # Scripts auxiliares
│   ├── check-auth.mjs            # Verificador de autenticação
│   ├── debug-otp.ts/js           # Debug de OTP
│   ├── explore/                  # Exploradores
│   ├── generators/               # Geradores
│   └── validate-otp-timing.js    # Validador de timing OTP
├── tests/                        # Suite de testes
│   ├── auth/
│   │   └── login.spec.ts         # Login com retry e OTP
│   ├── debug/
│   │   └── otp-dom.spec.ts       # Diagnóstico OTP
│   ├── exploration/              # Testes de exploração automática
│   ├── profile/                  # NOVOS testes de perfil
│   │   ├── account.spec.ts       # Navegação até Conta
│   │   └── profile.spec.ts       # Acesso ao perfil
│   ├── regression/
│   │   ├── bets.spec.ts          # Palpites (refatorado, 321 linhas)
│   │   ├── delete-account.spec.ts
│   │   └── helpers/
│   ├── smoke/                    # NOVOS testes smoke
│   │   ├── dashboard.smoke.spec.ts   # Dashboard + abas
│   │   ├── login.smoke.spec.ts       # Página de login
│   │   └── navigation.smoke.spec.ts  # Navegação entre abas
│   ├── unit/                     # NOVOS testes unitários
│   │   └── email.spec.ts         # 17 testes para utils/email.ts
│   └── template.spec.ts          # Template para novos testes
├── utils/                        # Utilitários
│   ├── email.ts                  # Extração de OTP e email
│   ├── logger.ts                 # Sistema de logs
│   └── ocr.ts                    # OCR via Tesseract
├── reports/                      # Relatórios (gerado)
│   ├── html/
│   ├── json/
│   ├── screenshots/
│   ├── traces/
│   └── videos/
├── .env.example                  # Template de variáveis de ambiente
├── .gitignore                    # Arquivos ignorados
├── .nvmrc                        # Versão do Node (18)
├── .prettierrc                   # Config Prettier
├── eslint.config.mjs             # Config ESLint
├── package.json                  # Dependências e scripts
├── playwright.config.ts          # Config Playwright (projetos centralizados)
├── README.md                     # Este arquivo
└── tsconfig.json                 # Config TypeScript
```

### 4.4 Configuração Centralizada

O arquivo `config/app-config.ts` é a fonte única de configuração operacional. Todo timeout, delay, caminho de autenticação, limite de tentativa, URL e dispositivo deve ser ajustado nele.

**Regra de ouro:** não criar valores fixos em arquivos de teste, Page Objects ou scripts. Use `CONFIG.chave` sempre.

### 4.5 Projetos Playwright (Centralizados)

As definições de projeto foram movidas para `config/projects.ts` para evitar repetição:

| Projeto | Execução | Navegador | Descrição |
|---------|----------|-----------|-----------|
| `login` | Automática | Chromium Mobile | Gera auth.json |
| `bets` | Automática | Chromium Mobile | Palpites em partidas |
| `smoke` | Automática | Chromium Mobile | Testes rápidos críticos |
| `regression` | Automática | Chromium Mobile | Suite completa |
| `profile` | Automática | Chromium Mobile | Perfil e configurações |
| `chromium-mobile` | Automática | Chromium Mobile | Exploração mobile |
| `chromium-desktop` | Automática | Chromium Desktop | Smoke em desktop |
| `webkit` | Automática | WebKit Desktop | Validação cross-browser |
| `firefox` | Automática | Firefox Desktop | Validação cross-browser |
| `template` | Manual | Chromium Mobile | Template para novos testes |
| `delete-account` | **Manual** | Chromium Mobile | ⚠️ Destrutivo |

---

## 5 INÍCIO RÁPIDO

### 5.1 Instalação

```bash
# 1. Clonar e entrar no diretório
git clone <url-do-repositorio>
cd certeiro-app-teste

# 2. Instalar dependências
npm install

# 3. Configurar navegadores Playwright
npm run setup

# 4. (Opcional) Configurar variáveis de ambiente
cp .env.example .env
# Edite .env com suas credenciais

# 5. Gerar autenticação
npm run test:login
```

### 5.2 Comandos Essenciais

| Comando | Descrição |
|---------|-----------|
| `npm run test:login` | Autenticação (gera auth.json) |
| `npm test` | Todos os projetos automáticos |
| `npm run test:smoke` | Testes rápidos (funcionalidades críticas) |
| `npm run test:regression` | Suite completa de testes |
| `npm run test:bets` | Teste de palpites |
| `npm run test:profile` | Testes de perfil |
| `npm run report` | Abre relatório HTML |
| `npm run lint` | Verifica código com ESLint |
| `npm run format:fix` | Formata código com Prettier |
| `npm run typecheck` | Verifica tipos TypeScript |

### 5.3 Variáveis de Ambiente

```bash
# Provider de OTP (mock | mailbox | manual)
export OTP_PROVIDER=mock

# Dispositivo mobile (Pixel 7 | iPhone 13 | Galaxy S9+)
export MOBILE_DEVICE=Pixel 7

# Modo headless
export HEADLESS=true

# Nível de log (silent | error | warn | info | debug)
export LOG_LEVEL=info

# Workers paralelos
export PLAYWRIGHT_WORKERS=2
```

---

## 6 NOVIDADES DA VERSÃO 1.1

### 🆕 Pages
- **BetsPage.ts** — Page Object para fluxo de palpites (874 → 321 linhas no spec)
- **AccountPage.ts** — Gerenciamento de conta com múltiplos fallbacks de seletor

### 🆕 Fixtures
- **fixtures/base.ts** — `test`, `testWithPages`, `testWithAuth`, `loggedInPage`
- Setup automático: `printConfig`, `ensureDataDir`, `ensureCleanAuth`

### 🆕 Testes
- **3 testes Smoke** — login, dashboard, navegação entre abas
- **2 testes Profile** — acesso ao perfil, navegação até Conta
- **17 testes Unitários** — email.ts (extractValidationCode, isValidOtpCode, etc.)

### 🆕 Cross-Browser
- WebKit e Firefox adicionados para testes Smoke
- Projeto `chromium-desktop` para debugging em viewport grande

### 🆕 Qualidade
- ESLint + Prettier configurados
- `.env.example`, `.gitignore`, `.nvmrc`
- Scripts npm padronizados com `npx` em vez de caminhos longos

### 🔧 Refatorações
- `bets.spec.ts`: 874 → 321 linhas, zero tipos `any`
- `LoginPage.ts`: Web-First Assertions, menos `waitForTimeout`
- `DashboardPage.ts`: Navegação SPA-friendly (pela raiz)
- `playwright.config.ts`: Projetos centralizados em `config/projects.ts`
- Detecção de OTP inválido com retry automático (`LOGIN_AUTH_ERROR`)

---

## 7 PRÓXIMOS PASSOS

Para operacionalizar completamente o projeto, consulte:

### 📖 **Manual Completo** [`docs/MANUAL_COMPLETO.md`](docs/MANUAL_COMPLETO.md)
Guia prático com instalação detalhada, configuração de OTP Providers, execução de testes, depuração e solução de erros.

### 📚 **Guia de Estudo** [`docs/GUIA_DE_ESTUDO.md`](docs/GUIA_DE_ESTUDO.md)
Referência técnica com conceitos (POM, Factory), Playwright API, implementação de Page Objects, exemplos práticos e onboarding.

### 📘 **Tutorial Word** [`docs/TUTORIAL_CERTEIRO_APP.docx`](docs/TUTORIAL_CERTEIRO_APP.docx)
Tutorial completo gerado automaticamente com screenshots de todas as páginas do app.

---

## 8 EQUIPE

**Desenvolvido por**: Suporte N2 OfficeCom  
**Lead Developer**: Windson Carlos  
**Gerente**: Jairo Silva

**Integrantes:**
- Arthur Igor
- João Marcos
- Gabriel Raimundo
- Hianto

**Status**: 🔄 Projeto em Andamento  
**Última atualização**: 18 de maio de 2026
