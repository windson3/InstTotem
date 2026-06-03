# 📘 OWL AGENT — GUIA COMPLETO DE SKILLS
## Referência Total de 583 Skills Instaladas

**Versão:** 2026.06.03  
**Total:** 583 skills em 18 categorias  
**Foco:** Documentação, Design, Tutoriais, Marketing Visual & Criação de Conteúdo

---

## 📋 ÍNDICE

1. [Como Usar Este Guia](#1-como-usar-este-guia)
2. [Documentação & Escrita Técnica](#2-documentação--escrita-técnica)
3. [Design & UI/UX](#3-design--uiux)
4. [Marketing & Mídias Sociais](#4-marketing--mídias-sociais)
5. [Diagramas & Visualização](#5-diagramas--visualização)
6. [Apresentações & Slides](#6-apresentações--slides)
7. [PDF & Documentos](#7-pdf--documentos)
8. [Web Development](#8-web-development)
9. [Criação de Conteúdo — Guia Prático](#9-criação-de-conteúdo--guia-prático)
10. [Workflows por Tipo de Projeto](#10-workflows-por-tipo-de-projeto)
11. [Referência Rápida — Comandos](#11-referência-rápida--comandos)
12. [Todas as Skills por Categoria](#12-todas-as-skills-por-categoria)

---

## 1. COMO USAR ESTE GUIA

### O que é uma Skill?
Uma **skill** é um pacote de instruções reutilizáveis que ensina o OWL Agent a executar tarefas específicas. Cada skill contém:
- **SKILL.md** — instruções detalhadas
- **Referências** — exemplos, padrões, checklists
- **Scripts** — automações prontas

### Como carregar uma skill:
```
skill_view(name="nome-da-skill")
```

### Como listar skills disponíveis:
```
skills_list()
```

### Como buscar skills por categoria:
```
skills_list(category="creative")
```

### Áreas de Atuação das Skills neste Guia:

| Área | Qtd | Para quê |
|---|---|---|
| 📝 Documentação & Escrita | 39 | Docs, tutoriais, blogs, wikis |
| 🎨 Design & UI/UX | 65 | Interfaces, design systems, tipografia |
| 📢 Marketing & Social | 54 | Ads, posts, conteúdo para redes |
| 📊 Diagramas & Visual | 45 | Diagramas, charts, animações, vídeo |
| 🎯 Apresentações | 4 | Slides, decks, PowerPoint |
| 📄 PDF & Documentos | 5 | Extração, edição, geração de PDFs |
| 🌐 Web Development | 363 | Sites, apps, APIs, bancos de dados |
| 🔧 Outras | 8 | Diversas |

---

## 2. DOCUMENTAÇÃO & ESCRITA TÉCNICA

### 2.1 — Framework Diátaxis (Documentação Profissional)

**`documentation-writer`** — Especialista em documentação técnica seguindo o framework Diátaxis. Cria 4 tipos de documento:
- **Tutoriais** — guiam iniciantes a um resultado prático
- **How-to Guides** — resolvem problemas específicos
- **Referência** — descrição técnica de funcionalidades
- **Explicação** — aprofunda entendimento de conceitos

**Quando usar:** documentação de software, APIs, wikis, manuais técnicos.

---

**`document-writer`** — Escrita de blogs e documentação no ecossistema Nuxt. Padrões de estilo, estrutura de conteúdo, componentes MDC.

**Quando usar:** blogs técnicos, documentação de projetos web.

---

**`code-wiki`** — Gera wiki completa com diagramas Mermaid para qualquer codebase. Inclui:
- Overview do projeto
- Arquitetura com flowchart
- Documentação por módulo
- Diagramas de classe e sequência
- Guia de primeiros passos

**Quando usar:** documentar repositórios, onboarding de devs, referência de código.

---

### 2.2 — Blogs & Artigos

**`blog-writing-guide`** — Padrões de escrita do blog de engenharia da Sentry. Voz técnica, direta, sem fluff. Inclui:
- Guia de voz e tom
- Estrutura de posts (problema → solução → trade-offs)
- SEO para conteúdo técnico
- Checklist editorial
- Padrões anti-AI (evitar linguagem genérica)

**Quando usar:** artigos técnicos, blog posts, eng deep-dives.

---

**`content-research-writer`** — Pesquisa e escreve conteúdo de alta qualidade. Combina pesquisa web com escrita estruturada.

**When usar:** conteúdo baseado em pesquisa, artigos informativos.

---

**`academic-research-writer`** — Cria documentos de pesquisa acadêmica seguindo padrões IEEE/ACM.

**When usar:** papers acadêmicos, artigos científicos, documentação formal.

---

**`research-paper-writer`** — Formal papers following IEEE/ACM format.

**When usar:** publicações acadêmicas, relatórios técnicos formais.

---

### 2.3 — Tutoriais & Guias

**`skill-writer`** — Cria, sintetiza e melhora skills de agente iterativamente.

**When usar:** criar novas skills, melhorar skills existentes.

---

**`skill-creator`** — Guia para criar skills eficazes. Estrutura, validação, melhores práticas.

**When usar:** ao criar qualquer nova skill do zero.

---

**`executive-onboarding-playbook`** — Planos de onboarding 30-60-90 dias para VPs e CPOs.

**When usar:** documentação de onboarding executivo.

---

**`executive-resume-writer`** — Cria currículos de C-suite e VP com foco em liderança estratégica.

**When usar:** currículos executivos, perfis profissionais de alto nível.

---

**`resume-bullet-writer`** — Transforma bullets fracos em declarações de impacto.

**When usar:** melhorar currículos, descrições de experiência.

---

**`writing-job-descriptions`** — Ajuda a escrever descrições de vagas eficazes.

**When usar:** criar job postings, descrições de cargo.

---

**`proposal-writer`** — Cria propostas comerciais que ganham deals.

**When usar:** propostas de negócios, pitches, orçamentos.

---

**`pr-writer`** — Cria e atualiza pull requests seguindo convenções.

**When usar:** documentação de PRs, changelogs.

---

**`asc-whats-new-writer`** — Gera release notes localizados para App Store.

**When usar:** notas de lançamento, changelogs de apps.

---

**`portfolio-case-study-writer`** — Transforma bullets de currículo em estudos de caso detalhados.

**When usar:** portfólios, case studies, apresentações de projeto.

---

**`playwriter`** — Controla o navegador Chrome via extensão Playwriter.

**When usar:** automação de browser, testes de interface.

---

**`cinematic-script-writer`** — Roteiros cinematográficos.

**When usar:** roteiros, narrativas visuais, storytelling.

---

**`script-writer`** — Roteiros para vídeos do YouTube.

**When usar:** scripts de vídeo, conteúdo audiovisual.

---

**`reels-scripting`** — Transforma Reels do Instagram em scripts próprios.

**When usar:** conteúdo para Reels, adaptação de vídeos.

---

**`songwriting-and-ai-music`** — Composição de letras e prompts para Suno AI.

**When usar:** criação musical, letras, composição com IA.

---

**`wechat-article-writer`** — Escrita de artigos para WeChat (公众号).

**When usar:** conteúdo para WeChat, mercado chinês.

---

**`xhs-note-creator`** — Cria notas para Xiaohongshu (小红书).

**When usar:** conteúdo para XHS, mercado chinês.

---

**`writer-memory`** — Sistema de memória para escritores — rastreia personagens, relações, tramas.

**When usar:** escrita criativa, narrativas longas, worldbuilding.

---

**`writing-for-interfaces`** — Escreve, revisa e melhora textos para interfaces.

**When usar:** UX copy, microtextos, labels, mensagens de erro.

---

**`writing-react-native-storybook-stories`** — Cria e edita stories do React Native Storybook.

**When usar:** documentação de componentes React Native.

---

**`writing-plans`** — Escreve planos de implementação: tarefas, caminhos, código.

**When usar:** planejamento técnico, specs de implementação.

---

**`capture-tasks-from-meeting-notes`** — Analisa notas de reunião e extrai action items.

**When usar:** reuniões, atas, acompanhamento de tarefas.

---

**`generate-status-report`** — Gera relatórios de status de projeto a partir de issues.

**When usar:** relatórios de progresso, updates de projeto.

---

**`planning-with-files`** — Usa arquivos markdown para planejamento e progresso.

**When usar:** planejamento de projetos, acompanhamento de tarefas.

---

**`one-three-one-rule`** — Framework de decisão estruturado para propostas técnicas.

**When usar:** decisões técnicas, avaliações de arquitetura.

---

**`adversarial-ux-test`** — Roleplay do usuário mais difícil e resistente a tecnologia.

**When usar:** testes de UX, identificação de problemas de usabilidade.

---

**`dogfood`** — QA exploratório de web apps — encontra bugs, evidências, relatórios.

**When usar:** testes de qualidade, identificação de bugs.

---

**`de-slop`** — Remove padrões de escrita de IA do texto.

**When usar:** limpar texto gerado por IA, humanizar conteúdo.

---

**`de-slopify`** — Remove artefatos de IA de documentação e código.

**When usar:** limpar documentação gerada por IA.

---

**`de-sloppify`** — Pipeline de limpeza de código para projetos .NET.

**When usar:** limpeza de código .NET.

---

**`humanizer`** — Humaniza texto — remove AI-isms e adiciona voz real.

**When usar:** tornar texto mais natural e humano.

---

**`translate-book-parallel`** — Traduz livros inteiros (PDF/DOCX/EPUB) para qualquer idioma.

**When usar:** tradução de livros, documentos longos.

---

**`ai-content-collaboration`** — Como humanos e IA compõem em fluxos de conteúdo.

**When usar:** workflows de conteúdo colaborativo com IA.

---

**`aibtc-news-editor`** — Editor de notícias para aibtc.news.

**When usar:** curadoria de notícias, edição de conteúdo.

---

**`after-hours-editorial-template`** — Template editorial dark-editorial de luxo.

**When usar:** layouts editoriais, apresentações visuais.

---

**`field-notes-editorial-template`** — Template de relatório "Field Notes".

**When usar:** relatórios de campo, documentação visual.

---

**`editorial-burgundy-principles-template`** — Template editorial em burgundy/blush.

**When usar:** apresentações, documentos visuais premium.

---

**`editorial-monograph`** — Monografia editorial A4 com hairline.

**When usar:** documentos editoriais, publicações.

---

**`editorial-qa`** — Framework de QA pré-publicação para conteúdo.

**When usar:** revisão de conteúdo, controle de qualidade editorial.

---

**`skill-quality-reviewer`** — Analisa skills usando método de eixo duplo.

**When usar:** revisão de qualidade de skills.

---

**`dual-axis-skill-reviewer`** — Revisão de skills com método dual-axis.

**When usar:** avaliação de skills, quality assurance.

---

**`edge-strategy-reviewer`** — Revisão crítica de drafts de estratégia.

**When usar:** revisão de documentos estratégicos.

---

**`qa-reviewer`** — Revisão de qualidade de trabalho de IA.

**When usar:** QA de conteúdo gerado por IA.

---

**`remotion-video-reviewer`** — Processo de revisão estruturado para vídeos Remotion.

**When usar:** revisão de implementações de vídeo.

---

**`remember-interactive-programming`** — Micro-prompt que lembra o agente que é interativo.

**When usar:** programação interativa, REPL.

---

### Resumo — Documentação & Escrita:

| Skill | Uso Principal |
|---|---|
| documentation-writer | Docs técnicos (Diátaxis) |
| document-writer | Blogs e docs Nuxt |
| code-wiki | Wiki de código + Mermaid |
| blog-writing-guide | Artigos técnicos |
| content-research-writer | Conteúdo com pesquisa |
| academic-research-writer | Papers acadêmicos |
| skill-writer | Criar/melhorar skills |
| proposal-writer | Propostas comerciais |
| pr-writer | Pull requests |
| de-slop / humanizer | Remover AI-isms |
| translate-book-parallel | Tradução de livros |

---

## 3. DESIGN & UI/UX

### 3.1 — Design Systems & Inteligência de Design

**`ui-ux-pro-max`** — Sistema de inteligência de design com:
- 67 estilos UI
- 161 paletas de cores
- 57 combinações de fontes
- 25 tipos de gráficos
- 99 diretrizes UX
- 161 regras de raciocínio por indústria
- Motor de busca Python integrado

**Quando usar:** gerar design systems completos, escolher paletas, tipografia, layouts.

**Exemplo de uso:**
```
"Construa uma landing page para meu spa de beleza"
→ ui-ux-pro-max gera: pattern + estilo + cores + tipografia + efeitos + anti-patterns
```

---

**`taste-design`** — Framework anti-slop com:
- Inferência de brief (lê o contexto antes de projetar)
- 3 dials: Variância / Motion / Densidade
- Mapeamento brief → design system
- Regras de layout, tipografia, cor, motion, backgrounds
- Pré-flight check rigoroso

**Quando usar:** landing pages, portfolios, sites de marketing que NÃO podem parecer IA.

---

**`impeccable-design`** — 20+ comandos de design:
- **CREATE:** craft, shape, impeccable
- **EVALUATE:** audit, critique
- **REFINE:** animate, bolder, colorize, delight, layout, overdrive, quieter, typeset
- **SIMPLIFY:** adapt, clarify, distill
- **HARDEN:** harden, onboard, optimize, polish

**Quando usar:** construir, revisar ou polir qualquer UI — landing pages, dashboards, componentes.

---

**`motion-design`** — Animação e micro-interações:
- Framework de decisão de animação
- Spring physics
- Easing curves customizadas
- Regras de performance (só transform + opacity)
- Checklist de revisão de motion
- Acessibilidade (prefers-reduced-motion)

**Quando usar:** adicionar animações, transições, micro-interações; revisar qualidade de motion.

---

**`claude-design`** — Design de artifacts HTML one-off:
- Landing pages, teasers, protótipos
- High-fidelity mockups
- Visual option boards
- Component explorations
- HTML slide decks
- Motion studies

**Quando usar:** criar protótipos HTML, mockups, decks de apresentação.

---

**`popular-web-designs`** — 54 sistemas de design reais como HTML/CSS:
- **AI/ML:** Claude, Cohere, ElevenLabs, Mistral, Ollama, RunwayML, etc.
- **Dev Tools:** Cursor, Linear, Vercel, Raycast, Sentry, Supabase, etc.
- **Infra:** Stripe, MongoDB, HashiCorp, ClickHouse, etc.
- **Design/Produtividade:** Figma, Notion, Airtable, Framer, etc.
- **Fintech:** Coinbase, Kraken, Revolut, Wise
- **Enterprise:** Apple, BMW, IBM, NVIDIA, SpaceX, Spotify

**Quando usar:** "faça parecer com Stripe/Linear/Vercel", páginas estilizadas após marcas conhecidas.

---

### 3.2 — Componentes & Layout

**`component-interface-design`** — Design de interfaces com bibliotecas de componentes e design systems.

**When usar:** design de componentes, interfaces modulares.

---

**`api-and-interface-design`** — Design estável de APIs e interfaces.

**When usar:** design de APIs, contratos de interface.

---

**`api-designer`** — Design de REST/GraphQL APIs, criação de specs OpenAPI.

**When usar:** criar specs de API, documentação de endpoints.

---

**`database-schema-designer`** — Design de schemas SQL/NoSQL robustos e escaláveis.

**When usar:** modelagem de banco de dados.

---

**`architecture-designer`** — Design de arquitetura de alto nível.

**When usar:** arquitetura de sistemas, decisões de alto nível.

---

**`architecting-solutions`** — Design de soluções técnicas e arquitetura.

**When usar:** soluções técnicas, planejamento de arquitetura.

---

**`design-team`** — Transforma o agente em equipe de design completa — 17 especialistas.

**When usar:** projetos de design completos, múltiplas especialidades.

---

**`creative-director`** — Diretor de IA criativo com autoavaliação recursiva — 20+ comandos.

**When usar:** direção criativa, projetos visuais complexos.

---

**`design-md`** — Autor/validar/exportar arquivos DESIGN.md (Google design tokens).

**When usar:** criar specs de design tokens, documentação de design system.

---

**`frontend-design`** — Interfaces frontend distintivas, production-grade.

**When usar:** criar interfaces web profissionais.

---

**`editorial-designer`** — Interfaces frontend editoriais de alta qualidade.

**When usar:** layouts editoriais, publicações digitais.

---

**`editorial`** — Layout editorial inspirado em revistas com tipografia serifada refinada.

**When usar:** layouts de publicações, artigos visuais.

---

**`web-design-guidelines`** — Revisão de código UI para conformidade com Web Interface Guidelines.

**When usar:** revisão de UI, conformidade com padrões web.

---

**`web-design-reviewer`** — Inspeção visual de sites rodando localmente.

**When usar:** revisão visual de sites, QA de design.

---

**`make-interfaces-feel-better`** — Detalhes de design-engineering que fazem interfaces funcionarem.

**When usar:** polir interfaces, melhorar UX.

---

**`user-interface-designer`** — Design de interfaces centradas no usuário.

**When usar:** design de interfaces web, wireframes, design systems.

---

**`ui-ux-designer`** — Design de interfaces, wireframes e sistemas de design.

**When usar:** design de UI/UX completo.

---

**`brand-designer`** — Identidade visual, logo design, sistemas de marca.

**When usar:** branding, identidade visual, logos.

---

**`brand-guidelines`** — Aplica cores e tipografia oficiais da Anthropic.

**When usar:** aplicar diretrizes de marca.

---

**`chart-designer`** — Design de visualizações de dados e gráficos.

**When usar:** criar gráficos, dashboards, visualizações.

---

**`template-designer`** — Seleção visual de templates para agentes de design de imagem.

**When usar:** selecionar templates de design.

---

**`elite-powerpoint-designer`** — Apresentações PowerPoint de classe mundial.

**When usar:** criar apresentações PowerPoint profissionais.

---

**`pptx-author`** — Constrói decks PowerPoint headless com python-pptx.

**When usar:** gerar apresentações PowerPoint programaticamente.

---

**`canva`** — Cria, busca, preenche e exporta designs do Canva.

**When usar:** designs no Canva, templates.

---

**`canva-branded-presentation`** — Apresentações Canva on-brand.

**When usar:** apresentações com marca no Canva.

---

**`canva-resize-for-all-social-media`** — Redimensiona designs Canva para formatos de redes sociais.

**When usar:** adaptar designs para múltiplas plataformas.

---

**`canva-translate-design`** — Traduz texto em designs Canva.

**When usar:** traduzir designs multilíngues.

---

**`figma-use`** — Uso do Figma via MCP tool (MANDATORY prerequisite).

**When usar:** trabalhar com Figma.

---

**`figma-create-new-file`** — Cria novos arquivos no Figma (MANDATORY prerequisite).

**When usar:** criar arquivos Figma.

---

**`figma-generate-design`** — Gera designs no Figma.

**When usar:** gerar designs automaticamente no Figma.

---

**`figma-generate-diagram`** — Gera diagramas no Figma (MANDATORY prerequisite).

**When usar:** criar diagramas no Figma.

---

**`figma-generate-library`** — Constrói design systems no Figma.

**When usar:** criar bibliotecas de design no Figma.

---

**`figma-code-connect`** — Cria e mantém arquivos Figma Code Connect.

**When usar:** conectar Figma a código.

---

**`figma-use-figjam`** — Usa Figma FigJam via MCP.

**When usar:** trabalhar com FigJam.

---

**`figma-use-slides`** — Usa Figma Slides via MCP.

**When usar:** criar slides no Figma.

---

**`open-pencil-design-editor`** — Alternativa open-source ao Figma com CLI e MCP.

**When usar:** design sem Figma, alternativa open-source.

---

**`sketch`** — Mockups HTML rápidos: 2-3 variantes para comparar.

**When usar:** protótipos rápidos, comparação de layouts.

---

**`pretext`** — Demos criativos com @chenglou/pretext.

**When usar:** demos interativas, protótipos criativos.

---

**`ideation`** — Gera ideias de projeto via restrições criativas.

**When usar:** brainstorming, geração de ideias.

---

**`popular-web-designs`** — 54 sistemas de design reais (Stripe, Linear, Vercel, etc.).

**When usar:** criar páginas com visual de marcas conhecidas.

---

**`gsap`** — Referência GSAP para HyperFrames.

**When usar:** animações GSAP.

---

**`hyperframes`** — Composições de vídeo baseadas em HTML, title cards animados.

**When usar:** criar vídeos, animações, title cards.

---

**`hyperframes-cli`** — CLI do HyperFrames — init, lint, inspect, preview.

**When usar:** trabalhar com HyperFrames via CLI.

---

**`hyperframes-registry`** — Instala e conecta blocos e componentes do registry.

**When usar:** gerenciar componentes HyperFrames.

---

**`touchdesigner-mcp`** — Controla TouchDesigner via MCP.

**When usar:** controlar TouchDesigner.

---

**`comfyui`** — Gera imagens, vídeo e áudio com ComfyUI.

**When usar:** geração de mídia com ComfyUI.

---

**`manim-video`** — Animações Manim CE — vídeos de matemática/algoritmos estilo 3Blue1Brown.

**When usar:** vídeos educacionais, animações matemáticas.

---

**`p5js`** — Sketches p5.js: arte generativa, shaders, 3D.

**When usar:** arte generativa, visualizações criativas.

---

**`pixel-art`** — Pixel art com paletas de era (NES, Game Boy, PICO-8).

**When usar:** criar pixel art.

---

**`ascii-art`** — Arte ASCII: pyfiglet, cowsay, boxes, image-to-ascii.

**When usar:** arte ASCII, logos em texto.

---

**`ascii-video`** — Vídeo ASCII: converte vídeo/áudio para MP4/GIF colorido.

**When usar:** criar vídeos em ASCII.

---

**`baoyu-article-illustrator`** — Ilustrações para artigos: tipo × estilo × paleta.

**When usar:** criar ilustrações para artigos.

---

**`baoyu-comic`** — Quadrinhos educacionais (知识漫画).

**When usar:** criar quadrinhos educacionais.

---

**`baoyu-infographic`** — Infográficos: 21 layouts × 21 estilos.

**When usar:** criar infográficos.

---

**`baoyu-diagram`** — Diagramas SVG dark-themed profissionais.

**When usar:** criar diagramas SVG.

---

**`excalidraw`** — Diagramas Excalidraw JSON (arch, flow, seq).

**When usar:** diagramas hand-drawn.

---

**`excalidraw-diagram`** — Gera diagramas Excalidraw de conteúdo de texto.

**When usar:** criar diagramas Excalidraw.

---

**`excalidraw-diagram-generator`** — Gera diagramas Excalidraw de descrições em linguagem natural.

**When usar:** gerar diagramas automaticamente.

---

**`hand-drawn-diagrams`** — Diagramas Excalidraw hand-drawn de um prompt.

**When usar:** diagramas estilo hand-drawn.

---

**`progressive-blur-header-swiftui`** — Componente SwiftUI de header sticky com blur progressivo.

**When usar:** headers iOS com blur.

---

**`liquid-glass`** — Implementa e revisa macOS SwiftUI Liquid Glass UI.

**When usar:** UI Liquid Glass macOS.

---

**`swiftui-liquid-glass`** — Implementa e revisa iOS 26+ SwiftUI Liquid Glass UI.

**When usar:** UI Liquid Glass iOS.

---

**`accessibility-and-inclusive-visualization`** — Visualizações de dados acessíveis e inclusivas.

**When usar:** visualizações acessíveis.

---

### Resumo — Design & UI/UX:

| Skill | Uso Principal |
|---|---|
| ui-ux-pro-max | Design system completo por indústria |
| taste-design | Anti-slop, brief inference |
| impeccable-design | 20+ comandos de design |
| motion-design | Animações e micro-interações |
| claude-design | Artifacts HTML one-off |
| popular-web-designs | 54 designs reais (Stripe, Linear, etc.) |
| design-md | Design tokens DESIGN.md |
| figma-use / figma-* | Trabalhar com Figma |
| canva / canva-* | Designs no Canva |
| chart-designer | Gráficos e visualizações |
| brand-designer | Identidade visual |
| editorial-designer | Interfaces editoriais |
| hyperframes | Composições de vídeo HTML |
| comfyui | Geração de mídia |
| manim-video | Animações matemáticas |
| p5js | Arte generativa |
| pixel-art | Pixel art |
| ascii-art | Arte ASCII |

---

## 4. MARKETING & MÍDIAS SOCIAIS

### 4.1 — Ads & Copy

**`ads-copywriter`** — Geração de copy para Google Ads, Meta/Facebook, multi-plataforma.

**When usar:** criar anúncios, copy para ads.

---

**`ads-youtube`** — Análise de YouTube Ads: tipos de campanha, criativos.

**When usar:** anúncios no YouTube.

---

**`google-calendar-daily-brief`** — Briefings diários do Google Calendar.

**When usar:** preparar reuniões, briefings.

---

### 4.2 — Instagram

**`instagram`** — Integração com Instagram para mídias sociais.

**When usar:** interagir com Instagram.

---

**`instagram-carousel`** — Design de posts carrossel como arquivos HTML.

**When usar:** criar carrosséis para Instagram.

---

**`instagram-content-generation`** — Gera conteúdo Instagram via each::sense AI.

**When usar:** gerar conteúdo para Instagram.

---

**`instagram-downloader`** — Baixa posts do Instagram.

**When usar:** baixar conteúdo do Instagram.

---

**`instagram-marketing`** — Gera conteúdo de marketing a partir de URLs de produtos.

**When usar:** marketing de produtos no Instagram.

---

**`instagram-messenger`** — Integração com Instagram Messenger.

**When usar:** gerenciar mensagens do Instagram.

---

**`instagram-post`** — Posta no Instagram com imagens, carrosséis, Reels e Stories.

**When usar:** publicar no Instagram.

---

**`instagram-publisher`** — Publica posts carrossel a partir de imagens locais.

**When usar:** publicar carrosséis.

---

**`instagram-replicate`** — Reconstrói um Reel público em vídeo determinístico.

**When usar:** replicar Reels.

---

**`instagram-scraper`** — Scraping do Instagram — batch, stealth.

**When usar:** extrair dados do Instagram.

---

**`instagram-skill`** — Usa Instagram CLI para interagir via terminal.

**When usar:** automação do Instagram via CLI.

---

### 4.3 — Facebook

**`facebook`** — Posta no Facebook wall/group com imagens e tags.

**When usar:** publicar no Facebook.

---

**`facebook-ads`** — Gerencia campanhas, audiências e anúncios Meta/Facebook.

**When usar:** gerenciar ads no Facebook.

---

**`facebook-ads-library-mcp-server`** — MCP server para consultar Facebook Ads Library.

**When usar:** pesquisar anúncios no Facebook.

---

**`facebook-automation`** — Automatiza tarefas do Facebook via Rube MCP.

**When usar:** automatizar Facebook.

---

**`facebook-video-downloader`** — Baixa vídeos do Facebook.

**When usar:** baixar vídeos do Facebook.

---

**`scrapesocial-facebook`** — Pesquisa e workflow guidance para Facebook.

**When usar:** pesquisar conteúdo no Facebook.

---

### 4.4 — YouTube

**`youtube-analytics`** — Analisa performance de canal e vídeos.

**When usar:** analytics do YouTube.

---

**`youtube-api`** — Dados do YouTube sem quotas de API.

**When usar:** acessar dados do YouTube.

---

**`youtube-automation`** — Automatiza workflows de conteúdo YouTube.

**When usar:** automatizar YouTube.

---

**`youtube-channels`** — Foco em canais do YouTube.

**When usar:** gerenciar canais.

---

**`youtube-clipper`** — Geração e edição de clips YouTube.

**When usar:** criar clips.

---

**`youtube-data`** — Dados estruturados do YouTube.

**When usar:** extrair dados do YouTube.

---

**`youtube-downloader`** — Baixa vídeos do YouTube.

**When usar:** baixar vídeos.

---

**`youtube-full`** — Quando YouTube é relevante.

**When usar:** qualquer tarefa relacionada a YouTube.

---

**`youtube-playlist`** — Quando playlist do YouTube está envolvida.

**When usar:** gerenciar playlists.

---

**`youtube-render-pdf`** — Gera notas de aula LaTeX profissionais com figuras.

**When usar:** criar materiais educacionais.

---

**`youtube-search`** — Busca conteúdo no YouTube.

**When usar:** pesquisar no YouTube.

---

**`youtube-summarizer`** — Extrai transcrições e gera resumos.

**When usar:** resumir vídeos.

---

**`youtube-transcribe-skill`** — Extrai legendas/transcrições do YouTube.

**When usar:** transcrever vídeos.

---

**`youtube-transcript`** — Extrai transcrições do YouTube.

**When usar:** obter transcrições.

---

**`youtube-uploader`** — Sobe vídeos no YouTube com título, descrição, tags.

**When usar:** upload de vídeos.

---

**`youtube-video-analyst`** — Desconstrução forense de vídeos do YouTube.

**When usar:** análise profunda de vídeos.

---

**`baoyu-youtube-transcript`** — Baixa transcrições/legendas e capas do YouTube.

**When usar:** baixar transcrições.

---

**`transcriptapi`** — Quando YouTube pode ser relevante.

**When usar:** extrair transcrições.

---

### 4.5 — WhatsApp

**`agent-whatsapp`** — Interage com WhatsApp — envia mensagens, lê chats.

**When usar:** interagir com WhatsApp.

---

**`automate-whatsapp`** — Automa WhatsApp com Kapso workflows.

**When usar:** automatizar WhatsApp.

---

**`integrate-whatsapp`** — Conecta WhatsApp ao produto com Kapso.

**When usar:** integrar WhatsApp.

---

**`observe-whatsapp`** — Observa e troubleshoot WhatsApp no Kapso.

**When usar:** debugar WhatsApp.

---

**`whatsapp-automation`** — Automatiza WhatsApp Business via Rube MCP.

**When usar:** automatizar WhatsApp Business.

---

**`whatsapp-by-online-live-support`** — WhatsApp via Online Live Support.

**When usar:** integração WhatsApp.

---

**`whatsapp-cloud-api`** — Referência oficial da WhatsApp Cloud API.

**When usar:** construir mensagens WhatsApp.

---

**`whatsapp-instagram-tiktok-mass-sender-marketing`** — Mensagens em massa e marketing.

**When usar:** marketing em massa.

---

**`whatsapp-mass-sender-group-marketing`** — Mensagens em massa, marketing de grupo.

**When usar:** marketing de grupo.

---

**`whatsapp-messaging`** — Envia mensagens WhatsApp.

**When usar:** enviar mensagens.

---

**`whatsapp-skill`** — Envia e recebe mensagens WhatsApp.

**When usar:** comunicação WhatsApp.

---

**`whatsapp-templates`** — Cria templates de mensagens WhatsApp.

**When usar:** criar templates.

---

**`whatsapp-web`** — Automação WhatsApp Web via Playwright e Chrome CDP.

**When usar:** automatizar WhatsApp Web.

---

**`whatsapp-web-js`** — Guia para whatsapp-web.js, biblioteca Puppeteer.

**When usar:** desenvolver com whatsapp-web.js.

---

### 4.6 — Outras Redes

**`tiktok`** — (via mass-sender skills)

**`scrapesocial-instagram`** — Pesquisa e workflow guidance para Instagram.

**When usar:** pesquisar Instagram.

---

**`social-orchestrator`** — Orquestrador unificado de canais sociais.

**When usar:** coordenar múltiplas redes sociais.

---

**`social-media-content`** — Extrai texto, metadata e mídia de Instagram.

**When usar:** extrair conteúdo de redes sociais.

---

**`media`** — Habilidades de mídia: YouTube, GIFs, música, áudio.

**When usar:** trabalhar com mídia.

---

**`meme-generation`** — Gera memes reais com templates.

**When usar:** criar memes.

---

**`blotato`** — Plataforma de publicação e agendamento de mídias sociais.

**When usar:** agendar posts, publicar em redes.

---

**`resend`** — Envia emails via MCP server oficial da Resend.

**When usar:** enviar emails transacionais.

---

### Resumo — Marketing & Social:

| Skill | Uso Principal |
|---|---|
| ads-copywriter | Copy para ads |
| instagram-* | Instagram completo |
| facebook-* | Facebook completo |
| youtube-* | YouTube completo |
| whatsapp-* | WhatsApp completo |
| social-orchestrator | Orquestrar redes |
| meme-generation | Criar memes |
| blotato | Agendar posts |
| resend | Emails transacionais |

---

## 5. DIAGRAMAS & VISUALIZAÇÃO

### 5.1 — Diagramas de Arquitetura

**`architecture-diagram`** — Diagramas SVG dark-themed de arquitetura/cloud/infra como HTML.

**When usar:** diagramas de arquitetura.

---

**`architecture-diagrams`** — Diagramas de arquitetura com Mermaid, PlantUML.

**When usar:** diagramas de sistema.

---

**`aws-diagrams`** — Visualiza infra AWS de CLI output, CloudFormation.

**When usar:** diagramas AWS.

---

**`azure-diagrams`** — Visualiza infra Azure de ARM templates, Azure CLI.

**When usar:** diagramas Azure.

---

**`bicep-diagrams`** — Gera diagramas de arquivos Bicep Azure.

**When usar:** diagramas Bicep.

---

**`terraform-diagrams`** — Gera diagramas de código Terraform.

**When usar:** diagramas Terraform.

---

**`eraser-diagrams`** — Gera diagramas de código, infra ou descrição.

**When usar:** diagramas a partir de código.

---

**`draw-io-diagram-generator`** — Cria, edita e gera diagramas draw.io.

**When usar:** diagramas draw.io.

---

**`sf-diagram-mermaid`** — Diagramas Salesforce com Mermaid.

**When usar:** diagramas Salesforce.

---

**`sf-diagram-nanobananapro`** — Geração de imagens para visuais Salesforce.

**When usar:** visuais Salesforce.

---

### 5.2 — Mermaid & Flowcharts

**`mermaid-diagrams`** — Guia completo para diagramas Mermaid (flowchart, sequence, class, state, ER, gantt, pie, mindmap).

**When usar:** qualquer diagrama Mermaid.

---

**`generating-mermaid-diagrams`** — Diagramas Mermaid com ASCII fallback.

**When usar:** gerar diagramas Mermaid.

---

**`diagram-creator`** — Cria diagramas profissionais com Mermaid, PlantUML e outros.

**When usar:** criar diagramas.

---

**`diagram-to-image`** — Converte diagramas Mermaid e tabelas Markdown para imagens PNG.

**When usar:** exportar diagramas como imagem.

---

**`concept-diagrams`** — Gera diagramas SVG flat, minimal, light/dark-aware.

**When usar:** diagramas conceituais.

---

**`node-link-and-diagram-layout`** — Escolhe e aplica estratégias de layout para grafos.

**When usar:** diagramas de grafos.

---

### 5.3 — Data Visualization

**`data-visualization`** — Roteador de visualização de dados web.

**When usar:** escolher tipo de visualização.

---

**`csv-data-visualizer`** — Trabalha com CSV para criar visualizações.

**When usar:** visualizar dados CSV.

---

**`d3-data-visualization`** — Constrói visualizações customizadas com D3.

**When usar:** visualizações D3.

---

**`canvas2d-data-visualization`** — Renderiza visualizações com Canvas2D.

**When usar:** visualizações Canvas2D.

---

**`threejs-data-visualization`** — Renderiza visualizações WebGL com Three.js.

**When usar:** visualizações 3D/WebGL.

---

**`react-and-nextjs-data-visualization`** — Integra visualizações em React/Next.js.

**When usar:** visualizações em React.

---

**`typescript-data-visualization-engineering`** — Constrói visualizações tipadas em TypeScript.

**When usar:** visualizações TypeScript.

---

**`grammar-of-graphics-and-declarative-visualization`** — Visualizações com gramáticas declarativas (Vega-Lite, Observable Plot).

**When usar:** visualizações declarativas.

---

**`statistical-and-uncertainty-visualization`** — Visualizações com incerteza estatística.

**When usar:** visualizações estatísticas.

---

**`geospatial-and-cartographic-visualization`** — Visualizações geoespaciais e cartográficas.

**When usar:** mapas, visualizações geoespaciais.

---

**`gantt-chart-visualization`** — Diagramas de Gantt.

**When usar:** cronogramas, Gantt.

---

**`dashboards-and-real-time-visualization`** — Dashboards e visualizações em tempo real.

**When usar:** dashboards.

---

**`scrollytelling-and-parallax-data-visualization`** — Scrollytelling e parallax.

**When usar:** narrativas visuais com scroll.

---

**`testing-data-visualizations`** — Testa visualizações e dashboards.

**When usar:** QA de visualizações.

---

### 5.4 — Charts

**`chart-designer`** — Design de visualizações e gráficos.

**When usar:** criar gráficos.

---

**`comps-analysis`** — Análise de empresas comparáveis em Excel.

**When usar:** análise financeira.

---

**`3-statement-model`** — Modelo 3-statement integrado (IS, BS, CF) em Excel.

**When usar:** modelagem financeira.

---

**`dcf-model`** — Modelo DCF de avaliação em Excel.

**When usar:** valuation.

---

**`lbo-model`** — Modelo LBO em Excel.

**When usar:** LBO.

---

**`merger-model`** — Modelo de fusão/aquisição em Excel.

**When usar:** M&A.

---

**`grad-event-study`** — Metodologia de estudo de eventos.

**When usar:** análise de eventos.

---

**`detect-freight-led-inflation-turn`** — Detecta inflação via CASS Freight Index.

**When usar:** análise macroeconômica.

---

### 5.5 — UML & Software Architecture

**`uml-and-software-architecture-visualization`** — UML, C4, ERD, BPMN, sequence diagrams.

**When usar:** diagramas UML.

---

### 5.6 — Vídeo & Animação

**`ffmpeg-video-editor`** — Gera comandos FFmpeg de linguagem natural.

**When usar:** edição de vídeo.

---

**`video-edit`** — Edita vídeos no RunComfy.

**When usar:** editar vídeos.

---

**`video-transcript`** — Extrai conteúdo de vídeo como texto.

**When usar:** transcrever vídeos.

---

**`image-to-video`** — Anima imagens estáticas no RunComfy.

**When usar:** criar vídeos a partir de imagens.

---

**`image-gen`** — Gera ou edita imagens raster.

**When usar:** gerar imagens.

---

**`image-creator`** — Renderiza HTML/CSS em imagens via Playwright.

**When usar:** converter HTML em imagem.

---

**`image-edit`** — Edita imagens no RunComfy.

**When usar:** editar imagens.

---

**`image-fetcher`** — Adquire visuais de múltiplas fontes.

**When usar:** buscar imagens.

---

**`image-studio`** — Studio de geração de imagens inteligente.

**When usar:** gerar imagens.

---

**`image-ai-generator`** — Gera imagens via Openrouter API.

**When usar:** gerar imagens com IA.

---

**`stable-diffusion`** — Geração de imagens state-of-the-art com Stable Diffusion.

**When usar:** gerar imagens com SD.

---

**`segment-anything-model`** — SAM: segmentação de imagem zero-shot.

**When usar:** segmentar imagens.

---

**`clip`** — Modelo OpenAI conectando visão e linguagem.

**When usar:** visão computacional.

---

**`llava`** — Large Language and Vision Assistant.

**When usar:** instruções visuais.

---

**`heygen-avatar`** — Cria avatar HeyGen persistente.

**When usar:** criar avatares.

---

**`heygen-video`** — Gera vídeos com apresentador HeyGen.

**When usar:** criar vídeos com apresentador.

---

**`remotion-video-reviewer`** — Revisão estruturada de vídeos Remotion.

**When usar:** revisar vídeos.

---

**`kanban-video-orchestrator`** — Planeja e monitora produção de vídeo multi-agente.

**When usar:** produção de vídeo.

---

### Resumo — Diagramas & Visualização:

| Skill | Uso Principal |
|---|---|
| architecture-diagram | Diagramas de arquitetura SVG |
| mermaid-diagrams | Diagramas Mermaid |
| diagram-creator | Diagramas Mermaid/PlantUML |
| diagram-to-image | Exportar diagramas como PNG |
| data-visualization | Roteador de visualizações |
| d3-data-visualization | Visualizações D3 |
| threejs-data-visualization | Visualizações WebGL |
| chart-designer | Gráficos |
| ffmpeg-video-editor | Edição de vídeo |
| image-gen / image-creator | Geração de imagens |
| stable-diffusion | Geração de imagens SD |
| heygen-video | Vídeos com apresentador |

---

## 6. APRESENTAÇÕES & SLIDES

**`elite-powerpoint-designer`** — Apresentações PowerPoint de classe mundial com profissionalismo.

**When usar:** criar apresentações PowerPoint premium.

---

**`pptx-author`** — Constrói decks PowerPoint headless com python-pptx. Pares com excel-author.

**When usar:** gerar apresentações PowerPoint programaticamente.

---

**`google-slides`** — Google Slides — encontrar, ler, resumir, criar.

**When usar:** trabalhar com Google Slides.

---

**`canva-branded-presentation`** — Apresentações Canva on-brand a partir de brief.

**When usar:** apresentações com marca no Canva.

---

### Resumo — Apresentações:

| Skill | Uso Principal |
|---|---|
| elite-powerpoint-designer | PowerPoint premium |
| pptx-author | PowerPoint programático |
| google-slides | Google Slides |
| canva-branded-presentation | Apresentações Canva |

---

## 7. PDF & DOCUMENTOS

**`ocr-and-documents`** — Extrai texto de PDFs/scans (pymupdf, marker-pdf).

**When usar:** extrair texto de PDFs.

---

**`nano-pdf`** — Edita texto/typos/títulos em PDF via prompts em linguagem natural.

**When usar:** editar PDFs.

---

**`killerpdf-portable-editor`** — Editor PDF portátil Windows, single-EXE.

**When usar:** editar PDFs no Windows.

---

**`translate-book-parallel`** — Traduz livros inteiros (PDF/DOCX/EPUB) para qualquer idioma.

**When usar:** traduzir documentos longos.

---

**`docx-authoring`** — Cria, modifica e traduz documentos DOCX com python-docx.

**When usar:** criar documentos Word.

---

### Resumo — PDF & Documentos:

| Skill | Uso Principal |
|---|---|
| ocr-and-documents | Extrair texto de PDFs |
| nano-pdf | Editar PDFs |
| killerpdf-portable-editor | Editar PDFs no Windows |
| translate-book-parallel | Traduzir livros |
| docx-authoring | Criar documentos Word |

---

## 8. WEB DEVELOPMENT

### 8.1 — Frontend Frameworks

**`react-best-practices`** — Otimização de performance React/Next.js.

**When usar:** otimizar React.

---

**`nextjs`** — (via react-best-practices, expo-router)

**`vue-debug-guides`** — Debug e error handling Vue 3.

**When usar:** debugar Vue.

---

**`angular`** — (via typescript skills)

**`svelte`** — (via frontend skills)

---

### 8.2 — CSS & Styling

**`tailwind`** — (via taste-design, ui-ux-pro-max)

**`shadcn`** — Gerencia componentes shadcn.

**When usar:** adicionar componentes shadcn.

---

**`bootstrap`** — (via popular-web-designs)

---

### 8.3 — Backend & APIs

**`node`** — Melhores práticas Node.js.

**When usar:** desenvolver com Node.js.

---

**`express`** — (via node skills)

**`fastapi`** — (via python skills)

**`django`** — (via python skills)

**`flask`** — (via python skills)

**`laravel`** — (via php skills)

---

### 8.4 — Bancos de Dados

**`supabase-best-practices`** — Melhores práticas Supabase/Postgres.

**When usar:** otimizar Supabase.

---

**`postgres`** — (via supabase skills)

**`mysql`** — (via database skills)

**`mongodb`** — (via database skills)

**`redis`** — (via database skills)

**`sqlite`** — (via database skills)

**`prisma`** — (via database skills)

**`drizzle`** — (via database skills)

**`chroma`** — Banco de dados de embeddings open-source.

**When usar:** armazenar embeddings.

---

**`pinecone`** — Banco de dados vetorial gerenciado.

**When usar:** busca vetorial.

---

**`qdrant`** — Engine de busca vetorial de alta performance.

**When usar:** RAG, busca vetorial.

---

### 8.5 — DevOps & Deploy

**`docker-management`** — Gerencia containers Docker.

**When usar:** trabalhar com Docker.

---

**`kubernetes`** — (via devops skills)

**`terraform`** — (via terraform-diagrams)

**`cloudflare`** — Cloudflare platform completa.

**When usar:** Workers, Pages, etc.

---

**`vercel`** — (via popular-web-designs)

**`netlify`** — (via web skills)

---

### 8.6 — Testes

**`javascript-typescript-jest`** — Melhores práticas de testes JS/TS com Jest.

**When usar:** testar código JS/TS.

---

**`typescript-e2e-testing`** — Testes E2E para projetos TypeScript/NestJS.

**When usar:** testes E2E.

---

**`playwright`** — (via mcp-power-5)

**`cypress`** — (via testing skills)

---

### 8.7 — Segurança

**`security-auditor`** — Especialista em vulnerabilidades OWASP Top 10.

**When usar:** auditoria de segurança.

---

**`security-reviewer`** — Identifica vulnerabilidades, gera auditorias.

**When usar:** revisão de segurança.

---

**`xss-cross-site-scripting`** — Playbook XSS.

**When usar:** prevenir XSS.

---

### 8.8 — Performance

**`web-perf`** — Analisa performance web com Chrome DevTools MCP.

**When usar:** otimizar performance.

---

**`lighthouse`** — (via web-perf)

---

### Resumo — Web Development:

| Área | Skills |
|---|---|
| Frontend | React, Vue, Angular, Svelte, Tailwind, shadcn |
| Backend | Node, Express, FastAPI, Django, Flask, Laravel |
| Database | Supabase, Postgres, MongoDB, Redis, Chroma, Pinecone, Qdrant |
| DevOps | Docker, Cloudflare, Vercel, Terraform |
| Testes | Jest, E2E, Playwright |
| Segurança | OWASP, XSS, Security Auditor |
| Performance | Web Perf, Lighthouse |

---

## 9. CRIAÇÃO DE CONTEÚDO — GUIA PRÁTICO

### 9.1 — Workflow Completo: Documentação Técnica

```
1. DEFINIR O BRIEF
   → taste-design: inferir o brief, definir dials
   → documentation-writer: classificar tipo (Tutorial/How-to/Reference/Explanation)

2. PESQUISAR
   → content-research-writer: pesquisar o tema
   → web-search: buscar referências
   → duckduckgo-search: busca alternativa

3. ESTRUTURAR
   → documentation-writer: propor estrutura (outline)
   → code-wiki: se for documentação de código

4. ESCREVER
   → blog-writing-guide: seguir padrões de escrita
   → document-writer: para blogs Nuxt
   → academic-research-writer: para papers

5. REVISAR
   → de-slop: remover AI-isms
   → humanizer: humanizar texto
   → editorial-qa: QA pré-publicação
   → qa-reviewer: revisão de qualidade

6. PUBLICAR
   → (exportar para formato desejado)
```

---

### 9.2 — Workflow Completo: Design de Interface

```
1. BRIEF & INFERÊNCIA
   → taste-design: inferir brief, definir 3 dials
   → ui-ux-pro-max: gerar design system por indústria

2. EXPLORAR
   → claude-design: produzir 3 variantes (conservadora, forte, divergente)
   → popular-web-designs: se quiser visual de marca conhecida
   → sketch: mockups rápidos

3. REFINAR
   → impeccable-design: /polish, /audit, /typeset, /colorize, /layout
   → motion-design: adicionar animações
   → design-md: gerar spec de tokens

4. VERIFICAR
   → accessibility-and-inclusive-visualization: verificar acessibilidade
   → web-design-reviewer: inspeção visual
   → pre-flight check (taste-design)

5. EXPORTAR
   → image-creator: converter HTML para imagem
   → diagram-to-image: exportar diagramas
```

---

### 9.3 — Workflow Completo: Marketing de Conteúdo

```
1. PLANEJAR
   → social-orchestrator: coordenar canais
   → content-research-writer: pesquisar tema

2. CRIAR CONTEÚDO
   → ads-copywriter: copy para ads
   → instagram-content-generation: conteúdo Instagram
   → script-writer: roteiros de vídeo
   → reels-scripting: scripts para Reels
   → meme-generation: criar memes

3. DESIGN VISUAL
   → instagram-carousel: carrosséis
   → canva: designs
   → image-ai-generator: gerar imagens
   → stable-diffusion: imagens SD

4. PUBLICAR
   → instagram-post: publicar no Instagram
   → instagram-publisher: publicar carrosséis
   → blotato: agendar posts
   → youtube-uploader: subir vídeos

5. ANALISAR
   → youtube-analytics: analytics
   → (verificar métricas)
```

---

### 9.4 — Workflow Completo: Apresentação

```
1. BRIEF
   → taste-design: inferir estilo
   → ui-ux-pro-max: design system

2. CRIAR
   → elite-powerpoint-designer: PowerPoint premium
   → pptx-author: PowerPoint programático
   → google-slides: Google Slides
   → canva-branded-presentation: Canva

3. VISUAL
   → hyperframes: composições de vídeo
   → manim-video: animações matemáticas
   → diagram-creator: diagramas

4. EXPORTAR
   → diagram-to-image: exportar como imagem
   → image-creator: converter para imagem
```

---

### 9.5 — Workflow Completo: Diagrama & Visualização

```
1. DEFINIR TIPO
   → data-visualization: classificar o trabalho analítico
   → diagram-creator: escolher tipo de diagrama

2. CRIAR
   → mermaid-diagrams: diagramas Mermaid
   → architecture-diagram: diagramas de arquitetura
   → excalidraw: diagramas hand-drawn
   → d3-data-visualization: visualizações D3
   → chart-designer: gráficos

3. EXPORTAR
   → diagram-to-image: converter para PNG
   → image-creator: converter HTML para imagem
```

---

## 10. WORKFLOWS POR TIPO DE PROJETO

### 📄 Projeto: Documentação de Software
```
documentation-writer → code-wiki → blog-writing-guide → de-slop → editorial-qa
```

### 🎨 Projeto: Landing Page
```
taste-design → ui-ux-pro-max → claude-design → impeccable-design → motion-design
```

### 📱 Projeto: App Mobile
```
taste-design → ui-ux-pro-max → claude-design → react-best-practices → shadcn
```

### 📊 Projeto: Dashboard
```
data-visualization → chart-designer → d3-data-visualization → dashboard-and-real-time-visualization
```

### 📢 Projeto: Campanha de Marketing
```
ads-copywriter → instagram-content-generation → canva → image-ai-generator → blotato
```

### 🎬 Projeto: Vídeo
```
script-writer → heygen-video → ffmpeg-video-editor → youtube-uploader
```

### 📑 Projeto: Apresentação
```
elite-powerpoint-designer → pptx-author → diagram-creator → hyperframes
```

### 📖 Projeto: Tutorial
```
documentation-writer → blog-writing-guide → code-wiki → diagram-creator → de-slop
```

### 🔬 Projeto: Pesquisa
```
content-research-writer → academic-research-writer → research-paper-writer → translate-book-parallel
```

### 🏗️ Projeto: Arquitetura de Sistema
```
architecture-designer → architecture-diagram → mermaid-diagrams → uml-and-software-architecture-visualization
```

### 🎮 Projeto: Jogo
```
game-studio → phaser-2d-game → react-three-fiber-game → three-webgl-game
```

---

## 11. REFERÊNCIA RÁPIDA — COMANDOS

### Comandos do Agente

| Comando | O que faz |
|---|---|
| `skills_list()` | Lista todas as skills disponíveis |
| `skill_view(name="x") | Carrega uma skill específica |
| `skills_list(category="creative") | Lista skills por categoria |
| `delegate_task(goal="x")` | Spawnar subagente para tarefa |
| `fact_store(action="probe", entity="x")` | Consultar memória estruturada |
| `memory(action="add", target="x", content="y")` | Salvar memória |

### Slash Commands (no chat)

| Comando | Skill |
|---|---|
| `/tdd` | test-driven-development |
| `/diagnose` | hermes-agent-diagnostics |
| `/plan` | plan |
| `/spike` | spike |
| `/polish` | impeccable-design |

### Instalação de Skills

```bash
# Instalar uma skill
hermes skills install nome-da-skill --yes

# Instalar de repo GitHub
hermes skills install user/repo/skill-name --yes

# Listar skills instaladas
hermes skills list --source local
```

### Categorias de Skills Disponíveis

| Categoria | Qtd | Descrição |
|---|---|---|
| creative | 23 | Design, arte, animação, vídeo |
| productivity | 9 | Excel, PDF, docs, workspace |
| media | 7 | YouTube, GIFs, música, áudio |
| github | 6 | Git, PRs, issues, CI/CD |
| devops | 6 | Docker, webhooks, gateway |
| software-development | 17 | Debug, TDD, code review |
| mlops | 5 | ML training, inference, models |
| mcp | 2 | MCP servers |
| microsoft-foundry | 4 | Azure AI Foundry |
| research | 4 | Pesquisa, arxiv, blogwatcher |
| email | 1 | Himalaya CLI |
| gaming | 1 | Pokemon player |
| smart-home | 1 | Philips Hue |
| note-taking | 1 | Obsidian |
| autonomous-ai-agents | 5 | Claude Code, Codex, etc. |
| red-teaming | 1 | Godmode |
| local | 489 | Skills locais customizadas |

---

## 12. TODAS AS SKILLS POR CATEGORIA

### creative (23 skills)

| Skill | Descrição |
|---|---|
| after-hours-editorial-template | Template editorial dark-editorial de luxo |
| animation-designer | Animações web, transitions, motion design |
| architecture-diagram | Diagramas SVG dark-themed como HTML |
| ascii-art | Arte ASCII: pyfiglet, cowsay, boxes |
| ascii-video | Vídeo ASCII: converte vídeo/áudio para MP4/GIF |
| baoyu-article-illustrator | Ilustrações para artigos |
| baoyu-comic | Quadrinhos educacionais |
| baoyu-infographic | Infográficos: 21 layouts × 21 estilos |
| claude-design | Design de artifacts HTML one-off |
| comfyui | Gera imagens, vídeo e áudio com ComfyUI |
| design-md | Autor/validar/exportar DESIGN.md |
| excalidraw | Diagramas Excalidraw JSON |
| humanizer | Humaniza texto — remove AI-isms |
| ideation | Gera ideias via restrições criativas |
| impeccable-design | 20+ comandos de design anti-slop |
| manim-video | Animações Manim CE |
| motion-design | Animações e micro-interações |
| p5js | Sketches p5.js |
| pixel-art | Pixel art com paletas de era |
| popular-web-designs | 54 designs reais (Stripe, Linear, Vercel) |
| sketch | Mockups HTML rápidos |
| taste-design | Framework anti-slop com brief inference |
| ui-ux-pro-max | 67 estilos UI, 161 paletas, 57 fontes |

### productivity (9 skills)

| Skill | Descrição |
|---|---|
| airtable | Airtable REST API |
| docx-authoring | Cria/modifica/traduz DOCX |
| excel | Lê/edita/formata Excel |
| excel-author | Constrói workbooks Excel headless |
| google-workspace | Gmail, Calendar, Drive, Docs |
| killerpdf-portable-editor | Editor PDF portátil Windows |
| maps | Geocoding, POIs, rotas |
| nano-pdf | Edita PDF via linguagem natural |
| ocr-and-documents | Extrai texto de PDFs/scans |
| powerpoint | Cria/edita .pptx |

### media (7 skills)

| Skill | Descrição |
|---|---|
| gif-search | Busca GIFs no Tenor |
| heartmula | Geração de música Suno-like |
| social-media-content | Extrai conteúdo de Instagram |
| songsee | Espectrogramas de áudio |
| spotify | Spotify: play, search, queue |
| tts-and-telegram-audio | TTS e áudio no Telegram |
| youtube-content | YouTube transcripts para resumos |

### github (6 skills)

| Skill | Descrição |
|---|---|
| codebase-inspection | Inspeciona codebases com pygount |
| github-auth | Auth GitHub: tokens, SSH |
| github-code-review | Review de PRs |
| github-issues | Cria/triagem de issues |
| github-pr-workflow | Ciclo de vida de PRs |
| github-repo-management | Clone/create/fork repos |

### devops (6 skills)

| Skill | Descrição |
|---|---|
| hermes-agent-maintenance | Scan e instalação de skills |
| kanban-orchestrator | Playbook de decomposição |
| kanban-worker | Pitfalls para workers |
| local-llm-providers | Configurar LLMs locais |
| webhook-subscriptions | Subscriptions de webhooks |
| whatsapp-gateway | Configurar gateway WhatsApp |

### software-development (17 skills)

| Skill | Descrição |
|---|---|
| batch-file-transformation | Transformação em lote de arquivos |
| community-skill-install | Instala skills da comunidade |
| debugging-hermes-tui-commands | Debug de comandos TUI |
| hermes-agent-diagnostics | Health check completo |
| hermes-agent-skill-authoring | Autorar skills in-repo |
| hermes-s6-container-supervision | Modificar s6-overlay |
| hermes-setup | Configuração do Hermes |
| node-inspect-debugger | Debug Node.js via --inspect |
| plan | Plan mode: escreve plano markdown |
| powershell-architect | Arquiteto de Skills PowerShell |
| powershell-wpf-development | PowerShell Expert — WPF/XAML |
| requesting-code-review | Pré-commit review |
| spike | Experimentos throwaway |
| subagent-driven-development | Executa planos via subagentes |
| systematic-debugging | Debug 4-fases |
| test-driven-development | TDD: RED-GREEN-REFACTOR |
| writing-plans | Escreve planos de implementação |

### mlops (5 skills)

| Skill | Descrição |
|---|---|
| huggingface-hub | HuggingFace CLI |
| huggingface-community-evals | Avaliações de modelos |
| huggingface-datasets | Datasets do HuggingFace |
| huggingface-gradio | Gradio web UIs |
| huggingface-jobs | Jobs do HuggingFace |
| huggingface-llm-trainer | Treinamento de LLMs |
| huggingface-paper-publisher | Publicar papers |
| huggingface-papers | Ler papers |
| huggingface-tokenizers | Tokenizers rápidos |
| huggingface-trackio | Track experiments |
| huggingface-vision-trainer | Treinar modelos de visão |

### mcp (2 skills)

| Skill | Descrição |
|---|---|
| mcp-power-5 | 5 MCP servers essenciais |
| native-mcp | Cliente MCP nativo |

### microsoft-foundry (4 skills)

| Skill | Descrição |
|---|---|
| finetuning | Fine-tune em Azure AI Foundry |
| microsoft-foundry | Deploy, evaluate, fine-tune |
| deploy-model | Deploy de modelos |
| capacity | Descobre capacidade disponível |

### research (4 skills)

| Skill | Descrição |
|---|---|
| arxiv | Busca papers arXiv |
| blogwatcher | Monitora blogs e RSS |
| llm-wiki | Wiki de LLM interlinkado |
| polymarket | Query Polymarket |

### autonomous-ai-agents (5 skills)

| Skill | Descrição |
|---|---|
| claude-code | Delegar coding ao Claude Code |
| codex | Delegar coding ao OpenAI Codex |
| hermes-agent | Configurar Hermes Agent |
| kanban-codex-lane | Codex CLI como worker |
| opencode | Delegar coding ao OpenCode |

### email (1 skill)

| Skill | Descrição |
|---|---|
| himalaya | Email IMAP/SMTP via terminal |

### gaming (1 skill)

| Skill | Descrição |
|---|---|
| pokemon-player | Joga Pokemon via emulator |

### smart-home (1 skill)

| Skill | Descrição |
|---|---|
| openhue | Controla Philips Hue |

### note-taking (1 skill)

| Skill | Descrição |
|---|---|
| obsidian | Lê/cria/edita notas no Obsidian |

### red-teaming (1 skill)

| Skill | Descrição |
|---|---|
| godmode | Jailbreak LLMs |

### local (489 skills)

Skills locais customizadas instaladas no ambiente. Inclui todas as skills listadas nas seções anteriores deste guia.

---

## 🎯 CONCLUSÃO: COMO USAR NO DIA A DIA

### Para Criação de Conteúdo Técnico:
1. **Comece pelo brief** → `taste-design` para inferir direção
2. **Pesquise** → `content-research-writer` + `web-search`
3. **Estruture** → `documentation-writer` (Diátaxis)
4. **Escreva** → `blog-writing-guide` ou `document-writer`
5. **Revise** → `de-slop` + `humanizer` + `editorial-qa`
6. **Documente código** → `code-wiki` + `mermaid-diagrams`

### Para Design & Visual:
1. **Defina o sistema** → `ui-ux-pro-max` (por indústria) ou `taste-design` (anti-slop)
2. **Crie variantes** → `claude-design` (3 opções)
3. **Refine** → `impeccable-design` (/polish, /audit, /typeset)
4. **Anime** → `motion-design`
5. **Exporte** → `image-creator` + `diagram-to-image`

### Para Marketing & Redes Sociais:
1. **Planeje** → `social-orchestrator`
2. **Crie copy** → `ads-copywriter`
3. **Gere conteúdo** → `instagram-content-generation` + `script-writer`
4. **Design** → `canva` + `instagram-carousel` + `image-ai-generator`
5. **Publique** → `instagram-post` + `blotato` (agendamento)

### Para Apresentações:
1. **PowerPoint** → `elite-powerpoint-designer` ou `pptx-author`
2. **Google Slides** → `google-slides`
3. **Diagramas** → `diagram-creator` + `mermaid-diagrams`
4. **Vídeo** → `hyperframes` + `heygen-video`

### Para PDFs & Documentos:
1. **Extrair** → `ocr-and-documents` (pymupdf/marker)
2. **Editar** → `nano-pdf`
3. **Criar** → `docx-authoring` + `excel-author`
4. **Traduzir** → `translate-book-parallel`

### Para Diagramas & Visualização:
1. **Arquitetura** → `architecture-diagram` + `mermaid-diagrams`
2. **Dados** → `data-visualization` → `d3-data-visualization` ou `chart-designer`
3. **Vídeo** → `ffmpeg-video-editor` + `manim-video`
4. **Imagens** → `image-gen` + `stable-diffusion` + `comfyui`

### 💡 Dica Final:

> **Regra de Ouro:** Problema bem classificado → skill certa → execução mais confiável.
> 
> Não tente fazer tudo com uma skill só. Combine skills em workflows para resultados profissionais.

---

**Documento gerado por OWL Agent — ZOO Company**  
**Data:** 03/06/2026  
**Total de skills catalogadas:** 583  
**Foco:** Documentação, Design, Tutoriais, Marketing Visual & Criação de Conteúdo

---
