from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageColor, PdfParser
import numpy as np
import hashlib
import csv
import re
import json
import sys
from io import BytesIO

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from padronizar_cores import padronizar_fundos
from traduzir_medidas import traduzir_medidas
W, H = 1920, 1080
BG = '#F8FAFC'
INK = '#132B3B'
MUTED = '#486174'
with (ROOT / 'paleta_graficos.csv').open(encoding='utf-8-sig', newline='') as f:
    COLORS = {row['species']: row['hex'] for row in csv.DictReader(f) if row['species'] != 'Todos'}
checks = []


def font(size, bold=False):
    name = 'arialbd.ttf' if bold else 'arial.ttf'
    return ImageFont.truetype('C:/Windows/Fonts/' + name, size)


def text(draw, value, x, y, size=30, bold=False, fill=INK, align='left'):
    f = font(size, bold)
    width = draw.textlength(value, font=f)
    if align == 'center':
        x -= width / 2
    elif align == 'right':
        x -= width
    box = draw.textbbox((x, y), value, font=f)
    assert box[0] >= 0 and box[1] >= 0 and box[2] <= W and box[3] <= H, (value, box)
    checks.append({'texto': value, 'caixa': list(box)})
    draw.text((x, y), value, font=f, fill=fill)


def wrap(draw, value, x, y, width, size=30, fill=INK):
    line = ''
    for word in value.split():
        candidate = (line + ' ' + word).strip()
        if line and draw.textlength(candidate, font=font(size)) > width:
            text(draw, line, x, y, size=size, fill=fill)
            y += size + 12
            line = word
        else:
            line = candidate
    if line:
        text(draw, line, x, y, size=size, fill=fill)
    return y + size + 12


def opaque(image):
    image = image.convert('RGBA')
    base = Image.new('RGBA', image.size, 'white')
    return Image.alpha_composite(base, image).convert('RGB')


def place(page, image, x, y, width, height):
    image = ImageOps.contain(image, (width, height), Image.Resampling.LANCZOS)
    page.paste(image, (round(x + (width - image.width) / 2), round(y + (height - image.height) / 2)))


def header(page, number, stage, title, subtitle=None):
    d = ImageDraw.Draw(page)
    text(d, stage, 96, 48, size=26, fill=MUTED)
    text(d, 'Tela de apoio ' + str(number) + '/2', W - 96, 48, size=24, fill=MUTED, align='right')
    text(d, title, 96, 107, size=60, bold=True)
    if subtitle:
        wrap(d, subtitle, 96, 190, 1728, size=31, fill=MUTED)
    return d


with (ROOT / 'resumo_especies.csv').open(encoding='utf-8-sig', newline='') as f:
    groups = {r['species']: r for r in csv.DictReader(f)}
with (ROOT / 'resumo_geral.csv').open(encoding='utf-8-sig', newline='') as f:
    overall = next(csv.DictReader(f))
assert int(overall['n']) == 342 and int(overall['excluidos']) == 2

page1 = Image.new('RGB', (W, H), BG)
d = header(page1, 1, 'Antes da animação', 'Medidas do bico e espécies do estudo')
text(d, 'As duas medidas', 96, 223, size=36, bold=True)
text(d, 'As três espécies', 1030, 223, size=36, bold=True)
d.line((960, 240, 960, 950), fill='#D8E1E8', width=2)

bill = opaque(Image.open(traduzir_medidas(ROOT)))
# Preserva as setas e usa os rótulos traduzidos; a nota longa inferior fica fora do recorte.
bill = bill.crop((0, 0, bill.width, round(bill.height * 0.65)))
place(page1, bill, 96, 287, 820, 350)
text(d, 'Comprimento', 110, 670, size=34, bold=True)
wrap(d, 'Da base à ponta, pela parte superior do bico.', 110, 718, 790, size=32)
text(d, 'Profundidade', 110, 798, size=34, bold=True)
wrap(d, 'Altura do bico, de cima para baixo.', 110, 846, 790, size=32)
text(d, 'As duas medidas estão em milímetros.', 110, 929, size=28, fill=MUTED)

species = opaque(Image.open(padronizar_fundos(ROOT)))
place(page1, species, 1030, 287, 800, 480)
for key, label, fraction in [('Chinstrap', 'Chinstrap', .22), ('Gentoo', 'Gentoo', .50), ('Adelie', 'Adélie', .80)]:
    center = 1030 + 800 * fraction
    text(d, label, center, 790, size=35, bold=True, fill=COLORS[key], align='center')
    text(d, groups[key]['n'] + ' pinguins', center, 843, size=26, fill=MUTED, align='center')
    text(d, COLORS[key], center, 884, size=23, fill=COLORS[key], align='center')
