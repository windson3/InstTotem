const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

const outputPath = 'C:\\Testes APP\\Tutorial Skills COMPLETO.pdf';
const doc = new PDFDocument({ margin: 50, size: 'A4' });
doc.pipe(fs.createWriteStream(outputPath));

// === FONTES ===
// Usar fonte Nativa do PDF (Helvetica) - supporta Latin-1 via encoding
// Para acentos, vamos usar uma abordagem: substituir caracteres problematicos
function safeText(text) {
  return text
    .replace(/[\u2018\u2019]/g, "'")   // smart quotes
    .replace(/[\u201C\u201D]/g, '"')   // smart double quotes
    .replace(/\u2013/g, '-')            // en-dash
    .replace(/\u2014/g, '--')           // em-dash
    .replace(/\u2026/g, '...')          // ellipsis
    .replace(/\u00A0/g, ' ');           // non-breaking space
}

// === HELPER FUNCTIONS ===
function addTitle(text, size) {
  doc.font('Helvetica-Bold').fontSize(size);
  doc.text(safeText(text), { align: 'center' });
  doc.moveDown(0.5);
}

function addSubtitle(text) {
  doc.font('Helvetica').fontSize(10);
  doc.text(safeText(text), { align: 'center', color: '#666666' });
  doc.moveDown(1);
}

function addCategoryHeader(cat, count) {
  // Check if we need a new page
  if (doc.y > 700) doc.addPage();
  
  const colors = {
    'autonomous-ai-agents': '#E74C3C',
    'creative': '#9B59B6',
    'data-science': '#3498DB',
    'deprecated': '#95A5A6',
    'devops': '#E67E22',
    'email': '#1ABC9C',
    'engineering': '#2ECC71',
    'gaming': '#F39C12',
    'github': '#333333',
    'in-progress': '#8E44AD',
    'mcp': '#16A085',
    'media': '#D35400',
    'misc': '#7F8C8D',
    'mlops': '#2980B9',
    'note-taking': '#C0392B',
    'personal': '#8E44AD',
    'productivity': '#27AE60',
    'red-teaming': '#C0392B',
    'research': '#2C3E50',
    'smart-home': '#F39C12',
    'software-development': '#1ABC9C',
  };
  
  const color = colors[cat] || '#2C3E50';
  const catLabel = cat.toUpperCase().replace(/-/g, ' ');
  
  doc.save();
  doc.fillColor(color).font('Helvetica-Bold').fontSize(13);
  doc.text(`${catLabel}  [${count} skills]`, { continued: false });
  doc.restore();
  
  doc.strokeColor(color).lineWidth(1.5);
  doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
  doc.moveDown(0.5);
}

function addSkill(name, desc) {
  // Check if we need a new page
  if (doc.y > 750) doc.addPage();
  
  doc.font('Helvetica-Bold').fontSize(9);
  doc.fillColor('#2C3E50');
  doc.text(`    ${safeText(name)}`, { continued: true });
  
  doc.font('Helvetica').fontSize(8);
  doc.fillColor('#444444');
  doc.text(`  ${safeText(desc)}`, { align: 'left' });
  doc.moveDown(0.3);
}

function addSectionTitle(text) {
  if (doc.y > 680) doc.addPage();
  doc.moveDown(0.5);
  doc.font('Helvetica-Bold').fontSize(11).fillColor('#2C3E50');
  doc.text(safeText(text));
  doc.strokeColor('#BDC3C7').lineWidth(0.5);
  doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
  doc.moveDown(0.5);
}

function addBodyText(text) {
  doc.font('Helvetica').fontSize(9).fillColor('#333333');
  doc.text(safeText(text), { align: 'justify', lineGap: 2 });
  doc.moveDown(0.5);
}

function addBullet(text) {
  doc.font('Helvetica').fontSize(8.5).fillColor('#333333');
  doc.text(`    - ${safeText(text)}`, { align: 'left', lineGap: 1 });
}

// ========================================
// CAPA
// ========================================
doc.addPage();
doc.y = 200;

addTitle('Tutorial Completo de Skills', 28);
addTitle('Todas as Categorias', 18);
addSubtitle('Guia de referencia pratico para Hermes Agent');
doc.moveDown(1);
addSubtitle('Versao completa - Portugues Brasil');
doc.moveDown(2);

doc.font('Helvetica').fontSize(11).fillColor('#555555');
doc.text('Gerado em: 28/05/2026', { align: 'center' });
doc.text('Total: 109 skills em 20 categorias', { align: 'center' });

// ========================================
// SUMARIO
// ========================================
doc.addPage();
addTitle('Sumario', 20);
doc.moveDown(0.5);

