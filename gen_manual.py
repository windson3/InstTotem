# -*- coding: utf-8 -*-
"""
OWL AGENT - MANUAL COMPLETO DE SKILLS v2
Capa elegante, tabelas com header escuro, comandos mono
Corrigido: colunas com largura adequada, nomes longos com multi_cell
"""
import fpdf
import os

OUTPUT = r"c:\Testes APP\Instalação Totem\InstTotem\MANUAL_SKILLS_OWL.pdf"

# Cores
DARK_BG = (30, 40, 70)
MEDIUM_BLUE = (45, 70, 140)
LIGHT_BLUE = (80, 120, 200)
PALE_BG = (230, 238, 250)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
DARK_TEXT = (40, 40, 40)
HEADER_BG = (35, 45, 80)
MEDIUM_GRAY = (120, 120, 120)
LIGHT_GRAY = (200, 200, 200)

def clean(text):
    text = text.replace('\u2014', '-').replace('\u2013', '-')
    text = text.replace('\u201c', '"').replace('\u201d', '"')
    text = text.replace('\u2018', "'").replace('\u2019', "'")
    text = text.replace('\u2026', "...")
    for a, b in [('á','a'),('é','e'),('í','i'),('ó','o'),('ú','u'),('ç','c'),('ã','a'),('õ','o'),('â','a'),('ê','e'),('ô','o'),('à','a'),('è','e'),('ì','i'),('ò','o'),('ù','u'),('Á','A'),('É','E'),('Í','I'),('Ó','O'),('Ú','U'),('Ç','C'),('Ã','A'),('Õ','O')]:
        text = text.replace(a, b)
    # Remove emoji
    text = ''.join(c for c in text if ord(c) < 900)
    return text.strip()

# ============================================================
# SKILLS DATABASE
# ============================================================
SKILLS = {}

SKILLS["DOCUMENTACAO E ESCRITA TECNICA"] = [
    ("documentation-writer", "Especialista em documentacao tecnica (Diataxis). Tutoriais, How-to, Referencia, Explicacao."),
    ("document-writer", "Escrita de blogs e docs Nuxt. Padroes de estilo, MDC."),
    ("code-wiki", "Gera wiki completa + diagramas Mermaid para qualquer codebase."),
    ("blog-writing-guide", "Escrita tecnica estilo Sentry. Voz direta, SEO, checklist editorial."),
    ("content-research-writer", "Pesquisa e escreve conteudo de alta qualidade."),
    ("academic-research-writer", "Cria documentos de pesquisa academica IEEE/ACM."),
    ("research-paper-writer", "Artigos formais IEEE/ACM para publicacoes academicas."),
    ("skill-writer", "Cria, sintetiza e melhora skills de agente."),
    ("skill-creator", "Guia para criar skills eficazes do zero."),
    ("executive-resume-writer", "Curriculos de C-suite e VP com foco estrategico."),
    ("resume-bullet-writer", "Transforma bullets fracos em declaracoes de impacto."),
    ("proposal-writer", "Propostas comerciais que ganham deals."),
    ("pr-writer", "Cria e atualiza pull requests com convencoes."),
    ("script-writer", "Roteiros para videos do YouTube."),
    ("writer-memory", "Sistema de memoria para escritores."),
    ("writing-for-interfaces", "UX copy, microtextos, labels para interfaces."),
    ("de-slop / de-slopify", "Remove padroes de escrita de IA, humaniza texto."),
    ("humanizer", "Humaniza texto — remove AI-isms e adiciona voz real."),
    ("translate-book-parallel", "Traduz livros inteiros PDF/DOCX/EPUB."),
    ("editorial-qa", "QA pre-publicacao para conteudo."),
]

SKILLS["DESIGN E UI/UX"] = [
    ("ui-ux-pro-max", "67 estilos UI, 161 paletas, 57 fontes, 25 graficos, 99 diretrizes UX."),
    ("taste-design", "Framework anti-slop: inferencia de brief, 3 dials, layout/color/motion rules."),
    ("impeccable-design", "20+ comandos: craft, shape, audit, animate, colorize, typeset, polish."),
    ("motion-design", "Animacoes: easing, spring physics, performance, accessibility."),
    ("claude-design", "Artifacts HTML: landing pages, prototipos, mockups, decks."),
    ("popular-web-designs", "54 design systems reais (Stripe, Linear, Vercel, Notion, etc)."),
    ("design-md", "Google DESIGN.md: autor/validar/exportar specs de tokens."),
    ("frontend-design", "Interfaces frontend production-grade, distintivas."),
    ("editorial-designer", "Interfaces editoriais de alta qualidade."),
    ("brand-designer", "Identidade visual, logo, sistemas de marca."),
    ("brand-guidelines", "Cores e tipografia oficiais da Anthropic."),
    ("chart-designer", "Design de visualizacoes e graficos de dados."),
    ("elite-powerpoint-designer", "PowerPoint de classe mundial, profissional."),
    ("canva", "Cria, busca, preenche e exporta designs Canva."),
    ("figma-use / figma-*", "Trabalha com Figma via MCP: use, create, generate, connect."),
    ("sketch", "Mockups HTML rapidos 2-3 variantes."),
    ("ascii-art / ascii-video", "Arte ASCII / Video ASCII MP4/GIF."),
    ("pixel-art", "Pixel art (NES, Game Boy, PICO-8)."),
    ("comfyui", "Geracao de imagens, video e audio ComfyUI."),
    ("manim-video", "Animacoes matematicas estilo 3Blue1Brown."),
    ("p5js", "Arte generativa, shaders, 3D."),
]

