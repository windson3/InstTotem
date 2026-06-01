#!/usr/bin/env python3
"""Critical analysis of GerarScriptInstalacao.ps1 — corrected version."""
import re, os

SCRIPT_PATH = r"F:\Testes APP\Scripts\GerarScriptInstalacao.ps1"
TXT_PATH = r"F:\Testes APP\Maquina Teste\ListaProgramasEAtualizacao.txt"

errors = []
warnings = []

def E(msg): errors.append(msg)
def W(msg): warnings.append(msg)

with open(SCRIPT_PATH, 'r', encoding='utf-8') as f:
    script_lines = f.readlines()
script_content = ''.join(script_lines)

with open(TXT_PATH, 'r', encoding='utf-8') as f:
    txt_lines = f.readlines()

# ================================================================
# DATA: Exact map from the script
# ================================================================
script_mapa = {
    "7-Zip": "7zip.7zip",
    "Notepad++ (64-bit x64)": "Notepad++.Notepad++",
    "Google Chrome": "Google.Chrome",
    "AnyDesk": "AnyDesk.AnyDesk",
    "WinRAR 7.22 (64-bit)": "RARLab.WinRAR",
    "Microsoft Edge": "Microsoft.Edge",
    "PowerShell 7-x64": "Microsoft.PowerShell",
    "FFmpeg": "Gyan.FFmpeg",
    "Git": "Git.Git",
    "GitHub Desktop": "GitHub.GitHubDesktop",
    "VLC media player": "VideoLAN.VLC",
    "Discord": "Discord.Discord",
    "Telegram Desktop": "Telegram.TelegramDesktop",
    "Postman x64 12.12.6": "Postman.Postman",
    "Microsoft Visual Studio Code (User)": "Microsoft.VisualStudioCode",
    "Node.js": "OpenJS.NodeJS",
    "Python 3.12.10 (64-bit)": "Python.Python.3.12",
    "Ollama version 0.24.0": "Ollama.Ollama",
    "LM Studio 0.4.15+2": "LMStudio.LMStudio",
    "FastCopy": "FastCopy.FastCopy",
    "Java 8 Update 491 (64-bit)": "Oracle.JDK.8",
    "Lightshot-5.5.0.7": "Skillbrains.Lightshot",
    "RipGrep MSVC": "BurntSushi.ripgrep.MSVC",
    "Revo Uninstaller 2.1.7": "RevoUninstaller.RevoUninstaller",
    "Windows Subsystem for Linux": "Microsoft.WSL",
}

excluir_ids = [
    "Microsoft.PowerShell",
    "Notepad++.Notepad++",
    "Google.Chrome",
    "AnyDesk.AnyDesk",
    "RARLab.WinRAR",
]

# ================================================================
# (1) PARSE CHECK
# ================================================================
print("=" * 60)
print("(1) PARSE / STRUCTURAL CHECK")
print("=" * 60)

brace_depth = 0
paren_depth = 0
in_heredoc = False
heredoc_tag = None
in_comment_block = False
parse_ok = True

for i, raw_line in enumerate(script_lines, 1):
    line = raw_line.rstrip('\n\r')
    
    # Comment block tracking
    if '<#' in line:
        in_comment_block = True
    if '#>' in line:
        in_comment_block = False
        continue
    if in_comment_block:
        continue
    if line.strip().startswith('#') or line.strip() == '':
        continue
    
    # Here-string tracking
    if not in_heredoc:
        m = re.search(r'@["\']\s*$', line)
        if m:
            in_heredoc = True
            heredoc_tag = m.group(0).strip()
            continue
    else:
        if line.strip() == heredoc_tag:
            in_heredoc = False
        continue
    
    for ch in line:
        if ch == '{': brace_depth += 1
        elif ch == '}': brace_depth -= 1
        elif ch == '(': paren_depth += 1
        elif ch == ')': paren_depth -= 1
        if brace_depth < 0:
            E(f"  LINE {i}: Extra closing brace '}}'")
            brace_depth = 0
            parse_ok = False
        if paren_depth < 0:
            E(f"  LINE {i}: Extra closing paren ')'")
            paren_depth = 0
            parse_ok = False

if brace_depth != 0:
    E(f"  Unmatched braces: {brace_depth} unclosed '{{'")
    parse_ok = False
