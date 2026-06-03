# -*- coding: utf-8 -*-
import fpdf
import markdown
import re
import os
import sys

# Force UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

# Read the markdown file
with open(r"c:\Testes APP\Instalação Totem\InstTotem\GUIA_COMPLETO_SKILLS.md", "r", encoding="utf-8") as f:
    md_content = f.read()

# Convert markdown to HTML
html = markdown.markdown(md_content, extensions=["tables", "fenced_code"])

def strip_html(html_text):
    """Convert HTML to plain text for PDF rendering."""
    # Remove code blocks first (keep content)
    html_text = re.sub(r"<pre[^>]*>(.*?)</pre>", r"\n\1\n", html_text, flags=re.DOTALL)
    # Headers
    html_text = re.sub(r"<h1[^>]*>(.*?)</h1>", r"\n\n# \1\n", html_text, flags=re.DOTALL)
    html_text = re.sub(r"<h2[^>]*>(.*?)</h2>", r"\n\n## \1\n", html_text, flags=re.DOTALL)
    html_text = re.sub(r"<h3[^>]*>(.*?)</h3>", r"\n\n### \1\n", html_text, flags=re.DOTALL)
    html_text = re.sub(r"<h4[^>]*>(.*?)</h4>", r"\n\n#### \1\n", html_text, flags=re.DOTALL)
    # Bold/italic
    html_text = re.sub(r"<strong[^>]*>(.*?)</strong>", r"\1", html_text, flags=re.DOTALL)
    html_text = re.sub(r"<b[^>]*>(.*?)</b>", r"\1", html_text, flags=re.DOTALL)
    html_text = re.sub(r"<em[^>]*>(.*?)</em>", r"\1", html_text, flags=re.DOTALL)
    html_text = re.sub(r"<i[^>]*>(.*?)</i>", r"\1", html_text, flags=re.DOTALL)
    # Code inline
    html_text = re.sub(r"<code[^>]*>(.*?)</code>", r"\1", html_text, flags=re.DOTALL)
    # Lists
    html_text = re.sub(r"<li[^>]*>(.*?)</li>", r"  - \1\n", html_text, flags=re.DOTALL)
    html_text = re.sub(r"<[ou]l[^>]*>", "", html_text, flags=re.DOTALL)
    html_text = re.sub(r"</[ou]l>", "", html_text, flags=re.DOTALL)
    # Paragraphs
    html_text = re.sub(r"<br\s*/?>", "\n", html_text)
    html_text = re.sub(r"<p[^>]*>", "\n", html_text)
    html_text = re.sub(r"</p>", "\n", html_text)
    # Links - keep text only
    html_text = re.sub(r"<a[^>]*>(.*?)</a>", r"\1", html_text, flags=re.DOTALL)
    # HR
    html_text = re.sub(r"<hr\s*/?>", "\n---\n", html_text)
    # Remove all remaining tags
    html_text = re.sub(r"<[^>]+>", "", html_text)
    # Decode entities
    html_text = html_text.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    html_text = html_text.replace("&quot;", '"').replace("&#39;", "'").replace("&nbsp;", " ")
    html_text = html_text.replace("&#8211;", "-").replace("&#8212;", "-").replace("&#8216;", "'").replace("&#8217;", "'")
    html_text = html_text.replace("&#8220;", '"').replace("&#8221;", '"').replace("&#8230;", "...")
    # Clean whitespace
    html_text = re.sub(r"\n{3,}", "\n\n", html_text)
    return html_text.strip()

text = strip_html(html)

# Find Unicode font
font_paths = [
    "C:/Windows/Fonts/arial.ttf",
    "C:/Windows/Fonts/segoeui.ttf",
    "C:/Windows/Fonts/calibri.ttf",
]

unicode_font = None
for fp in font_paths:
    if os.path.exists(fp):
        unicode_font = fp
        break

print(f"Unicode font: {unicode_font}")

# Create PDF
pdf = fpdf.FPDF()
pdf.set_auto_page_break(auto=True, margin=15)

if unicode_font:
    try:
        pdf.add_font("Unicode", "", unicode_font)
        bold_path = unicode_font.replace("arial.ttf", "arialbd.ttf").replace("segoeui.ttf", "seguisb.ttf").replace("calibri.ttf", "calibrib.ttf")
        if os.path.exists(bold_path) and bold_path != unicode_font:
            pdf.add_font("Unicode", "B", bold_path)
        main_font = "Unicode"
        print(f"Using Unicode font: {unicode_font}")
    except Exception as e:
        print(f"Font load failed: {e}, falling back to Helvetica")
        main_font = "Helvetica"
else:
    main_font = "Helvetica"
    print("No Unicode font found, using Helvetica")