const sumario = [
  ['1. Fundamentos', '3'],
  ['2. Como Usar Skills', '4'],
  ['3. Categoria: Engineering', '5'],
  ['4. Categoria: Software Development', '6'],
  ['5. Categoria: Productivity', '7'],
  ['6. Categoria: GitHub', '8'],
  ['7. Categoria: Creative', '9'],
  ['8. Categoria: DevOps', '10'],
  ['9. Categoria: Autonomous AI Agents', '11'],
  ['10. Categoria: Media', '12'],
  ['11. Categoria: Research', '13'],
  ['12. Categoria: MCP', '14'],
  ['13. Categoria: ML Ops', '15'],
  ['14. Categoria: Email / Gaming / Smart Home', '16'],
  ['15. Categoria: Note-Taking / Personal', '17'],
  ['16. Categoria: In-Progress / Deprecated', '18'],
  ['17. Categoria: Misc / Red-Teaming', '19'],
  ['18. Comandos Essenciais do Hermes', '20'],
  ['19. Fluxo por Tipo de Tarefa', '21'],
  ['20. Roteiro de Teste em 10 Passos', '22'],
  ['21. Troubleshooting', '23'],
  ['22. Plano de Estudo (4 semanas)', '24'],
];

sumario.forEach(([titulo, pag]) => {
  doc.font('Helvetica').fontSize(10).fillColor('#333333');
  doc.text(`${titulo}`, 70, doc.y, { continued: true, width: 400 });
  doc.text(`${pag}`, { align: 'right', width: 475 });
  doc.moveDown(0.3);
});

// ========================================
// SECAO 1: FUNDAMENTOS
// ========================================
doc.addPage();
addTitle('1. Fundamentos', 18);
doc.moveDown(0.5);

addBodyText('Skill e um pacote de instrucoes reutilizaveis que orienta o agente para um tipo de tarefa especifica. Cada skill possui um arquivo SKILL.md com gatilhos de uso, passos e referencias.');
doc.moveDown(0.5);

addSectionTitle('Conceitos-Chave');
addBullet('Skill = instrucoes que o agente carrega dinamicamente para resolver um tipo de tarefa.');
addBullet('Categoria = grupo tematico de skills (ex: engineering, creative, devops).');
addBullet('Slash command = atalho no chat para ativar uma skill (ex: /tdd, /diagnose).');
addBullet('SKILL.md = arquivo markdown que define a skill (frontmatter + instrucoes).');
addBullet('delegate_task = spawnar subagentes para trabalho paralelo em skills.');
addBullet('fact_store = memoria estruturada para conhecimento entre sessoes.');
addBullet('memory = memoria duravel para preferencias e fatos do usuario.');
doc.moveDown(0.5);

addSectionTitle('Fluxo Minimo Recomendado');
addBullet('1) Defina o objetivo claramente.');
addBullet('2) Escolha a skill correta pela categoria/descricao.');
addBullet('3) Execute em ciclo curto (uma skill por vez).');
addBullet('4) Valide resultado com evidencia (teste, log, diff, checklist).');
addBullet('5) Registre aprendizado em memory ou fact_store.');

// ========================================
// SECAO 2: COMO USAR SKILLS
// ========================================
doc.addPage();
addTitle('2. Como Usar Skills', 18);
doc.moveDown(0.5);

addSectionTitle('Listar Skills Disponiveis');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  # Listar todas as skills locais');
doc.text('  hermes skills list --source local');
doc.text('');
doc.text('  # Listar skills built-in');
doc.text('  hermes skills list --source builtin');
doc.text('');
doc.text('  # Buscar skill por nome');
doc.text('  hermes skills search tdd');
doc.text('');
doc.text('  # Inspecionar uma skill especifica');
doc.text('  hermes skills inspect diagnose');
doc.moveDown(0.5);

addSectionTitle('Ativar Skills no Chat');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  # Abrir chat com skill especifica');
doc.text('  hermes chat -s tdd');
doc.text('');
doc.text('  # Multiplas skills');
doc.text('  hermes chat -s diagnose,triage');
doc.text('');
doc.text('  # No chat interativo, use slash commands:');
doc.text('  /tdd        - Test-Driven Development');
doc.text('  /diagnose   - Diagnostico de bugs');
doc.text('  /triage     - Triagem de issues');
doc.text('  /to-prd     - Criar PRD');
doc.text('  /to-issues  - Quebrar em issues');
doc.text('  /grill      - Entrevista de plano');
doc.text('  /handoff    - Passagem de contexto');
doc.moveDown(0.5);

addSectionTitle('Via Codigo (agente autônomo)');
addBodyText('Quando o agente detecta que uma skill e necessaria, ele carrega automaticamente via skill_view(name). Em testes automatizados, use skills_list(category) para filtrar por categoria.');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  skills_list(category="engineering")  # Lista engineering');
doc.text('  skill_view(name="diagnose")          # Carrega diagnose');
doc.text('  skill_manage(action="create", name="minha-skill", content="...")');