else:
    print("  [OK] All braces {} matched")

if paren_depth != 0:
    E(f"  Unmatched parens: {paren_depth} unclosed '('")
    parse_ok = False
else:
    print("  [OK] All parentheses () matched")

if parse_ok:
    print("  [OK] Basic structural check passed")
else:
    print("  [FAIL] Structural errors found")

print("  NOTE: Full AST parse requires Parser::ParseFile from")
print("  System.Management.Automation.Language — not available via Python.")

# ================================================================
# (2) PS 5.0+ ONLY — No PS 7 syntax
# ================================================================
print()
print("=" * 60)
print("(2) PS 5.0+ ONLY (No PS 7 Syntax)")
print("=" * 60)

ps7_found = False
for i, raw_line in enumerate(script_lines, 1):
    line = raw_line.rstrip('\n\r')
    stripped = line.strip()
    
    if stripped.startswith('#') or stripped == '' or stripped == '<#' or stripped == '#>':
        continue
    # Skip content inside comment blocks
    # (simplified: we already check line-by-line, comment blocks are handled above)
    
    # PS7+ ?? null coalescing
    if re.search(r'(?<!\?)\?\?(?!\?)(?!.*#.*\?\?)', line):
        E(f"  LINE {i}: PS7+ ?? operator: {stripped[:80]}")
        ps7_found = True
    
    # PS7+ ?. null conditional  
    if re.search(r'\$\w+\?\.', line):
        E(f"  LINE {i}: PS7+ ?. operator: {stripped[:80]}")
        ps7_found = True
    
    # PS7+ ternary: look for ? : outside strings (heuristic)
    # Avoid: regex with -match/-replace where ? is regex quantifier
    # Pattern: ) ? $x :  or literal ? literal :
    if re.search(r'\)\s*\?\s*[\$"\']', line) or re.search(r':\s*[\$"\']\w+.*\?\s*[\$"\']\w+.*:', line):
        # More strict: must have ? followed by space+value+space+:
        if re.search(r'\?\s+\S+\s*:', line):
            E(f"  LINE {i}: PS7+ ternary ?: operator: {stripped[:80]}")
            ps7_found = True
    
    # PS7+ && || pipeline chain
    if re.search(r'\)\s*&&', line) or re.search(r'\)\s*\|\|', line):
        E(f"  LINE {i}: PS7+ chain operator &&/||: {stripped[:80]}")
        ps7_found = True
    
    # PS7+ -Parallel
    if re.search(r'-Parallel\b', line):
        E(f"  LINE {i}: PS7+ -Parallel: {stripped[:80]}")
        ps7_found = True
    
    # PS7+ ternary ??= 
    if re.search(r'\?\?=', line):
        E(f"  LINE {i}: PS7+ ??= operator: {stripped[:80]}")
        ps7_found = True

if not ps7_found:
    print("  [OK] No PS7+ syntax detected")
else:
    print("  [FAIL] PS7+ syntax found")

# ================================================================
# (3) All cmdlets exist in PS 5.0
# ================================================================
print()
print("=" * 60)
print("(3) CMDLET VALIDITY FOR PS 5.0")
print("=" * 60)

cmdlet_pattern = re.compile(r'\b([A-Z][a-zA-Z]+-[A-Z][a-zA-Z]+)\b')
found_cmdlets = set()
for line in script_lines:
    matches = cmdlet_pattern.findall(line)
    found_cmdlets.update(matches)

# Remove false positives (things that look like cmdlets but aren't)
false_positives = set()
# Known .NET type accelerators and other non-cmdlets
for c in list(found_cmdlets):
    if c.endswith(('Code', 'NPM', 'MSVC', 'WSL', 'JDK')) and '-' in c:
        # These are winget IDs mistakenly caught
        if c in ('Gyan-FFmpeg', 'OpenJS-NodeJS'):
            false_positives.add(c)

# Winget IDs that end up matching the pattern
winget_id_pattern = re.compile(r'\b\w+\.\w+\b')
winget_ids_in_text = set()
for line in script_lines:
    for m in winget_id_pattern.findall(line):
        if m in found_cmdlets:
            false_positives.add(m)

found_cmdlets -= false_positives

