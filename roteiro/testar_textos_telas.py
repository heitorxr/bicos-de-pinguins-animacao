from pathlib import Path
import json
import hashlib

ROOT = Path(__file__).resolve().parent
report = json.loads((ROOT / 'verificacao_paginas_cores_conferidas.json').read_text(encoding='utf-8'))
if 'textos_por_tela' not in report:
    raise AssertionError('RED: a distribuição dos avisos entre as telas ainda não foi ajustada')
first = '\n'.join(report['textos_por_tela']['1'])
last = '\n'.join(report['textos_por_tela']['2'])
assert 'proposta para revisão' not in (first + last).lower()
assert 'assistência de ia' not in first.lower()
assert last.lower().count('assistência de ia') == 1
assert 'Allison Horst' in first
if 'O clustering identifica grupos de observações semelhantes nos dados.' not in last:
    raise AssertionError('RED: o comentário ainda não explica agrupamentos de forma geral')
assert 'sem aplicar um algoritmo de clustering.' in last
assert 'Gentoo: bico em média' not in last
translation = json.loads((ROOT / 'verificacao_traducao.json').read_text(encoding='utf-8'))
assert translation['rotulos'] == {'Bill length': 'Comprimento', 'Bill depth': 'Profundidade'}
assert len(translation['setas_preservadas']) == 6 and all(translation['setas_preservadas'])
assert translation['fora_dos_rotulos_preservado']
source = ROOT / 'imagens_originais' / 'medidas.png'
assert hashlib.sha256(source.read_bytes()).hexdigest() == translation['sha256_original']
assert (ROOT / 'medidas_em_portugues.png').is_file()
print('PASSOU: aviso de IA só na última tela; proposta removida; medidas traduzidas, com setas e original preservados.')