// ========================================
// TODAS AS CATEGORIAS E SKILLS
// ========================================
doc.addPage();
addTitle('Inventario Completo de Skills', 20);
addSubtitle('Todas as 109 skills organizadas por categoria');
doc.moveDown(0.5);

// Engineering
addCategoryHeader('ENGINEERING', 10);
addSkill('diagnose', 'Executa loop disciplinado de diagnostico: reproduzir, minimizar, hipotetizar, instrumentar, corrigir e validar com teste de regressao.');
addSkill('grill-with-docs', 'Entrevista tecnica profunda sobre o plano, confronta decisoes com glossario e ADRs, atualiza documentacao de dominio.');
addSkill('improve-codebase-architecture', 'Encontra oportunidades de aprofundar modulos (mais capacidade com interface menor), melhora testabilidade e navegabilidade.');
addSkill('prototype', 'Cria prototipos descartaveis para validar decisoes rapido: logica/estado (terminal) ou UI com variacoes de design.');
addSkill('setup-matt-pocock-skills', 'Configura base operacional das skills de engenharia (tracker, rotulos de triagem, docs de dominio).');
addSkill('tdd', 'Desenvolvimento orientado a testes com ciclos Red-Green-Refactor, focando comportamento observavel e interfaces publicas.');
addSkill('to-issues', 'Quebra plano/PRD em issues independentes por fatias verticais, com dependencias explicitas e foco em execucao paralelizavel.');
addSkill('to-prd', 'Transforma o contexto atual em PRD estruturado (problema, solucao, historias de usuario, decisoes e escopo).');
addSkill('triage', 'Conduz triagem de issues por maquina de estados, classifica categoria e proximo fluxo.');
addSkill('zoom-out', 'Pedir visao de alto nivel da area de codigo: mapa de modulos, chamadas e impacto sistemico antes de mudancas.');

// Software Development
addCategoryHeader('SOFTWARE DEVELOPMENT', 13);
addSkill('debugging-hermes-tui-commands', 'Debug de comandos slash da TUI do Hermes: Python, gateway, Ink UI.');
addSkill('hermes-agent-skill-authoring', 'Criar skills in-repo: frontmatter, validator, estrutura SKILL.md correta.');
addSkill('hermes-s6-container-supervision', 'Modificar, debugar ou extender a arvore de supervisao s6-overlay no Docker do Hermes.');
addSkill('hermes-setup', 'Guia completo de configuracao do Hermes no Windows: token Telegram, gateway, STT, OAuth Google Workspace.');
addSkill('node-inspect-debugger', 'Debug de Node.js via --inspect + Chrome DevTools Protocol CLI.');
addSkill('plan', 'Modo plano: escrever plano em markdown para .hermes/plans/ sem executar nada.');
addSkill('powershell-wpf-development', 'Desenvolvimento PowerShell com GUI WPF/XAML. Cobre integracao XAML, binding de controles, here-strings, elevacao e erros comuns.');
addSkill('requesting-code-review', 'Review pre-commit: scan de seguridad, quality gates, auto-fix.');
addSkill('spike', 'Experimentos descartaveis para validar uma ideia antes de construir de verdade.');
addSkill('subagent-driven-development', 'Executar planos via delegate_task subagents com revisao em 2 etapas.');
addSkill('systematic-debugging', 'Debug em 4 fases: entender bug, reproduzir, isolar causa raiz, corrigir e testar.');
addSkill('test-driven-development', 'TDD: forcar ciclo RED-GREEN-REFACTOR, testes antes do codigo.');
addSkill('writing-plans', 'Escrever planos de implementacao: tarefas pequenas, caminhos, codigo de referencia.');

// DevOps
addCategoryHeader('DEVOPS', 3);
addSkill('kanban-orchestrator', 'Playbook de decomposicao + regras anti-tentacao para orquestrador Kanban.');
addSkill('kanban-worker', 'Pitfalls, exemplos e edge cases para workers Kanban do Hermes.');
addSkill('webhook-subscriptions', 'Inscricoes webhook: execucoes de agente orientadas a eventos.');

// Autonomous AI Agents
addCategoryHeader('AUTONOMOUS AI AGENTS', 5);
addSkill('claude-code', 'Delegar codigo para Claude Code CLI: features, PRs, revisao.');
addSkill('codex', 'Delegar codigo para OpenAI Codex CLI: features, PRs, revisao.');
addSkill('hermes-agent', 'Configurar, extender ou contribuir para o Hermes Agent.');
addSkill('kanban-codex-lane', 'Usar Codex CLI como laneisolado de implementacao enquanto Hermes mantem ownership do Kanban.');
addSkill('opencode', 'Delegar codigo para OpenCode CLI: features, revisao de PRs.');