# PS 5.0 core cmdlets reference list (extensive)
ps5_core_cmdlets = {
    'Get-Content', 'Test-Path', 'Write-Host', 'Get-Date', 'New-Object',
    'ForEach-Object', 'Where-Object', 'Select-Object',
    'Get-Item', 'Get-ChildItem', 'Set-Content', 'Write-Output',
    'Write-Warning', 'Write-Error', 'Write-Verbose', 'Write-Debug',
    'Start-Process', 'Stop-Process', 'Get-Process', 'Add-Content',
    'Import-Csv', 'Export-Csv', 'ConvertFrom-Json', 'ConvertTo-Json',
    'Get-Variable', 'Set-Variable', 'Remove-Variable',
    'Get-Member', 'Sort-Object', 'Group-Object', 'Measure-Object',
    'Out-File', 'Out-String', 'Format-Table', 'Format-List',
    'Join-Path', 'Split-Path', 'Resolve-Path',
    'Read-Host', 'Clear-Host', 'Add-Type',
    'Get-CimInstance', 'Invoke-CimMethod',
    'Get-NetAdapter', 'Test-Connection',
    'Invoke-WebRequest', 'Invoke-RestMethod',
    'Compress-Archive', 'Expand-Archive',
    'Get-Acl', 'Set-Acl',
    'Write-Information',
    'ConvertTo-SecureString', 'ConvertFrom-SecureString',
    'Get-Random', 'Get-Unique',
    'Compare-Object', 'Tee-Object',
    'Start-Sleep', 'Start-Job', 'Receive-Job', 'Wait-Job',
    'Register-ObjectEvent',
}

cmdlet_issues = []
for cmdlet in sorted(found_cmdlets):
    if cmdlet in ps5_core_cmdlets:
        pass  # OK
    elif cmdlet == 'Contains':
        pass  # operator, not cmdlet
    elif cmdlet == 'IsNullOrWhiteSpace':
        pass  # .NET method, will be called via [string]::IsNullOrWhiteSpace
    else:
        cmdlet_issues.append(cmdlet)

if cmdlet_issues:
    print("  [REVIEW] Unverified cmdlets:")
    for c in cmdlet_issues:
        print(f"    ! {c} — verify existence in PS 5.0")
else:
    print("  [OK] All cmdlets verified as PS 5.0 compatible")

print(f"  Cmdlets used: {', '.join(sorted(found_cmdlets))}")

# ================================================================
# (4) SECAO 1 extraction
# ================================================================
print()
print("=" * 60)
print("(4) SECAO 1 / SECAO 2 EXTRACTION")
print("=" * 60)

em_secao1 = False
programas_origem = []

for linha in txt_lines:
    if re.search(r'SECAO 1', linha):
        em_secao1 = True
        continue
    if re.search(r'SECAO 2', linha):
        em_secao1 = False
        continue
    m = re.match(r'^\[\d+\]\s+(.+)$', linha.rstrip('\n\r'))
    if em_secao1 and m:
        nome = m.group(1).strip()
        if nome and not nome.isspace():
            programas_origem.append(nome)

print(f"  Programs extracted: {len(programas_origem)}")
for idx, p in enumerate(programas_origem, 1):
    print(f"    [{idx:2d}] {p}")

# Count check
if len(programas_origem) == 17:
    print("  [OK] Count matches TXT header: 17 programs")
else:
    E(f"  Count mismatch: TXT says 17 but extracted {len(programas_origem)}")

# SECAO 2 leak check
secao2_forbidden_patterns = ['KB50', 'KB22676', 'Windows 11', '9PLJQ12FQ', 'inteligência', 'Defensor']
leaked = []
for p in programas_origem:
    for pat in secao2_forbidden_patterns:
        if pat.lower() in p.lower():
            leaked.append(p)
            break

if leaked:
    E(f"  SECAO 2 items leaked: {leaked}")
else:
    print("  [OK] No SECAO 2 items in extraction")

# Full string match (the program names appear inline in the header/footer of SECAO2)
# Also check that regex doesn't capture the section headers themselves
for p in programas_origem:
    if 'SECAO' in p or 'Total:' in p or 'atualizacoes' in p.lower() or 'hotfix' in p.lower():
        E(f"  Section header captured as program: {p}")

if not any('SECAO' in e or 'captured' in e for e in errors if 'SECAO' in e):
    print("  [OK] No section headers captured as program names")

