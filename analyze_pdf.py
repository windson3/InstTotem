import json, re

with open(r"C:\Testes APP\Instalação Totem\InstTotem\pdf_content.json", "r", encoding="utf-8") as f:
    data = json.load(f)

pages = data["pages"]

# Extract all skill names and descriptions
all_skills = []
current_category = ""

for page in pages:
    text = page["text"]
    lines = text.split("\n")
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # Detect category headers (all caps lines with no description)
        if re.match(r'^[A-Z][A-Z\s&]+$', line) and len(line) > 2:
            current_category = line
            continue
        
        # Skip page numbers and footer lines
        if re.match(r'^\d+$', line):
            continue
        if 'OWL Agent' in line or 'ZOO Company' in line or 'Hermes Framework' in line:
            continue
        if line == 'Sumario' or line == 'Fundamentos':
            continue
        
        # Skip lines that are just "(XX)" counts
        if re.match(r'^\(\d+\)$', line):
            continue
        
        # Skip "Skill especializada" markers
        if line == 'Skill especializada':
            continue
        
        # Skip "XX skills" count lines
        if re.match(r'^\d+ skills?$', line):
            continue
        
        # Everything else is likely a skill name or description
        if line and len(line) > 1:
            all_skills.append({
                "category": current_category,
                "text": line
            })

# Deduplicate
seen = set()
unique = []
for s in all_skills:
    key = s["text"].lower().strip()
    if key not in seen and len(key) > 2:
        seen.add(key)
        unique.append(s)

# Group by category
from collections import defaultdict
by_cat = defaultdict(list)
for s in unique:
    by_cat[s["category"]].append(s["text"])

print("=" * 60)
print(f"ANALISE DO PDF: Tutorial Skills COMPLETO")
print(f"Total de paginas: {data['metadata']['pages']}")
print(f"Total de entradas unicas: {len(unique)}")
print("=" * 60)

print("\n=== SKILLS POR CATEGORIA ===")
for cat, skills in sorted(by_cat.items()):
    if cat:
        print(f"\n--- {cat} ({len(skills)} skills) ---")
        for s in skills[:5]:
            print(f"  - {s}")
        if len(skills) > 5:
            print(f"  ... e mais {len(skills)-5}")

# Also extract full text for content analysis
full_text = "\n".join(p["text"] for p in pages)

# Check for key sections
print("\n=== ESTRUTURA DO DOCUMENTO ===")
sections = []
for page in pages:
    text = page["text"]
    # Find category headers in page
    for line in text.split("\n"):
        if re.match(r'^[A-Z][A-Z\s&]+$', line.strip()) and len(line.strip()) > 2:
            sections.append((page["page"], line.strip()))

for page_num, section in sections:
    print(f"  Pag {page_num}: {section}")

# Check document quality indicators
print("\n=== INDICADORES DE QUALIDADE ===")
print(f"  Paginas com conteudo: {len(pages)}/{data['metadata']['pages']}")
print(f"  Tem TOC (sumario): {'Sim' if any('Sumario' in p['text'] for p in pages) else 'Nao'}")
print(f"  Tem numeracao de paginas: {'Sim' if any(re.search(r'^\d+$', p['text'].strip().split('\n')[-1]) for p in pages[:5]) else 'Nao'}")
print(f"  Footer consistente: {'Sim' if all('OWL Agent' in p['text'] or 'ZOO Company' in p['text'] for p in pages[:10]) else 'Nao'}")

# Check for encoding issues
encoding_issues = 0
for page in pages:
    if '�' in page['text'] or '???' in page['text']:
        encoding_issues += 1
print(f"  Paginas com problemas de encoding: {encoding_issues}")

# Check for empty/minimal pages
empty_pages = 0
for page in pages:
    lines = [l for l in page["text"].split("\n") if l.strip() and not re.match(r'^\d+$', l.strip()) 
             and 'OWL Agent' not in l and 'ZOO Company' not in l]
    if len(lines) < 3:
        empty_pages += 1
print(f"  Paginas vazias/minimas: {empty_pages}")

print("\n=== PAGINAS COM PROBLEMAS ===")
for page in pages:
    text = page["text"]
    issues = []
    if '�' in text:
        issues.append("encoding")
    if len(text.strip()) < 50:
        issues.append("curta")
    if "Skill especializada" in text and len([l for l in text.split("\n") if l.strip()]) < 5:
        issues.append("só marcador")
    if issues:
        print(f"  Pag {page['page']}: {', '.join(issues)} -> {text[:100]}")

print("\n=== ANALISE COMPLETA ===")