// GitHub
addCategoryHeader('GITHUB', 6);
addSkill('codebase-inspection', 'Inspecionar codebases com pygount: LOC, linguagens, proporcoes.');
addSkill('github-auth', 'Setup de auth GitHub: tokens HTTPS, SSH keys, login gh CLI.');
addSkill('github-code-review', 'Review de PRs: diffs, inline comments via gh ou REST API.');
addSkill('github-issues', 'Criar, triar, rotular, atribuir issues via gh ou REST API.');
addSkill('github-pr-workflow', 'Ciclo completo de PR: branch, commit, open, CI, merge.');
addSkill('github-repo-management', 'Clonar/criar/fork repos; gerenciar remotes, releases.');

// Productivity
addCategoryHeader('PRODUCTIVITY', 14);
addSkill('airtable', 'Airtable REST API via curl: CRUD de registros, filtros, upserts.');
addSkill('caveman', 'Modo de comunicacao ultra enxuto. Reduz tokens ~75% mantendo precisao tecnica.');
addSkill('docx-authoring', 'Criar, modificar e traduzir documentos DOCX com python-docx.');
addSkill('google-workspace', 'Gmail, Calendar, Drive, Docs, Sheets via gws CLI ou Python.');
addSkill('grill-me', 'Entrevista intensa sobre plano/design ate eliminar ambiguidade e chegar a decisoes claras.');
addSkill('handoff', 'Compactar conversa atual em documento de passagem para outro agente/sessao.');
addSkill('linear', 'Linear: gerenciar issues, projects, teams via GraphQL + curl.');
addSkill('maps', 'Geocode, POIs, rotas, fusos horarios via OpenStreetMap/OSRM.');
addSkill('nano-pdf', 'Editar texto/titulos em PDF via nano-pdf CLI (prompts em linguagem natural).');
addSkill('notion', 'Notion API + ntn CLI: pages, databases, markdown, Workers.');
addSkill('ocr-and-documents', 'Extrair texto de PDFs/scans (pymupdf, marker-pdf).');
addSkill('powerpoint', 'Criar, ler, editar decks .pptx, slides, notas, templates.');
addSkill('teams-meeting-pipeline', 'Operar pipeline de resumo de reunioes Teams via Hermes CLI.');
addSkill('write-a-skill', 'Criar skills com estrutura correta: gatilhos, modularizacao, referencias/scripts.');

// Creative
addCategoryHeader('CREATIVE', 20);
addSkill('architecture-diagram', 'Diagramas SVG escuros de arquitetura/cloud/infra como HTML.');
addSkill('ascii-art', 'Arte ASCII: pyfiglet, cowsay, boxes, image-to-ascii.');
addSkill('ascii-video', 'Video ASCII: converter video/audio para MP4/GIF colorido em ASCII.');
addSkill('baoyu-article-illustrator', 'Ilustracoes de artigo: tipo x estilo x paleta consistente.');
addSkill('baoyu-comic', 'Quadrinhos educacionais (知识漫画): educacional, biografia, tutorial.');
addSkill('baoyu-infographic', 'Infograficos: 21 layouts x 21 estilos (信息图, visualizacao).');
addSkill('claude-design', 'Design de artefatos HTML unicos (landing, deck, prototipo).');
addSkill('comfyui', 'Gerar imagens, video e audio com ComfyUI via comfy-cli e REST/WebSocket API.');
addSkill('design-md', 'Criar/validar/exportar arquivos DESIGN.md de tokens Google.');
addSkill('excalidraw', 'Diagramas Mao-desenhados em JSON (arquitetura, fluxo, sequencia).');
addSkill('humanizer', 'Humanizar texto: remover AI-isms e adicionar voz natural.');
addSkill('ideation', 'Gerar ideias de projeto via restricoes criativas.');
addSkill('manim-video', 'Animacoes Manim CE: videos de matematica/algoritmo estilo 3Blue1Brown.');
addSkill('p5js', 'Sketches p5.js: arte generativa, shaders, interativo, 3D.');
addSkill('pixel-art', 'Pixel art com paletas de era (NES, Game Boy, PICO-8).');
addSkill('popular-web-designs', '54 design systems reais (Stripe, Linear, Vercel) como HTML/CSS.');
addSkill('pretext', 'Demos criativos com @chenglou/pretex: layout de texto sem DOM, tipografia generativa.');
addSkill('sketch', 'Mockups HTML rapidos: 2-3 variantes de design para comparar.');
addSkill('songwriting-and-ai-music', 'Craft de songwriting e prompts para Suno AI music.');
addSkill('touchdesigner-mcp', 'Controlar TouchDesigner via MCP: criar operadores, parametros, conexoes, Python em tempo real.');