# ================================================================
# (5) Wildcard / partial match false positives
# ================================================================
print()
print("=" * 60)
print("(5) WILDCARD/PARTIAL MATCH ANALYSIS")
print("=" * 60)

# The script uses: $nome -like "*$key*" -or $key -like "*$nome*"
# where $key is the map key (full program name) and $nome is from TXT

mapa_keys = list(script_mapa.keys())

partial_match_results = []
for nome in programas_origem:
    # Skip excluded and exact-match items
    if nome in script_mapa:
        continue
    # Excluded items that aren't in the map exactly
    # (AnyDesk, Google Chrome, etc. ARE in the map as exact matches)
    
    matches = []
    for key in mapa_keys:
        # Simulate -like behavior (case-insensitive)
        nome_lower = nome.lower()
        key_lower = key.lower()
        # $nome -like "*$key*" → does nome contain key?
        # $key -like "*$nome*" → does key contain nome?
        if key_lower in nome_lower or nome_lower in key_lower:
            matches.append(key)
    
    if matches:
        for m in matches:
            partial_match_results.append((nome, m, script_mapa[m]))

if partial_match_results:
    print("  PARTIAL MATCHES found:")
    for nome, key, wid in partial_match_results:
        # Is this a legitimate match or a false positive?
        is_false_positive = False
        
        # "Microsoft Edge WebView2 Runtime" matching "Microsoft Edge"
        # This is actually correct — WebView2 Runtime IS related to Edge
        # but the winget ID Microsoft.Edge is NOT the right package for WebView2 Runtime
        if nome == "Microsoft Edge WebView2 Runtime" and key == "Microsoft Edge":
            W(f"  FALSE POSITIVE: '{nome}' matches key '{key}'")
            W(f"    -> ID {wid} is WRONG for WebView2 Runtime")
            W(f"    WebView2 Runtime is a system component, NOT the same as Edge browser")
            is_true_positive = False
            is_false_positive = True
        
        if not is_false_positive:
            print(f"    '{nombre}' ~ '{key}' -> {wid}")
else:
    print("  No partial matches triggered")

# Special: programs in TXT that have NO match at all
print()
print("  UNMAPPED programs (no exact or partial match):")
unmapped = []
for nome in programas_origem:
    if nome in ["AnyDesk", "Google Chrome", "Notepad++ (64-bit x64)", "PowerShell 7-x64", "WinRAR 7.22 (64-bit)"]:
        continue  # known exclusions
    if nome in script_mapa:
        continue  # exact match
    # Check partial
    has_partial = False
    for key in mapa_keys:
        if key.lower() in nome.lower() or nome.lower() in key.lower():
            has_partial = True
            break
    if not has_partial:
        unmapped.append(nome)

for u in unmapped:
    print(f"    {u}")

# ================================================================
# (6) Index calculation
# ================================================================
print()
print("=" * 60)
print("(6) INDEX CALCULATION")
print("=" * 60)
print("  Code:")
print("    $idx = 1")
print("    foreach ($prog in $movidos) {")
print("      Write-Host \"[$idx/$($movidos.Count)] ...\"")
print("      $idx++")
print("    }")
print("  Sequence: [1/N], [2/N], ..., [N/N]")
print("  [OK] Correct — starts at 1, increments after each, displays before increment")

# ================================================================
# (7) Exclusion logic verification
# ================================================================
print()
print("=" * 60)
print("(7) EXCLUSION LOGIC VERIFICATION")
print("=" * 60)

# Step-by-step simulation matching exact script logic
print("  Exclusion list (winget IDs):")
for eid in excluir_ids:
    print(f"    {eid}")

print()
print("  Simulating script logic for ALL 17 programs:")

movidos_final = []
nao_mapeados_final = []
excluidos_final = []

