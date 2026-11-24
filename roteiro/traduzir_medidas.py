from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import hashlib
import json


def traduzir_medidas(root):
    root = Path(root)
    original_path = root / 'imagens_originais' / 'medidas.png'
    original_hash = hashlib.sha256(original_path.read_bytes()).hexdigest()
    source = Image.open(original_path).convert('RGBA')
    result = source.copy()
    draw = ImageDraw.Draw(result)
    allowed = Image.new('L', source.size, 0)
    mask_draw = ImageDraw.Draw(allowed)

    # A área inclinada cobre apenas o texto inglês, acima da seta curva.
    length_area = [(2000, 100), (2760, 240), (2690, 420), (1980, 305)]
    depth_area = (2965, 700, 3765, 895)
    draw.polygon(length_area, fill='white')
    mask_draw.polygon(length_area, fill=255)
    draw.rectangle(depth_area, fill='white')
    mask_draw.rectangle(depth_area, fill=255)
    f = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 125)
    for label, position in [('Comprimento', (1950, 140)), ('Profundidade', (2975, 710))]:
        box = draw.textbbox(position, label, font=f)
        assert 0 <= box[0] < box[2] <= source.width
        draw.text(position, label, font=f, fill='black')
        mask_draw.rectangle(box, fill=255)

    before = np.asarray(source)
    after = np.asarray(result)
    permitted = np.asarray(allowed) > 0
    assert np.array_equal(before[~permitted], after[~permitted])
    # Verifica a seta curva e as três partes da indicação vertical/das guias.
    arrow_boxes = [(1890, 320, 2020, 420), (2100, 410, 2450, 465),
                   (2540, 445, 2760, 560), (2870, 590, 2960, 985),
                   (2140, 590, 3000, 640), (2150, 930, 3020, 980)]
    preserved = [bool(np.array_equal(before[y1:y2, x1:x2], after[y1:y2, x1:x2]))
                 for x1, y1, x2, y2 in arrow_boxes]
    assert all(preserved), 'Uma seta ou guia foi alterada'
    destination = root / 'medidas_em_portugues.png'
    result.save(destination)
    assert hashlib.sha256(original_path.read_bytes()).hexdigest() == original_hash
    report = {'rotulos': {'Bill length': 'Comprimento', 'Bill depth': 'Profundidade'},
              'sha256_original': original_hash, 'setas_preservadas': preserved,
              'fora_dos_rotulos_preservado': True,
              'credito': 'Ilustração de Allison Horst; tradução dos rótulos.'}
    (root / 'verificacao_traducao.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    return destination