// Media
addCategoryHeader('MEDIA', 7);
addSkill('gif-search', 'Buscar/baixar GIFs do Tenor via curl + jq.');
addSkill('heartmula', 'HeartMuLa: geracao de musica estilo Suno a partir de letras + tags.');
addSkill('social-media-content', 'Extrair texto, metadata e midia de Instagram, Twitter/X, TikTok.');
addSkill('songsee', 'Espectrogramas de audio/features (mel, chroma, MFCC) via CLI.');
addSkill('spotify', 'Spotify: play, buscar, queue, gerenciar playlists e dispositivos.');
addSkill('tts-and-telegram-audio', 'Configuracao TTS, geracao de audio e envio de mensagens de voz via Telegram.');
addSkill('youtube-content', 'Transcricoes de YouTube para summaries, threads, blogs.');

// Research
addCategoryHeader('RESEARCH', 4);
addSkill('arxiv', 'Buscar papers arXiv por keyword, autor, categoria ou ID.');
addSkill('blogwatcher', 'Monitorar blogs e feeds RSS/Atom via blogwatcher-cli.');
addSkill('llm-wiki', 'Wiki LLM do Karpathy: construir/consultar KB markdown interconectada.');
addSkill('polymarket', 'Consultar Polymarket: mercados, precos, orderbooks, historico.');

// ML Ops
addCategoryHeader('ML OPERATIONS', 5);
addSkill('dspy', 'DSPy: programas declarativos de LM, auto-otimizar prompts, RAG.');
addSkill('huggingface-hub', 'HuggingFace hf CLI: buscar/baixar/upload modelos e datasets.');
addSkill('llama-cpp', 'llama.cpp: inferencia local GGUF + descoberta de modelos no HF Hub.');
addSkill('segment-anything-model', 'SAM: segmentacao de imagem zero-shot via pontos, caixas, mascaras.');
addSkill('weights-and-biases', 'W&B: logar experimentos ML, sweeps, registry, dashboards.');

// Email
addCategoryHeader('EMAIL', 1);
addSkill('himalaya', 'Himalaya CLI: email IMAP/SMTP diretamente do terminal.');

// Gaming
addCategoryHeader('GAMING', 1);
addSkill('pokemon-player', 'Jogar Pokemon via emulador headless + leituras de RAM.');

// Smart Home
addCategoryHeader('SMART HOME', 1);
addSkill('openhue', 'Controlar luzes Philips Hue, cenas, comodos via OpenHue CLI.');

// Note-Taking
addCategoryHeader('NOTE-TAKING', 1);
addSkill('obsidian', 'Ler, buscar, criar e editar notas no vault Obsidian.');

// Personal
addCategoryHeader('PERSONAL', 2);
addSkill('edit-article', 'Editar e melhorar artigos: reorganizar secoes, melhorar clareza e qualidade.');
addSkill('obsidian-vault', 'Buscar, criar e gerenciar notas no Obsidian com wikilinks e notas-indice.');

// In-Progress
addCategoryHeader('IN-PROGRESS', 5);
addSkill('review', 'Revisar mudancas desde um ponto fixo em dois eixos: padroes e especificacao.');
addSkill('teach', 'Ensinar uma skill ou conceito ao usuario dentro do workspace.');
addSkill('writing-beats', 'Escrever artigo por batidas narrativas, escolhendo caminho passo a passo.');
addSkill('writing-fragments', 'Coletar fragmentos de escricao em sessao de exploracao, sem impor estrutura cedo.');
addSkill('writing-shape', 'Transformar material bruto em artigo publicavel via conversa iterativa.');

// Deprecated
addCategoryHeader('DEPRECATED', 4);
addSkill('design-an-interface', 'Gerar multiplas propostas de interface bem diferentes usando subagentes paralelos.');
addSkill('qa', 'Sessao interativa de QA em conversa, transformando relatos em issues.');
addSkill('request-refactor-plan', 'Criar plano detalhado de refatoracao em passos pequenos e seguros.');
addSkill('ubiquitous-language', 'Extrair glossario de linguagem ubiqua (DDD), identificar ambiguidades.');
addBodyText('  NOTA: Skills deprecated ainda estao instaladas mas nao sao mais mantidas. Use as skills de engineering como substitutas.');

