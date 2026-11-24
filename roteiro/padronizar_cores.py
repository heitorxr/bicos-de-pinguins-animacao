from pathlib import Path
from PIL import Image, ImageColor, ImageDraw, ImageFilter
import csv
import hashlib
import json
import numpy as np


def padronizar_fundos(root):
    root = Path(root)
    with (root / 'paleta_graficos.csv').open(encoding='utf-8-sig', newline='') as f:
        palette = {row['species']: row['hex'] for row in csv.DictReader(f)}
    original_path = root / 'imagens_originais' / 'especies.png'
    source_bytes = original_path.read_bytes()
    original_hash = hashlib.sha256(source_bytes).hexdigest()
    source = Image.open(original_path).convert('RGBA')
    original = np.array(source)
    hsv = np.asarray(source.convert('RGB').convert('HSV'))

    # Contornos fechados protegem os corpos, olhos, bicos e pés, inclusive os alaranjados.
    ink = ((original[:, :, :3].max(axis=2) < 80) & (original[:, :, 3] >= 128)).astype('uint8') * 255
    ink = Image.fromarray(ink).filter(ImageFilter.MaxFilter(3))
    exterior = Image.fromarray(255 - np.asarray(ink)).copy()
    ImageDraw.floodfill(exterior, (0, 0), 128)
    outside = np.asarray(exterior) == 128
    protected = ~outside
    assert 0 < protected.sum() < protected.size, 'Contornos não segmentados corretamente'

    hue, saturation, value = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]
    visible_paint = outside & (original[:, :, 3] > 0) & (saturation >= 40) & (value >= 40)
    x = np.arange(source.width)[None, :]
    masks = {
        'Chinstrap': visible_paint & (hue >= 166) & (hue <= 235),
        'Gentoo': visible_paint & (hue >= 80) & (hue <= 162),
        'Adelie': visible_paint & (hue <= 60) & (x >= source.width * .56),
    }
    result = original.copy()
    counts = {}
    for name, mask in masks.items():
        assert int(mask.sum()) > 2000, (name, int(mask.sum()))
        result[mask, :3] = ImageColor.getrgb(palette[name])
        # Mantém a transparência original da pincelada, sem modificar o desenho.
        counts[name] = int(mask.sum())
    assert np.array_equal(result[protected], original[protected])
    assert np.array_equal(result[:, :, 3], original[:, :, 3])
    corrected_path = root / 'especies_paleta_graficos.png'
    Image.fromarray(result).save(corrected_path)
    assert hashlib.sha256(original_path.read_bytes()).hexdigest() == original_hash
    report = {
        'paleta': palette,
        'fonte_paleta': 'R/graficos.R, exportada por roteiro/exportar_paleta.R',
        'sha256_original': original_hash,
        'originais_preservados': True,
        'pinguins_preservados': True,
        'pixels_protegidos_pelos_contornos': int(protected.sum()),
        'pixels_de_fundo_padronizados': counts,
        'observacao': 'RGB base idêntico ao gráfico; transparência e bordas suavizadas preservadas.',
        'credito': 'Artwork by @allison_horst; adaptação cromática dos fundos.'
    }
    (root / 'verificacao_cores.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    return corrected_path