text(d, 'Fundos e nomes seguem a paleta dos gráficos.', 1030, 929, size=27, fill=MUTED)
d.line((96, 985, 1824, 985), fill='#D8E1E8', width=2)
text(d, 'Ilustrações: Allison Horst (@allison_horst) · fundos adaptados; rótulos das medidas traduzidos.', 96, 1001, size=20, fill=MUTED)

inicio_tela2 = len(checks)
page2 = Image.new('RGB', (W, H), BG)
d = header(page2, 2, 'Depois da animação', 'Misturar espécies muda a comparação',
           'Uma tendência negativa no conjunto; três positivas dentro das espécies.')
place(page2, opaque(Image.open(ROOT / 'comparacao_geral.png')), 96, 252, 844, 544)
place(page2, opaque(Image.open(ROOT / 'comparacao_especies.png')), 980, 252, 844, 544)
text(d, '342 pinguins: a mesma amostra nas duas leituras.', 110, 802, size=27, fill=MUTED)
values = []
for key, label in [('Adelie', 'Adélie'), ('Chinstrap', 'Chinstrap'), ('Gentoo', 'Gentoo')]:
    values.append(label + ' ' + format(float(groups[key]['r']), '+.3f').replace('.', ','))
text(d, '  |  '.join(values), 990, 802, size=27, fill=MUTED)
d.rounded_rectangle((96, 864, 1824, 984), radius=18, fill='#E8F0F5')
text(d, 'O clustering identifica grupos de observações semelhantes nos dados.', 126, 883, size=32)
text(d, 'Aqui, usamos as espécies já conhecidas para separar os dados, sem aplicar um algoritmo de clustering.', 126, 935, size=29, fill=MUTED)
text(d, 'Paradoxo de Simpson · correlação não demonstra causa e efeito.', 96, 1000, size=23, fill=MUTED)
text(d, 'Dados: Palmer Penguins; Horst, Hill e Gorman (2022), figura 5. Texto e montagem com assistência de IA.', 96, 1038, size=19, fill=MUTED)

page1.save(ROOT / 'apoio_antes_cores_conferidas.png')
page2.save(ROOT / 'apoio_depois_cores_conferidas.png')
pdf_path = ROOT / 'paginas_de_apoio_cores_conferidas.pdf'
# RGBA usa JPEG2000 sem perdas; RGB usaria JPEG e deslocaria alguns valores cromáticos.
page1.convert('RGBA').save(pdf_path, 'PDF', save_all=True, append_images=[page2.convert('RGBA')],
           resolution=144, title='Medidas do bico e inversão da correlação')
pdf = PdfParser.PdfParser(filename=str(pdf_path))
assert len(pdf.pages) == 2, len(pdf.pages)
K = PdfParser.PdfName
for ref, expected in zip(pdf.pages, (page1, page2)):
    page = pdf.read_indirect(ref)
    objects = page[K('Resources')][K('XObject')]
    stream = pdf.read_indirect(next(iter(objects.values())))
    embedded = Image.open(BytesIO(stream.buf)).convert('RGB')
    assert np.array_equal(np.asarray(embedded), np.asarray(expected)), 'PDF alterou os pixels'
pdf.close()

# O texto simples vem da mesma fonte canônica do roteiro, sem criar outra versão.
md = (ROOT / 'roteiro_pinguins.md').read_text(encoding='utf-8')
sections = re.split(r'(?m)^## ', md)[1:5]
spoken = []
for section in sections:
    body = section.partition('\n')[2]
    if '**Fala:**' in body:
        spoken.append(body.split('**Fala:**', 1)[1].strip())
    else:
        spoken.append('\n\n'.join(line for line in body.splitlines() if line.strip() and not line.startswith('**')))
narration = '\n\n'.join(spoken) + '\n'
assert (ROOT / 'narracao.txt').read_text(encoding='utf-8') == narration, 'Narração divergente; não será sobrescrita'
words = len(re.findall(r'\b\w+\b', narration))
report = {'paginas_pdf': 2, 'resolucao_paginas': [W, H], 'blocos_de_fala': len(spoken),
          'palavras_narracao': words, 'leitura_aproximada_segundos_a_130_ppm': round(words / 130 * 60),
          'limites_de_texto_verificados': len(checks), 'pdf_com_paginas_rasterizadas': True,
          'cores_dos_graficos': COLORS, 'pdf_sem_perdas_verificado': True,
          'textos_por_tela': {'1': [item['texto'] for item in checks[:inicio_tela2]],
                              '2': [item['texto'] for item in checks[inicio_tela2:]]}}
(ROOT / 'verificacao_paginas_cores_conferidas.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False, indent=2))