// Misc
addCategoryHeader('MISC', 4);
addSkill('git-guardrails-claude-code', 'Instalar hooks para bloquear comandos Git perigosos (push forçado, reset --hard, clean).');
addSkill('migrate-to-shoehorn', 'Migrar testes de assertions "as" para @total-typescript/shoehorn.');
addSkill('scaffold-exercises', 'Criar estrutura de exercicios: problemas, solucoes, explicacoes, com lint.');
addSkill('setup-pre-commit', 'Instalar Husky pre-commit hooks com lint-staged (Prettier), type checking e testes.');

// Red-Teaming
addCategoryHeader('REDD-TEAMING', 1);
addSkill('godmode', 'Jailbreak LLMs: Parseltongue, GODMODE, ULTRAPLINIAN. [SOLO PARA SEGURANCA]');

// MCP
addCategoryHeader('MCP', 1);
addSkill('native-mcp', 'Cliente MCP: conectar servidores, registrar ferramentas (stdio/HTTP).');

// ========================================
// COMANDOS ESSENCIAIS
// ========================================
doc.addPage();
addTitle('Comandos Essenciais do Hermes', 18);
doc.moveDown(0.5);

addSectionTitle('Listar e Inspecionar Skills');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  hermes skills list --source local    # Skills locais (customizadas)');
doc.text('  hermes skills list --source builtin  # Skills built-in');
doc.text('  hermes skills search tdd             # Buscar skill por nome');
doc.text('  hermes skills inspect diagnose       # Inspecionar uma skill');
doc.moveDown(0.5);

addSectionTitle('Chat Interativo');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  hermes chat                           # Chat sem skill especifica');
doc.text('  hermes chat -s tdd                    # Chat com skill TDD');
doc.text('  hermes chat -s diagnose,triage         # Chat com multiplas skills');
doc.text('  hermes chat -q "tarefa" -s tdd -Q    # Prompt direto com skill');
doc.moveDown(0.5);

addSectionTitle('No Chat (Slash Commands)');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  /tdd          Test-Driven Development');
doc.text('  /diagnose     Diagnostico de bugs');
doc.text('  /triage       Triagem de issues');
doc.text('  /to-prd       Criar PRD');
doc.text('  /to-issues    Quebrar em issues');
doc.text('  /grill-with-docs  Entrevista de plano');
doc.text('  /handoff      Passagem de contexto');
doc.text('  /zoom-out     Visao de alto nivel');
doc.text('  /prototype    Criar prototipo');
doc.moveDown(0.5);

addSectionTitle('Gerenciar Skills (via agente)');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  skills_list()                          # Lista todas as skills');
doc.text('  skills_list(category="engineering")     # Filtrar por categoria');
doc.text('  skill_view(name="diagnose")            # Carregar skill especifica');
doc.text('  skill_view(name="tdd", file_path="references/api.md")  # Sub-arquivo');
doc.text('  skill_manage(action="create", name="minha-skill", content="...")');
doc.text('  skill_manage(action="patch", name="tdd", old_string="...", new_string="...")');
doc.moveDown(0.5);

addSectionTitle('Memoria e Conhecimento');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  memory(action="add", target="user", content="prefere...")');
doc.text('  memory(action="add", target="memory", content="projeto usa...")');
doc.text('  fact_store(action="add", entity="PowerShell", content="...")');
doc.text('  fact_store(action="probe", entity="PowerShell")');
doc.text('  fact_store(action="reason", entities=["A","B"])');
doc.text('  fact_feedback(action="helpful", fact_id=5)');

// ========================================
// FLUXO POR TAREFA
// ========================================
doc.addPage();
addTitle('Fluxo por Tipo de Tarefa', 18);
doc.moveDown(0.5);

addSectionTitle('Bug Dificil / Regressao');
addBullet('1. /diagnose - Reproduzir, minimizar, hipotetizar, instrumentar, corrigir.');
addBullet('2. /systematic-debugging - Se precisar de abordagem mais estruturada.');
addBullet('3. Validar com teste de regressao.');
doc.moveDown(0.5);

addSectionTitle('Nova Feature com Qualidade');
addBullet('1. /grill-me ou /grill-with-docs - Refinar o plano e decisoes.');
addBullet('2. /to-prd - Documentar como PRD.');
addBullet('3. /to-issues - Quebrar em fatias verticais.');
addBullet('4. /tdd - Implementar cada issue com Red-Green-Refactor.');
addBullet('5. /requesting-code-review - Review pre-commit.');
doc.moveDown(0.5);

addSectionTitle('Refatoracao Grande');
addBullet('1. /zoom-out - Entender impacto sistemico.');
addBullet('2. /improve-codebase-architecture - Identificar oportunidades.');
addBullet('3. /request-refactor-plan (deprecated) ou /to-issues para plano.');
addBullet('4. /subagent-driven-development - Executar em paralelo.');
doc.moveDown(0.5);

