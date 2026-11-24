from pathlib import Path
from PIL import Image, PdfParser, ImageColor
from io import BytesIO
import csv
import hashlib
import json
import numpy as np

ROOT = Path(__file__).resolve().parent
adapted = ROOT / 'especies_paleta_graficos.png'
if not adapted.exists():
    raise AssertionError('RED: os fundos da ilustração ainda não foram padronizados com a paleta do gráfico')
with (ROOT / 'paleta_graficos.csv').open(encoding='utf-8-sig', newline='') as f:
    palette = {r['species']: r['hex'] for r in csv.DictReader(f)}
image = np.asarray(Image.open(adapted).convert('RGBA'))
report = json.loads((ROOT / 'verificacao_cores.json').read_text(encoding='utf-8'))
assert report['originais_preservados'] and report['pinguins_preservados']
assert report['paleta'] == palette
original = ROOT / 'imagens_originais' / 'especies.png'
assert hashlib.sha256(original.read_bytes()).hexdigest() == report['sha256_original']
for key in ('Adelie', 'Chinstrap', 'Gentoo'):
    rgb = ImageColor.getrgb(palette[key])
    opaque = (image[:, :, 3] == 255) & np.all(image[:, :, :3] == rgb, axis=2)
    assert int(opaque.sum()) > 2000, (key, int(opaque.sum()))

# Confere os pixels efetivamente desenhados, não apenas constantes no código.
slide = np.asarray(Image.open(ROOT / 'apoio_antes_cores_conferidas.png').convert('RGB'))
name_boxes = {'Chinstrap': (1070, 780, 1320, 835),
              'Gentoo': (1320, 780, 1540, 835), 'Adelie': (1540, 780, 1810, 835)}
for key, (x1, y1, x2, y2) in name_boxes.items():
    rgb = ImageColor.getrgb(palette[key])
    assert np.count_nonzero(np.all(slide[y1:y2, x1:x2] == rgb, axis=2)) > 50, key
    assert np.count_nonzero(np.all(slide[287:767, 1030:1830] == rgb, axis=2)) > 1000, key

# O PDF deve conter os mesmos pixels dos PNGs, sem desvio de cor por JPEG.
K = PdfParser.PdfName
pdf = PdfParser.PdfParser(filename=str(ROOT / 'paginas_de_apoio_cores_conferidas.pdf'))
try:
    assert len(pdf.pages) == 2
    for ref, filename in zip(pdf.pages, ('apoio_antes_cores_conferidas.png', 'apoio_depois_cores_conferidas.png')):
        page = pdf.read_indirect(ref)
        objects = page[K('Resources')][K('XObject')]
        stream = pdf.read_indirect(next(iter(objects.values())))
        assert stream.dictionary[K('Filter')] == K('JPXDecode')
        embedded = np.asarray(Image.open(BytesIO(stream.buf)).convert('RGB'))
        expected = np.asarray(Image.open(ROOT / filename).convert('RGB'))
        assert np.array_equal(embedded, expected), filename
finally:
    pdf.close()
print('PASSOU: paleta do R = fundos = nomes; PNG e PDF idênticos pixel a pixel; originais e pinguins preservados.')