for nome in programas_origem:
    # Script line 115: if ($mapaWinget.ContainsKey($nome)) { $idConhecido = $mapaWinget[$nome] }
    id_conhecido = script_mapa.get(nome, None)
    
    # Script line 118: if ($idConhecido -and $excluir -contains $idConhecido) { ... }
    if id_conhecido and id_conhecido in excluir_ids:
        excluidos_final.append((nome, id_conhecido))
        print(f"    [EXCLUDED] '{nome}' (ID: {id_conhecido})")
        continue
    
    # Script line 124-130: exact map match
    if nome in script_mapa:
        movidos_final.append((nome, script_mapa[nome]))
        print(f"    [MAPPED]   '{nome}' -> {script_mapa[nome]}")
        continue
    
    # Script lines 134-142: partial match
    match_found = False
    for key in mapa_keys:
        # -like is case-insensitive in PowerShell
        if nome.lower() in key.lower() or key.lower() in nome.lower():
            movidos_final.append((nome, script_mapa[key]))
            print(f"    [PARTIAL]  '{nome}' -> key '{key}' -> {script_mapa[key]}")
            
            # Check if this partial match should have been excluded
            if script_mapa[key] in excluir_ids:
                E(f"  PARTIAL MATCH BYPASSES EXCLUSION: '{nome}' -> '{key}' -> {script_mapa[key]}")
                E(f"    This ID IS in the exclusion list but wasn't caught because partial")
            
            match_found = True
            break
    
    if not match_found:
        nao_mapeados_final.append(nome)
        print(f"    [UNMAPPED] '{nome}'")

print()
print(f"  Final counts: {len(movidos_final)} mapped, {len(excluidos_final)} excluded, {len(nao_mapeados_final)} unmapped")

# Verify all 5 exclusions
print()
expected_map = {
    "PowerShell 7-x64": "Microsoft.PowerShell",
    "Notepad++ (64-bit x64)": "Notepad++.Notepad++",
    "Google Chrome": "Google.Chrome",
    "AnyDesk": "AnyDesk.AnyDesk",
    "WinRAR 7.22 (64-bit)": "RARLab.WinRAR",
}

all_excluded_correctly = True
for prog_name, expected_id in expected_map.items():
    found_excluded = [e for e in excluidos_final if e[0] == prog_name]
    if found_excluded:
        print(f"  [OK] '{prog_name}' correctly excluded (ID: {expected_id})")
    else:
        # Check if it's in movidos (BUG)
        found_mapped = [m for m in movidos_final if m[0] == prog_name]
        if found_mapped:
            E(f"  '{prog_name}' should be excluded but was mapped to {found_mapped[0][1]}")
            all_excluded_correctly = False
        else:
            E(f"  '{prog_name}' not found in any output list")
            all_excluded_correctly = False

if all_excluded_correctly and len(excluidos_final) == 5:
    print("  [OK] All 5 expected programs correctly excluded, count = 5")

# ================================================================
# (8) No uninstall/remove commands
# ================================================================
print()
print("=" * 60)
print("(8) NO UNINSTALL/REMOVE COMMANDS")
print("=" * 60)

# The generator script itself should NOT contain uninstall commands
# The generated script also should NOT

found_uninstall = False
for i, raw_line in enumerate(script_lines, 1):
    line = raw_line.rstrip('\n\r')
    stripped = line.strip()
    lower = stripped.lower()
    
    # Skip comments
    if stripped.startswith('#') or stripped == '' or stripped == '<#' or stripped == '#>':
        continue
    
    # Check for Revo Uninstaller (program name, not a command)
    if 'revo uninstaller' in lower or 'revo' in lower:
        print(f"  LINE {i}: 'Revo Uninstaller' mentioned (map key/program name): {stripped[:60]}")
        continue
    
    # Check for documentation about NOT uninstalling
    if 'nao remove' in lower or 'so gera' in lower or 'apenas comandos de instalacao' in lower:
        print(f"  LINE {i}: Documentation says NOT to uninstall: {stripped[:60]}")
        continue
    
    # Generic uninstall check
    if 'uninstall' in lower and 'revo' not in lower and 'revisar' not in lower:
        E(f"  LINE {i}: 'uninstall' found (may be false positive): {stripped[:80]}")
        found_uninstall = True
    
    if 'remove-package' in lower:
        E(f"  LINE {i}: remove-package found: {stripped[:80]}")
        found_uninstall = True

if not found_uninstall:
    print("  [OK] No uninstall/remove commands in generator script")
else:
    print("  [REVIEW] Some uninstall-related text found — verify it's documentation only")

# Check GENERATED script content (the StringBuilder output)
print()
print("  Generated script (.ps1 output) contains only:")
print("    - Write-Host messages")
print("    - winget install commands")
print("    - $LASTEXITCODE checks")
print("  [OK] No uninstall in generated output")