addSectionTitle('Projeto Novo (zero a um)');
addBullet('1. /ideation - Gerar ideias via restricoes.');
addBullet('2. /prototype - Validar decisoes rapido.');
addBullet('3. /claude-code - Delegar implementacao (se disponivel).');
addBullet('4. /tdd - Construir com qualidade.');
doc.moveDown(0.5);

addSectionTitle('Projeto PowerShell/WPF (Totem)');
addBullet('1. /powershell-wpf-development - Carregar skill especializada.');
addBullet('2. Garantir que XAML nao tem erros de parsing.');
addBullet('3. Usar FindName (nao VisualTreeHelper) para controles.');
addBullet('4. Validar paths com espacos/acentos.');
addBullet('5. Usar ScriptBlock no lugar de Invoke-Expression.');
addBullet('6. Separar TaskPath e TaskName em ScheduledTasks.');
addBullet('7. Testar parse com [Parser]::ParseFile() antes de executar.');

// ========================================
// ROTEIRO DE TESTE
// ========================================
doc.addPage();
addTitle('Roteiro de Teste em 10 Passos', 18);
doc.moveDown(0.5);

addBodyText('Use este roteiro para validar que todas as skills estao funcionando:');
doc.moveDown(0.3);

const passos = [
  'Confirmar skills instaladas: skills_list(category="engineering")',
  'Validar presenca: tdd, diagnose, triage, to-prd, grill-with-docs',
  'Carregar skill: skill_view(name="tdd") - verificar conteudo',
  'Smoke test: Escrever funcao simples com /tdd',
  'Teste de debug: Introduzir bug intencional e usar /diagnose',
  'Teste de planejamento: Criar PRD com /to-prd para ideia real',
  'Teste de quebra: Usar /to-issues para fatiar o PRD',
  'Teste de triagem: Usar /triage em demandas de exemplo',
  'Teste de passagem: Usar /handoff e verificar documento',
  'Registrar aprendizados em memory/fact_store',
];

passos.forEach((p, i) => {
  doc.font('Helvetica-Bold').fontSize(9).fillColor('#2C3E50');
  doc.text(`${i+1}. `, { continued: true });
  doc.font('Helvetica').fontSize(9).fillColor('#333333');
  doc.text(safeText(p));
  doc.moveDown(0.2);
});

// ========================================
// TROUBLESHOOTING
// ========================================
doc.addPage();
addTitle('Troubleshooting (erros comuns)', 18);
doc.moveDown(0.5);

const erros = [
  ['Unknown skill', 'Verificar se a skill esta em skills_list() e se o arquivo SKILL.md existe.'],
  ['Erro 429', 'Limite de provedor/modelo. Trocar modelo ou aguardar janela de cota.'],
  ['Erro 404 tool use', 'Escolher modelo/provedor com suporte a tool calling.'],
  ['Skill nao aparece no chat', 'Reabrir sessao e confirmar arquivo atecfg. via hermes config path.'],
  ['VisualTreeHelper retorna null', 'So funciona apos ShowDialog. Use FindName ao inves.'],
  ['XamlReader.Load falha', 'Verificar XML valido: tags fechadas, xmlns correto, sem Orientation no Separator.'],
  ['FindName retorna null', 'Verificar x:Name (nao Name), sem SetNameScope apos Load, case-sensitive.'],
  ['Invoke-Expression quebra', 'Usar & $command @args ou ScriptBlock ao inves.'],
  ['Path com espaco falha', 'Sempre usar quotes: & \'/c/path/with spaces/file.exe\''],
  ['Disable-ScheduledTask falha', 'Separar -TaskPath e -TaskName como parametros diferentes.'],
];

erros.forEach(([erro, solucao]) => {
  if (doc.y > 740) doc.addPage();
  doc.font('Helvetica-Bold').fontSize(8.5).fillColor('#C0392B');
  doc.text(`PROBLEMA: ${safeText(erro)}`);
  doc.font('Helvetica').fontSize(8.5).fillColor('#27AE60');
  doc.text(`SOLUCAO:  ${safeText(solucao)}`);
  doc.moveDown(0.3);
});

doc.moveDown(0.5);
addSectionTitle('Diagnostico Minimo');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  hermes config path           # Verificar caminho de skills');
doc.text('  skills_list()                 # Listar skills disponiveis');
doc.text('  skill_view(name="tdd")        # Carregar skill teste');
doc.text('  [Parser]::ParseFile($path)    # Validar sintaxe PS1');

// ========================================
// PLANO DE ESTUDO
// ========================================
doc.addPage();
addTitle('Plano de Estudo (4 semanas)', 18);
doc.moveDown(0.5);