def safe_text(text):
    """Make text safe for PDF rendering."""
    # Map common Unicode chars to ASCII equivalents
    replacements = {
        "\u2014": "-", "\u2013": "-", "\u201c": '"', "\u201d": '"',
        "\u2018": "'", "\u2019": "'", "\u2026": "...",
        "\u2022": "-", "\u2192": "->", "\u2190": "<-",
        "\u2713": "[OK]", "\u2717": "[FAIL]",
        "\u2500": "-", "\u2502": "|", "\u250c": "+", "\u2510": "+",
        "\u2514": "+", "\u2518": "+", "\u251c": "+", "\u2524": "+",
        "\u252c": "+", "\u2534": "+", "\u253c": "+",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    
    # Remove any remaining non-ASCII chars that would crash fpdf2
    if main_font == "Helvetica":
        result = []
        for ch in text:
            if ord(ch) < 128:
                result.append(ch)
            else:
                # Try to find ASCII equivalent
                import unicodedata
                try:
                    name = unicodedata.name(ch, "")
                    # Common mappings
                    if "LATIN SMALL LETTER A WITH" in name: result.append("a")
                    elif "LATIN SMALL LETTER E WITH" in name: result.append("e")
                    elif "LATIN SMALL LETTER I WITH" in name: result.append("i")
                    elif "LATIN SMALL LETTER O WITH" in name: result.append("o")
                    elif "LATIN SMALL LETTER U WITH" in name: result.append("u")
                    elif "LATIN SMALL LETTER C WITH" in name: result.append("c")
                    elif "LATIN SMALL LETTER N WITH" in name: result.append("n")
                    elif "LATIN CAPITAL LETTER A WITH" in name: result.append("A")
                    elif "LATIN CAPITAL LETTER E WITH" in name: result.append("E")
                    elif "LATIN CAPITAL LETTER I WITH" in name: result.append("I")
                    elif "LATIN CAPITAL LETTER O WITH" in name: result.append("O")
                    elif "LATIN CAPITAL LETTER U WITH" in name: result.append("U")
                    elif "LATIN CAPITAL LETTER C WITH" in name: result.append("C")
                    elif "LATIN CAPITAL LETTER N WITH" in name: result.append("N")
                    else: result.append("?")
                except:
                    result.append("?")
        text = "".join(result)
    return text

lines = text.split("\n")
total_lines = len(lines)
print(f"Processing {total_lines} lines...")

for line_num, line in enumerate(lines):
    if pdf.get_y() > 265:
        pdf.add_page()
    
    stripped = line.strip()
    
    if not stripped:
        pdf.ln(2)
        continue
    
    safe = safe_text(stripped)
    
    # Skip empty after sanitization
    if not safe.strip():
        pdf.ln(2)
        continue
    
    try:
        if safe.startswith("# "):
            pdf.add_page()
            title = safe[2:]
            pdf.set_font(main_font, "B", 18)
            pdf.set_text_color(30, 30, 120)
            pdf.multi_cell(0, 9, title)
            pdf.ln(4)
            pdf.set_draw_color(30, 30, 120)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(4)
        elif safe.startswith("## "):
            pdf.add_page()
            title = safe[3:]
            pdf.set_font(main_font, "B", 14)
            pdf.set_text_color(50, 50, 100)
            pdf.multi_cell(0, 7, title)
            pdf.ln(2)
            pdf.set_draw_color(100, 100, 180)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(2)
        elif safe.startswith("### "):
            title = safe[4:]
            pdf.set_font(main_font, "B", 11)
            pdf.set_text_color(60, 60, 60)
            pdf.multi_cell(0, 5, title)
            pdf.ln(1)
        elif safe.startswith("#### "):
            title = safe[5:]
            pdf.set_font(main_font, "B", 10)
            pdf.set_text_color(80, 80, 80)
            pdf.multi_cell(0, 5, title)
            pdf.ln(1)
        elif safe == "---":
            pdf.set_draw_color(180, 180, 180)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(2)
        elif safe.startswith("|"):
            cells = [c.strip() for c in safe.split("|")[1:-1]]
            if cells:
                # Skip separator rows
                if all(re.match(r"^[-:]+$", c.replace(" ", "")) for c in cells if c):
                    continue
                pdf.set_font(main_font, "", 6)
                pdf.set_text_color(60, 60, 60)
                col_widths = [55, 45, 70]
                for i, cell in enumerate(cells[:3]):
                    w = col_widths[i] if i < len(col_widths) else 40
                    truncated = cell[:28]
                    pdf.cell(w, 3.5, truncated, border=0)
                pdf.ln(3.5)
        elif safe.startswith("- ") or safe.startswith("  - "):
            indent = 4 if safe.startswith("  - ") else 0
            bullet_text = safe.lstrip("- ").strip()
            pdf.set_font(main_font, "", 8)
            pdf.set_text_color(40, 40, 40)
            pdf.set_x(10 + indent)
            pdf.multi_cell(0, 4, "  - " + bullet_text)
        elif safe.startswith("```"):
            continue
        else:
            pdf.set_font(main_font, "", 8)
            pdf.set_text_color(30, 30, 30)
            pdf.multi_cell(0, 4, safe)
    except Exception as e:
        # Skip problematic lines
        print(f"Warning: skipped line {line_num}: {e}")
        continue

output_pdf = r"c:\Testes APP\Instalação Totem\InstTotem\GUIA_COMPLETO_SKILLS.pdf"
pdf.output(output_pdf)
print(f"\nPDF gerado: {output_pdf}")
print(f"Total de paginas: {pdf.page_no()}")