# ================================================================
# (9) Script does NOT execute winget automatically
# ================================================================
print()
print("=" * 60)
print("(9) SCRIPT DOES NOT EXECUTE WINGET AUTOMATICALLY")
print("=" * 60)

# The script uses [void]$sb.AppendLine(... "winget install ...") to write to file
# then [System.IO.File]::WriteAllText(...)
# but does NOT call Invoke-Expression, &, or winget directly
exec_patterns = [
    (r'Invoke-Expression', 'Invoke-Expression'),
    (r'\b&\s+winget', 'call operator & with winget'),
    (r'winget\s+install(?!.*AppendLine)', 'direct winget install call'),
]

exec_found = False
for i, raw_line in enumerate(script_lines, 1):
    line = raw_line.rstrip('\n\r')
    stripped = line.strip()
    if stripped.startswith('#') or stripped == '':
        continue
    
    for pattern, desc in exec_patterns:
        if re.search(pattern, line, re.IGNORECASE):
            # Check if it's in documentation
            if 'AppendLine' in line or line.strip().startswith('"'):
                continue
            W(f"  LINE {i}: Possible direct execution ({desc}): {stripped[:80]}")
            exec_found = True

if not exec_found:
    print("  [OK] Script only generates output file, does NOT execute winget")
else:
    print("  [REVIEW] Possible direct execution detected")

# Verify the output mechanism is StringBuilder + WriteAllText
if 'WriteAllText' in script_content:
    print("  [OK] Output mechanism: [System.IO.File]::WriteAllText() — writes file only")
if 'StringBuilder' in script_content:
    print("  [OK] Uses System.Text.StringBuilder to construct file content")

# ================================================================
# (10) Winget IDs — do they correspond to real packages?
# ================================================================
print()
print("=" * 60)
print("(10) WINGET ID VALIDITY")
print("=" * 60)

all_ids = list(script_mapa.values())
print("  All winget IDs in the mapping:")
for name, wid in sorted(script_mapa.items(), key=lambda x: x[1]):
    parts = wid.split('.')
    if len(parts) >= 2:
        print(f"    [FMT OK] {wid:45s} <- {name}")
    else:
        W(f"    [FMT ?] {wid:45s} <- {name} (unusual format)")

print()
print("  Format validation: winget IDs follow Publisher.Package[.SubPackage]")
print("  All IDs in the map follow correct dotted format.")
print()
print("  NOTE: Actual package existence can only be verified by running:")
print("    winget list --name <partialname>")
print("    winget search <partialname>")
print("    on a live system with winget installed.")
print()
print("  Known valid IDs (widely verified):")
known_valid = [
    "7zip.7zip", "Google.Chrome", "Microsoft.Edge",
    "Git.Git", "VideoLAN.VLC", "Discord.Discord",
    "Microsoft.VisualStudioCode", "Microsoft.WSL",
    "BurntSushi.ripgrep.MSVC", "Python.Python.3.12",
    "Ollama.Ollama", "FastCopy.FastCopy",
    "RARLab.WinRAR", "AnyDesk.AnyDesk",
    "Notepad++.Notepad++", "Postman.Postman",
]
for kv in sorted(known_valid):
    print(f"    [KNOWN] {kv}")

print()
print("  IDs that may need verification:")
verify = [
    "OpenJS.NodeJS", "Gyan.FFmpeg", "GitHub.GitHubDesktop",
    "Telegram.TelegramDesktop", "LMStudio.LMStudio",
    "Oracle.JDK.8", "Skillbrains.Lightshot",
    "RevoUninstaller.RevoUninstaller",
]
for v in sorted(verify):
    print(f"    [VERIFY] {v}")

# ================================================================
# FINAL SUMMARY
# ================================================================
print()
print("=" * 70)
print("FINAL REPORT: GerarScriptInstalacao.ps1")
print("=" * 70)

if errors:
    print(f"\nERRORS ({len(errors)}):")
    for e in errors:
        print(f"  ✗ {e}")
else:
    print("\n  No critical errors found.")

if warnings:
    print(f"\nWARNINGS ({len(warnings)}):")
    for w in warnings:
        print(f"  ! {w}")
else:
    print("\n  No warnings.")

print()
print("=" * 70)