SKILLS["MARKETING E SOCIAL MEDIA"] = [
    ("ads-copywriter", "Geracao de copy para Google Ads, Meta/Facebook."),
    ("ads-youtube", "Analise de YouTube Ads: tipos de campanha, criativos."),
    ("instagram-post", "Posta no Instagram: imagens, carrosseis, Reels, Stories."),
    ("instagram-carousel", "Design de posts carrossel como HTML."),
    ("instagram-content-generation", "Gera conteudo Instagram via IA."),
    ("instagram-publisher", "Publica posts carrossel de imagens locais."),
    ("facebook-ads", "Gerencia campanhas e anuncios Meta/Facebook."),
    ("facebook-automation", "Automatiza tarefas do Facebook via Rube MCP."),
    ("facebook-video-downloader", "Baixa videos do Facebook."),
    ("youtube-uploader", "Sobe videos no YouTube com titulo, descricao, tags."),
    ("youtube-summarizer", "Extrai transcricoes e gera resumos de videos."),
    ("youtube-clipper", "Geracao e edicao de clips YouTube."),
    ("youtube-analytics", "Analisa performance de canal e videos."),
    ("whatsapp-messaging", "Envia mensagens WhatsApp."),
    ("whatsapp-cloud-api", "Referencia oficial da WhatsApp Cloud API."),
    ("whatsapp-web", "WhatsApp Web via Playwright e Chrome CDP."),
    ("whatsapp-templates", "Cria templates de mensagens para Meta."),
    ("social-orchestrator", "Orquestrador unificado de canais sociais."),
    ("blotato", "Publicacao e agendamento de redes sociais."),
    ("meme-generation", "Gera memes reais com templates."),
]

SKILLS["DIAGRAMAS E VISUALIZACAO"] = [
    ("architecture-diagram", "Diagramas SVG dark de arquitetura/cloud/infra como HTML."),
    ("mermaid-diagrams", "Diagramas Mermaid: flowchart, sequence, class, state, ER, gantt."),
    ("diagram-creator", "Cria diagramas com Mermaid, PlantUML e outros."),
    ("diagram-to-image", "Converte diagramas Mermaid e tabelas para PNG."),
    ("excalidraw-diagram-generator", "Gera diagramas Excalidraw de ling. natural."),
    ("hand-drawn-diagrams", "Diagramas Excalidraw hand-drawn de um prompt."),
    ("baoyu-diagram", "Diagramas SVG dark-themed profissionais."),
    ("architecture-diagrams", "Diagramas de arquitetura com Mermaid, PlantUML."),
    ("data-visualization", "Roteador de visualizacao de dados web."),
    ("d3-data-visualization", "Visualizacoes customizadas com D3."),
    ("threejs-data-visualization", "Visualizacoes WebGL com Three.js."),
    ("ffmpeg-video-editor", "Comandos FFmpeg de ling. natural."),
    ("image-gen", "Gera ou edita imagens raster via IA."),
    ("stable-diffusion", "Text-to-image com Stable Diffusion."),
    ("image-to-video", "Animar imagens em video."),
    ("video-edit", "Edita videos no RunComfy."),
    ("video-transcript", "Extrai conteudo de video como texto."),
    ("heygen-avatar / heygen-video", "Videos com apresentador virtual HeyGen."),
    ("remotion-video-reviewer", "Revisao de videos Remotion."),
    ("hyperframes", "Composicoes de video HTML + animacoes."),
]