const semanas = [
  ['Semana 1: Fundamentos', [
    'Listar todas as skills com skills_list()',
    'Ler SKILL.md de cada skill de engineering',
    'Fazer smoke test com /tdd e /diagnose',
    'Praticar fact_store e memory',
  ]],
  ['Semana 2: Debug e Qualidade', [
    '/diagnose em 3 bugs reais ou simulados',
    '/tdd para 2 features curtas',
    '/systematic-debugging para bug complexo',
    '/requesting-code-review em codigo pronto',
  ]],
  ['Semana 3: Planejamento e Delegacao', [
    '/to-prd para 1 projeto real',
    '/to-issues para quebrar em fatias',
    '/triage em issues existentes',
    '/subagent-driven-development para tarefa paralela',
    '/handoff para passar contexto',
  ]],
  ['Semana 4: Fluxo Completo', [
    '/prototype para validar ideia',
    '/claude-code ou /codex para delegar',
    '/grill-with-docs para refinar decisoes',
    'Revisar todos os 6 contextos de delegate_task',
    'Criar skill customizada com write-a-skill',
  ]],
];

semanas.forEach(([titulo, tarefas]) => {
  addSectionTitle(titulo);
  tarefas.forEach(t => addBullet(t));
  doc.moveDown(0.3);
});

doc.moveDown(0.5);
addSectionTitle('Metas Mensuraveis');
addBullet('Executar 10 sessoes com skill explicitamente invocada.');
addBullet('Resolver 3 bugs com /diagnose + teste de regressao.');
addBullet('Implementar 2 features curtas com /tdd.');
addBullet('Gerar 1 PRD e quebrar em ao menos 4 issues verticais.');
addBullet('Criar 1 skill customizada com /write-a-skill.');

// ========================================
// RAPIDA REFERENCIA
// ========================================
doc.addPage();
addTitle('Cola Rapida (Cheat Sheet)', 18);
doc.moveDown(0.5);

addSectionTitle('Descoberta');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  skills_list()                              # Todas as skills');
doc.text('  skills_list(category="engineering")         # Por categoria');
doc.text('  skill_view(name="diagnose")                # Carregar skill');
doc.text('  skill_manage(action="create", name="...")  # Criar skill');
doc.moveDown(0.3);

addSectionTitle('Sessao e Chat');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  hermes chat -s tdd                         # Chat com skill');
doc.text('  /tdd                                       # Slash no chat');
doc.text('  delegate_task(goal="...", toolsets=[...])  # Subagente');
doc.moveDown(0.3);

addSectionTitle('Projeto WPF/PowerShell');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  # Carregar skill WPF');
doc.text('  skill_view(name="powershell-wpf-development")');
doc.text('');
doc.text('  # Validar antes de rodar');
doc.text('  [Parser]::ParseFile($path)');
doc.text('');
doc.text('  # Carregar XAML');
doc.text('  $xaml = [xml](Get-Content "ui.xaml")');
doc.text('  $reader = [Xml.XmlNodeReader]::new($xaml)');
doc.text('  $win = [Markup.XamlReader]::Load($reader)');
doc.text('');
doc.text('  # Obter controles (apos Load, antes de ShowDialog)');
doc.text('  $btn = $win.FindName("MyButton")');
doc.text('');
doc.text('  # Executar comando com espaco no path');
doc.text('  & "C:/Program Files/app.exe" /arg1');
doc.text('');
doc.text('  # Auto-elevacao');
doc.text('  Start-Process powershell.exe -ArgumentList @(');
doc.text('    "-NoProfile", "-ExecutionPolicy", "Bypass",');
doc.text('    "-File", "`"$PSCommandPath`"") -Verb RunAs');
doc.moveDown(0.3);

addSectionTitle('Memoria');
doc.font('Courier').fontSize(8).fillColor('#1A5276');
doc.text('  memory(action="add", target="user", content="...")');
doc.text('  fact_store(action="add", entity="X", content="...")');
doc.text('  fact_store(action="probe", entity="X")');
doc.text('  fact_feedback(action="helpful", fact_id=5)');

// Regra de ouro
doc.moveDown(1);
doc.font('Helvetica-Bold').fontSize(12).fillColor('#E74C3C');
doc.text('REGRA DE OURO:', { align: 'center' });
doc.font('Helvetica-Bold').fontSize(10).fillColor('#2C3E50');
doc.text('Problema bem classificado -> skill certa -> execucao mais confiavel.', { align: 'center' });

// ========================================
// FIM
// ========================================
doc.moveDown(2);
doc.font('Helvetica').fontSize(8).fillColor('#999999');
doc.text(`Documento gerado em 28/05/2026 - ${doc.pageCount} paginas - 109 skills - 20 categorias`, { align: 'center' });

doc.end();
console.log(`PDF gerado: ${outputPath}`);
console.log(`Paginas: ${doc.pageCount}`);