SKILLS["DESIGN VISUAL E CONTEUDO COMPLETO"] = [
    ("image-gen / image-creator", "Geracao de imagens: HTML->imagem, AI, ComfyUI."),
    ("image-edit / image-fetcher", "Edicao e busca de imagens multiplas fontes."),
    ("image-studio", "Studio de geracao de imagens inteligente."),
    ("image-ai-generator", "Gera imagens via Openrouter API."),
    ("image-to-video", "Animar imagens estaticas em video."),
    ("video-edit / video-transcript", "Edicao e transcricao de videos."),
    ("ffmpeg-video-editor", "Comandos FFmpeg de ling. natural."),
    ("heygen-avatar / heygen-video", "Videos com apresentador virtual."),
    ("remotion-video-reviewer", "Revisao de videos Remotion."),
    ("hyperframes", "Composicoes de video HTML + animacoes."),
    ("hyperframes-cli", "CLI do HyperFrames: init, lint, inspect."),
    ("meme-generation", "Geracao de memes reais."),
    ("social-orchestrator", "Orquestrador de canais sociais."),
    ("blotato", "Publicacao e agendamento de redes."),
    ("instagram-post", "Post, carousel, content-generation, publisher."),
    ("instagram-scraper", "Scraping do Instagram."),
    ("instagram-marketing", "Marketing de produtos no Instagram."),
    ("instagram-messenger", "Instagram Messenger."),
    ("instagram-replicate", "Reconstrucao de Reels."),
    ("instagram-downloader", "Download de posts do Instagram."),
    ("instagram-skill", "Instagram CLI via terminal."),
    ("youtube-uploader", "Upload de videos no YouTube."),
    ("youtube-analytics", "Analytics de canal e videos."),
    ("youtube-clipper", "Geracao e edicao de clips."),
    ("youtube-data", "Dados estruturados do YouTube."),
    ("youtube-downloader", "Download de videos do YouTube."),
    ("youtube-search", "Busca de conteudo no YouTube."),
    ("youtube-summarizer", "Resumos de videos via transcricao."),
    ("youtube-transcribe-skill", "Extracao de legendas/transcricoes."),
    ("youtube-transcript", "Transcricoes de videos."),
    ("youtube-video-analyst", "Analise forense de videos."),
    ("youtube-full", "Qualquer tarefa relacionada a YouTube."),
    ("youtube-channels", "Foco em canais do YouTube."),
    ("youtube-playlist", "Playlists do YouTube."),
    ("youtube-render-pdf", "Notas de aula LaTeX com figuras."),
    ("youtube-automation", "Automacao de workflows YouTube."),
    ("youtube-api", "Dados YouTube sem quotas de API."),
    ("youtube-content", "Transcripts para resumos, blogs."),
    ("baoyu-youtube-transcript", "Transcricoes e capas do YouTube."),
    ("transcriptapi", "Transcricoes de video."),
    ("ads-copywriter", "Copy para Google Ads, Meta/Facebook."),
    ("ads-youtube", "Analise de YouTube Ads."),
    ("facebook-ads", "Gerencia campanhas e anuncios Meta."),
    ("facebook-ads-library-mcp-server", "MCP server para Facebook Ads Library."),
    ("facebook-automation", "Automatiza tarefas do Facebook."),
    ("facebook-video-downloader", "Baixa videos do Facebook."),
    ("scrapesocial-facebook", "Pesquisa e workflow para Facebook."),
    ("scrapesocial-instagram", "Pesquisa e workflow para Instagram."),
    ("whatsapp-messaging", "Envia mensagens WhatsApp."),
    ("whatsapp-cloud-api", "WhatsApp Cloud API."),
    ("whatsapp-web", "WhatsApp Web via Playwright."),
    ("whatsapp-web-js", "Guia para whatsapp-web.js."),
    ("whatsapp-templates", "Cria templates de mensagens."),
    ("whatsapp-automation", "Automa WhatsApp Business via Rube MCP."),
    ("whatsapp-skill", "Envia e recebe mensagens."),
    ("agent-whatsapp", "Interage com WhatsApp."),
    ("automate-whatsapp", "Automa com Kapso workflows."),
    ("integrate-whatsapp", "Conecta WhatsApp ao produto."),
    ("observe-whatsapp", "Debug de mensagens WhatsApp."),
    ("whatsapp-by-online-live-support", "WhatsApp via Online Live Support."),
    ("whatsapp-instagram-tiktok-mass-sender-marketing", "Mensagens em massa e marketing."),
    ("whatsapp-mass-sender-group-marketing", "Mensagens em massa, marketing de grupo."),
    ("blog-writing-guide", "Escrita tecnica estilo Sentry."),
    ("writing-beats", "Escreve artigo por batidas narrativas."),
    ("writing-fragments", "Coleta fragmento de escrita sem estrutura."),
    ("writing-shape", "Transforma material em artigo publicavel."),
    ("teach", "Orquestra trilha de aprendizagem."),
    ("review", "Revisa mudancas em dois eixos."),
    ("skill-writer", "Cria skills de agente eficazes."),
    ("skill-creator", "Guia para criar skills."),
    ("code-wiki", "Wiki + diagramas Mermaid para codebase."),
    ("academic-research-writer", "Pesquisa academica IEEE/ACM."),
    ("content-research-writer", "Pesquisa + escrita de conteudo."),
    ("documentation-writer", "Documentacao tecnica (Diataxis)."),
    ("document-writer", "Blogs e docs Nuxt."),
    ("proposal-writer", "Propostas comerciais."),
    ("pr-writer", "Pull requests."),
    ("script-writer", "Roteiros YouTube."),
    ("reels-scripting", "Scripts para Reels."),
    ("writer-memory", "Memoria para escritores."),
    ("writing-for-interfaces", "UX copy."),
    ("writing-plans", "Planos de implementacao."),
    ("writing-job-descriptions", "Descricoes de vagas."),
    ("writing-react-native-storybook-stories", "Stories do React Native Storybook."),
    ("wechat-article-writer", "Artigos para WeChat."),
    ("xhs-note-creator", "Notas para Xiaohongshu."),
    ("cinematic-script-writer", "Roteiros cinematograficos."),
    ("songwriting-and-ai-music", "Composicao musical com IA."),
    ("de-slop", "Remove padroes de escrita de IA."),
    ("de-slopify", "Remove artefatos de IA de documentacao."),
    ("de-sloppify", "Limpeza de codigo .NET."),
    ("humanizer", "Humaniza texto."),
    ("translate-book-parallel", "Traduz livros inteiros."),
    ("ai-content-collaboration", "Humans e IA em fluxos de conteudo."),
    ("aibtc-news-editor", "Editor de noticias aibtc.news."),
    ("asc-whats-new-writer", "Release notes para App Store."),
    ("executive-onboarding-playbook", "Onboarding 30-60-90 dias."),
    ("executive-resume-writer", "Curriculos executivos."),
    ("resume-bullet-writer", "Bullets de curriculo."),
    ("portfolio-case-study-writer", "Estudos de caso de portfolio."),
    ("playwriter", "Controla Chrome via Playwriter."),
    ("capture-tasks-from-meeting-notes", "Extrai tarefas de notas de reuniao."),
    ("generate-status-report", "Relatorios de status de projeto."),
    ("planning-with-files", "Planejamento com arquivos markdown."),
    ("one-three-one-rule", "Framework de decisao tecnica."),
    ("adversarial-ux-test", "Teste UX adversarial."),
    ("dogfood", "QA exploratorio de web apps."),
    ("editorial-qa", "QA pre-publicacao."),
    ("skill-quality-reviewer", "Analisa skills com eixo duplo."),
    ("dual-axis-skill-reviewer", "Revisao dual-axis de skills."),
    ("edge-strategy-reviewer", "Revisao de documentos estrategicos."),
    ("qa-reviewer", "Revisao de qualidade de trabalho IA."),
    ("remotion-video-reviewer", "Revisao de videos Remotion."),
    ("architecture-diagram", "Diagramas SVG dark de arquitetura."),
    ("architecture-diagrams", "Diagramas Mermaid/PlantUML."),
    ("aws-diagrams", "Diagramas de infra AWS."),
    ("azure-diagrams", "Diagramas de infra Azure."),
    ("bicep-diagrams", "Diagramas de arquivos Bicep."),
    ("terraform-diagrams", "Diagramas de codigo Terraform."),
    ("eraser-diagrams", "Diagramas de codigo ou infra."),
    ("draw-io-diagram-generator", "Diagramas draw.io."),
    ("sf-diagram-mermaid", "Diagramas Salesforce com Mermaid."),
    ("sf-diagram-nanobananapro", "Imagens para visuais Salesforce."),
    ("concept-diagrams", "Diagramas SVG flat, minimal."),
    ("node-link-and-diagram-layout", "Layout automatico de grafos."),
    ("excalidraw-diagram", "Diagramas Excalidraw JSON."),
    ("excalidraw-diagram-generator", "Diagramas Excalidraw de ling. natural."),
    ("hand-drawn-diagrams", "Diagramas hand-drawn de prompt."),
    ("baoyu-diagram", "Diagramas SVG dark profissionais."),
    ("baoyu-infographic", "Infograficos: 21 layouts x 21 estilos."),
    ("baoyu-comic", "Quadrinhos educacionais."),
    ("baoyu-article-illustrator", "Ilustracoes para artigos."),
    ("mermaid-diagrams", "Diagramas Mermaid completos."),
    ("generating-mermaid-diagrams", "Diagramas Mermaid com ASCII fallback."),
    ("diagram-creator", "Diagramas Mermaid/PlantUML."),
    ("diagram-to-image", "Converte diagramas para PNG."),
    ("data-visualization", "Roteador de visualizacoes web."),
    ("csv-data-visualizer", "Visualizacoes de arquivos CSV."),
    ("d3-data-visualization", "Visualizacoes D3 customizadas."),
    ("canvas2d-data-visualization", "Visualizacoes Canvas2D."),
    ("threejs-data-visualization", "Visualizacoes WebGL Three.js."),
    ("react-and-nextjs-data-visualization", "Visualizacoes em React/Next.js."),
    ("typescript-data-visualization-engineering", "Visualizacoes TypeScript."),
    ("grammar-of-graphics-and-declarative-visualization", "Visualizacoes declarativas (Vega-Lite)."),
    ("statistical-and-uncertainty-visualization", "Visualizacoes com incerteza."),
    ("geospatial-and-cartographic-visualization", "Visualizacoes geoespaciais."),
    ("gantt-chart-visualization", "Diagramas de Gantt."),
    ("dashboards-and-real-time-visualization", "Dashboards em tempo real."),
    ("scrollytelling-and-parallax-data-visualization", "Scrollytelling e parallax."),
    ("testing-data-visualizations", "Testes de visualizacoes."),
    ("chart-designer", "Design de visualizacoes e graficos."),
    ("comps-analysis", "Analise de empresas comparaveis em Excel."),
    ("3-statement-model", "Modelo 3-statement integrado em Excel."),
    ("dcf-model", "Modelo DCF de avaliacao em Excel."),
    ("lbo-model", "Modelo LBO em Excel."),
    ("merger-model", "Modelo de fusao/aquisicao em Excel."),
    ("grad-event-study", "Metodologia de estudo de eventos."),
    ("detect-freight-led-inflation-turn", "Detecta inflacao via CASS Freight Index."),
    ("uml-and-software-architecture-visualization", "UML, C4, ERD, BPMN."),
    ("api-and-interface-design", "Design estavel de APIs e interfaces."),
    ("api-designer", "Design de REST/GraphQL APIs, OpenAPI specs."),
    ("database-schema-designer", "Design de schemas SQL/NoSQL escalaveis."),
    ("architecture-designer", "Design de arquitetura de alto nivel."),
    ("architecting-solutions", "Design de solucoes tecnicas."),
    ("design-team", "17 especialistas de design em um agente."),
    ("creative-director", "Diretor de IA criativo com 20+ comandos."),
    ("make-interfaces-feel-better", "Detalhes que fazem interfaces funcionarem."),
    ("web-design-guidelines", "Revisao de conformidade Web Interface Guidelines."),
    ("web-design-reviewer", "Inspecao visual de sites."),
    ("accessibility-and-inclusive-visualization", "Visualizacoes acessiveis."),
    ("progressive-blur-header-swiftui", "Header SwiftUI com blur progressivo."),
    ("liquid-glass", "SwiftUI Liquid Glass UI."),
    ("swiftui-liquid-glass", "iOS 26+ SwiftUI Liquid Glass UI."),
    ("after-hours-editorial-template", "Template editorial dark luxo."),
    ("field-notes-editorial-template", "Template de relatorio Field Notes."),
    ("editorial-monograph", "Monografia editorial A4."),
    ("editorial", "Layout editorial inspirado em revistas."),
    ("editorial-designer", "Interfaces editoriais de alta qualidade."),
    ("editorial-burgundy-principles-template", "Template editorial burgundy/blush."),
    ("ocr-and-documents", "Extrai texto de PDFs/scans (pymupdf, marker-pdf)."),
    ("nano-pdf", "Edita PDF via ling. natural."),
    ("killerpdf-portable-editor", "Editor PDF portatil Windows."),
    ("docx-authoring", "Cria/modifica/traduz documentos DOCX."),
    ("excel", "Le, edita, formata arquivos Excel."),
    ("excel-author", "Constroi workbooks Excel headless."),
    ("powerpoint / pptx-author", "Cria/edita/apresentacoes PowerPoint."),
    ("google-slides", "Google Slides."),
    ("canva-branded-presentation", "Apresentacoes Canva on-brand."),
    ("canva-resize-for-all-social-media", "Redimensiona para formatos sociais."),
    ("canva-translate-design", "Traduz texto em designs Canva."),
    ("airtable", "Airtable REST API."),
    ("notion", "Notion API."),
    ("confluence", "Confluence CQL."),
    ("linear", "Linear issues/projects."),
    ("google-workspace", "Gmail, Calendar, Drive, Docs."),
    ("resend", "Emails via Resend."),
    ("himalaya", "Email IMAP/SMTP terminal."),
    ("1password", "1Password CLI."),
]

# ============================================================
# PDF CLASS
# ============================================================
class ManualPDF(fpdf.FPDF):
    def __init__(self):
        super().__init__()
        self.set_auto_page_break(auto=True, margin=20)
        self.set_margins(15, 15, 15)
    
    def cover_page(self):
        self.add_page()
        self.set_fill_color(*DARK_BG)
        self.rect(0, 0, 210, 160, 'F')
        self.set_fill_color(*WHITE)
        self.rect(0, 155, 210, 8, 'F')
        self.set_fill_color(25, 35, 75)
        self.polygon([(0, 0), (60, 0), (0, 50)], style='F')
        self.polygon([(210, 0), (150, 0), (210, 50)], style='F')
        self.set_draw_color(*LIGHT_BLUE)
        self.set_line_width(1.5)
        self.line(40, 55, 170, 55)
        self.set_xy(0, 60)
        self.set_font('Helvetica', 'B', 28)
        self.set_text_color(*WHITE)
        self.multi_cell(210, 12, clean('OWL AGENT'), align='C')
        self.set_xy(0, 85)
        self.set_font('Helvetica', '', 14)
        self.set_text_color(180, 200, 240)
        self.multi_cell(210, 7, clean('MANUAL COMPLETO DE SKILLS'), align='C')
        self.set_xy(0, 100)
        self.set_font('Helvetica', '', 10)
        self.set_text_color(150, 175, 220)
        self.multi_cell(210, 5, clean('583 Skills | 15+ Categorias | Referencia Profissional'), align='C')
        self.set_xy(0, 170)
        self.set_font('Helvetica', 'B', 11)
        self.set_text_color(*DARK_TEXT)
        self.multi_cell(210, 6, clean('Documentacao | Design | Tutoriais | Marketing Visual'), align='C')
        self.set_xy(0, 185)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(*MEDIUM_GRAY)
        self.multi_cell(210, 5, clean('Criacao de Conteudo | Diagramas | Apresentacoes | Comandos'), align='C')
        self.set_draw_color(*MEDIUM_BLUE)
        self.set_line_width(2)
        self.line(50, 210, 160, 210)
        self.set_xy(0, 225)
        self.set_font('Helvetica', '', 8)
        self.set_text_color(*MEDIUM_GRAY)
        self.multi_cell(210, 4, clean('Versao 2026.06 | OWL Agent - ZOO Company | Hermes Framework'), align='C')
        self.set_fill_color(240, 245, 255)
        self.polygon([(0, 297), (30, 297), (0, 267)], style='F')
        self.polygon([(210, 297), (180, 297), (210, 267)], style='F')
    
    def section_header(self, title, section_num=None):
        if self.get_y() > 250:
            self.add_page()
        if section_num:
            title = f"{section_num}) {title}"
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(*DARK_BG)
        self.cell(0, 10, clean(title))
        self.ln()
        self.set_draw_color(*MEDIUM_BLUE)
        self.set_line_width(0.8)
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(4)
    
    def skill_table(self, skills):
        """Tabela robusta: multi_cell para ambas as colunas, calculo de altura correto"""
        if not skills:
            return
        
        COL_W = 55  # largura coluna skill
        DESC_W = 130  # largura descricao
        LH = 4.2  # line height
        FH = 6  # font size skill
        FD = 6.5  # font size desc
        
        for idx, (name, desc) in enumerate(skills):
            name_c = clean(name)
            desc_c = clean(desc)
            
            # Calcular altura necessaria para cada coluna
            name_lines = max(1, len(name_c) // 22 + (1 if len(name_c) % 22 else 0))
            desc_lines = max(1, len(desc_c) // 38 + (1 if len(desc_c) % 38 else 0))
            row_h = max(name_lines * LH + 2, desc_lines * LH + 2, 6)
            
            # Verificar se precisa de nova pagina
            if self.get_y() + row_h > 270:
                self.add_page()
                # Header
                self.set_fill_color(*HEADER_BG)
                self.set_text_color(*WHITE)
                self.set_font('Helvetica', 'B', 8)
                self.cell(COL_W, 6, clean('Skill'), border=0, fill=True)
                self.cell(0, 6, clean('Descricao em Portugues'), border=0, fill=True)
                self.ln()
            
            # Cor de fundo
            bg = (245, 248, 255) if idx % 2 == 0 else WHITE
            self.set_fill_color(*bg)
            
            # Salvar posicao
            x0 = self.get_x()
            y0 = self.get_y()
            
            # Coluna Skill - multi_cell para quebrar linha se longo
            self.set_xy(x0, y0)
            self.set_font('Helvetica', 'B', FH)
            self.set_text_color(*DARK_TEXT)
            self.multi_cell(COL_W, LH, name_c, border=0, fill=True)
            name_end_y = self.get_y()
            
            # Coluna Descricao - comecar na mesma linha Y
            self.set_xy(x0 + COL_W, y0)
            self.set_font('Helvetica', '', FD)
            self.set_text_color(*DARK_TEXT)
            self.multi_cell(DESC_W, LH, desc_c, border=0, fill=True)
            desc_end_y = self.get_y()
            
            # Avancar para a linha abaixo da maior coluna
            self.set_xy(x0, max(name_end_y, desc_end_y))
    
    def command_section(self, title, commands, section_num=None):
        if section_num:
            title = f"{section_num}) {title}"
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(*DARK_BG)
        self.cell(0, 8, clean(title))
        self.ln()
        self.ln(2)
        for cmd in commands:
            if self.get_y() > 265:
                self.add_page()
            self.set_font('Courier', '', 8)
            self.set_text_color(50, 50, 50)
            self.multi_cell(0, 4.5, clean(cmd))
            self.ln(1)
        self.ln(3)
    
    def category_header(self, cat_name, count, desc):
        if self.get_y() > 265:
            self.add_page()
        self.set_fill_color(*PALE_BG)
        self.set_font('Helvetica', 'B', 9)
        self.set_text_color(*MEDIUM_BLUE)
        self.cell(0, 6, clean(f"  {cat_name}  ({count})  -  {desc}"), border=0, fill=True)
        self.ln()
        self.ln(1)

# ============================================================
# GERAR PDF
# ============================================================
pdf = ManualPDF()

# Capa
pdf.cover_page()

# Indice
pdf.add_page()
pdf.set_font('Helvetica', 'B', 16)
pdf.set_text_color(*DARK_BG)
pdf.cell(0, 12, clean('INDICE'))
pdf.ln()
pdf.set_draw_color(*LIGHT_BLUE)
pdf.line(15, pdf.get_y(), 195, pdf.get_y())
pdf.ln(5)
toc = [
    ("1", "Documentacao e Escrita Tecnica"),
    ("2", "Design e UI/UX"),
    ("3", "Marketing e Social Media"),
    ("4", "Diagramas e Visualizacao"),
    ("5", "Design Visual e Conteudo (Referencia Completa)"),
    ("6", "Comandos Essenciais - Hermes"),
    ("7", "Workflows por Tipo de Projeto"),
    ("8", "Todas as Skills por Categoria"),
]
pdf.set_font('Helvetica', '', 10)
for num, title in toc:
    pdf.set_text_color(*MEDIUM_BLUE)
    pdf.cell(15, 6, clean(num + ")"), border=0)
    pdf.set_text_color(*DARK_TEXT)
    pdf.cell(0, 6, clean(title))
    pdf.ln()
pdf.ln(5)

# Secao 1
pdf.section_header("Documentacao e Escrita Tecnica", "1")
pdf.set_fill_color(*HEADER_BG)
pdf.set_text_color(*WHITE)
pdf.set_font('Helvetica', 'B', 8)
pdf.cell(55, 6, clean('Skill'), border=0, fill=True)
pdf.cell(0, 6, clean('Descricao em Portugues'), border=0, fill=True)
pdf.ln()
pdf.skill_table(SKILLS["DOCUMENTACAO E ESCRITA TECNICA"])

# Secao 2
pdf.add_page()
pdf.section_header("Design e UI/UX", "2")
pdf.set_fill_color(*HEADER_BG)
pdf.set_text_color(*WHITE)
pdf.set_font('Helvetica', 'B', 8)
pdf.cell(55, 6, clean('Skill'), border=0, fill=True)
pdf.cell(0, 6, clean('Descricao em Portugues'), border=0, fill=True)
pdf.ln()
pdf.skill_table(SKILLS["DESIGN E UI/UX"])

# Secao 3
pdf.add_page()
pdf.section_header("Marketing e Social Media", "3")
pdf.set_fill_color(*HEADER_BG)
pdf.set_text_color(*WHITE)
pdf.set_font('Helvetica', 'B', 8)
pdf.cell(55, 6, clean('Skill'), border=0, fill=True)
pdf.cell(0, 6, clean('Descricao em Portugues'), border=0, fill=True)
pdf.ln()
pdf.skill_table(SKILLS["MARKETING E SOCIAL MEDIA"])

# Secao 4
pdf.add_page()
pdf.section_header("Diagramas e Visualizacao", "4")
pdf.set_fill_color(*HEADER_BG)
pdf.set_text_color(*WHITE)
pdf.set_font('Helvetica', 'B', 8)
pdf.cell(55, 6, clean('Skill'), border=0, fill=True)
pdf.cell(0, 6, clean('Descricao em Portugues'), border=0, fill=True)
pdf.ln()
pdf.skill_table(SKILLS["DIAGRAMAS E VISUALIZACAO"])

# Secao 5
pdf.add_page()
pdf.section_header("Design Visual e Conteudo - Referencia Completa", "5")
pdf.set_fill_color(*HEADER_BG)
pdf.set_text_color(*WHITE)
pdf.set_font('Helvetica', 'B', 8)
pdf.cell(55, 6, clean('Skill'), border=0, fill=True)
pdf.cell(0, 6, clean('Descricao em Portugues'), border=0, fill=True)
pdf.ln()
pdf.skill_table(SKILLS["DESIGN VISUAL E CONTEUDO COMPLETO"])

# Secao 6: Comandos
pdf.add_page()
pdf.section_header("Hermes - Comandos Essenciais", "6")
pdf.command_section("Skills - Listar e Buscar", [
    "hermes skills list --source local",
    "hermes skills list --source builtin",
    "hermes skills search tdd",
    "hermes skills inspect <identifier>",
    "hermes skills install <skill-name> --yes",
], "6.1")
pdf.command_section("Chat com Skills", [
    "hermes chat",
    "hermes chat -s tdd",
    "hermes chat -q \"responda apenas OK\" -s diagnose -Q",
], "6.2")
pdf.command_section("Gateway e Manutencao", [
    "hermes gateway restart",
    "hermes gateway status",
    "hermes backup -o <caminho>",
], "6.3")

# Secao 7: Workflows
pdf.add_page()
pdf.section_header("Workflows por Tipo de Projeto", "7")
workflows = [
    ("Documentacao de Software", "documentation-writer > code-wiki > blog-writing-guide > de-slop > editorial-qa"),
    ("Landing Page", "taste-design > ui-ux-pro-max > claude-design > impeccable-design > motion-design"),
    ("Campanha de Marketing", "ads-copywriter > instagram-content-generation > canva > image-ai-generator > blotato"),
    ("Video", "script-writer > heygen-video > ffmpeg-video-editor > youtube-uploader"),
    ("Apresentacao", "elite-powerpoint-designer > pptx-author > diagram-creator > hyperframes"),
    ("Tutorial", "documentation-writer > blog-writing-guide > code-wiki > diagram-creator"),
    ("Diagrama/Visualizacao", "data-visualization > chart-designer > d3-data-visualization > diagram-to-image"),
    ("Pesquisa", "content-research-writer > academic-research-writer > research-paper-writer"),
]
for title, flow in workflows:
    pdf.set_font('Helvetica', 'B', 9)
    pdf.set_text_color(*DARK_BG)
    pdf.cell(0, 6, clean(title))
    pdf.ln()
    pdf.set_font('Courier', '', 7.5)
    pdf.set_text_color(80, 80, 80)
    pdf.multi_cell(0, 4, clean(flow))
    pdf.ln(2)

# Secao 8: Categorias
pdf.add_page()
pdf.section_header("Todas as Skills por Categoria - Referencia Rapida", "8")
cats = [
    ("creative", 23, "Design, arte, animacao, video"),
    ("productivity", 9, "Excel, PDF, docs, workspace"),
    ("media", 7, "YouTube, GIFs, musica, audio"),
    ("github", 6, "Git, PRs, issues, CI/CD"),
    ("devops", 6, "Docker, webhooks, gateway"),
    ("software-development", 17, "Debug, TDD, code review"),
    ("mlops", 5, "ML training, inference, models"),
    ("mcp", 2, "MCP servers"),
    ("microsoft-foundry", 4, "Azure AI Foundry"),
    ("research", 4, "Pesquisa, arxiv, blogwatcher"),
    ("email", 1, "Himalaya CLI"),
    ("gaming", 1, "Pokemon player"),
    ("smart-home", 1, "Philips Hue"),
    ("note-taking", 1, "Obsidian"),
    ("autonomous-ai-agents", 5, "Claude Code, Codex, etc."),
    ("red-teaming", 1, "Godmode"),
    ("local", 489, "Skills locais customizadas"),
]
for cat_name, count, desc in cats:
    pdf.category_header(cat_name, count, desc)

# Fim
pdf.add_page()
pdf.set_font('Helvetica', 'B', 14)
pdf.set_text_color(*DARK_BG)
pdf.cell(0, 10, clean('FIM'), align='C')
pdf.ln()
pdf.set_draw_color(*MEDIUM_BLUE)
pdf.line(85, pdf.get_y(), 125, pdf.get_y())
pdf.ln(5)
pdf.set_font('Helvetica', '', 9)
pdf.set_text_color(*MEDIUM_GRAY)
pdf.multi_cell(0, 5, clean('583 Skills | 15+ Categorias | OWL Agent - ZOO Company | 2026'), align='C')

pdf.output(OUTPUT)
print(f"PDF gerado: {OUTPUT}")
print(f"Total de paginas: {pdf.page_no()}")
