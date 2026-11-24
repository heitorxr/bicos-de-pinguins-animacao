# Autoria das imagens e cores conferidas

## Origem das ilustrações

As imagens dos pinguins e das medidas são ilustrações públicas creditadas a Allison Horst no projeto palmerpenguins. Não foram geradas por IA nesta conversa. A página Art convida ao uso didático e solicita o crédito **Artwork by @allison_horst**.

O arquivo de espécies já aparece no histórico público do repositório em junho de 2020, incluindo uma atualização feita por Allison Horst em 11/06/2020. O aviso de assistência de IA da apresentação refere-se à preparação do texto, à diagramação e à adaptação cromática por software, não à autoria dos desenhos originais.

Página de origem e autorização:
`https://allisonhorst.github.io/palmerpenguins/articles/art.html`

Histórico público do arquivo:
`https://github.com/allisonhorst/palmerpenguins/commits/main/man/figures/lter_penguins.png`

Atualização de 11/06/2020 por Allison Horst:
`https://github.com/allisonhorst/palmerpenguins/commit/4587e116dea0cdbd2fe70e7bee58c6685bd60106`

Os arquivos em `imagens_originais/` foram preservados. A cópia `especies_paleta_graficos.png` adapta somente os fundos de cor; os contornos e interiores dos pinguins ficam protegidos. Os créditos identificam a adaptação.

## Paleta dos gráficos

A fonte única é o vetor `cores_pinguins` de `R/graficos.R`, exportado por `exportar_paleta.R` para `paleta_graficos.csv`.

| Espécie | HEX | RGB |
|---|---|---|
| Adélie | `#D55E00` | `213, 94, 0` |
| Chinstrap | `#0072B2` | `0, 114, 178` |
| Gentoo | `#00856A` | `0, 133, 106` |

Esses códigos-base são usados tanto nos nomes quanto nos fundos. As bordas suavizadas e a transparência original das pinceladas continuam produzindo misturas com o branco, como esperado; as áreas opacas usam os valores RGB acima.

## Verificação

O teste `testar_paleta_apresentacao.py` confirmou:

- a paleta da apresentação corresponde à paleta exportada do R;
- há pixels com os códigos exatos nos fundos e nas letras dos nomes;
- o arquivo original mantém seu SHA-256;
- as áreas dos desenhos protegidas pelos contornos permanecem idênticas;
- o PDF tem duas páginas e as imagens nele incorporadas são idênticas, pixel a pixel, aos PNGs.

O PDF utiliza JPEG2000 sem perdas. A exportação anterior em JPEG poderia deslocar ligeiramente os valores RGB.

## Arquivos atualizados

- `apoio_antes_cores_conferidas.png`
- `apoio_depois_cores_conferidas.png`
- `paginas_de_apoio_cores_conferidas.pdf`
- `verificacao_cores.json` e `verificacao_paginas_cores_conferidas.json`

Para reproduzir, execute `exportar_paleta.R` no R e depois `diagramar_paginas.py` em Python com Pillow (com suporte a JPEG2000) e NumPy. Os cálculos estatísticos permanecem em R. O roteiro falado, o Shiny, os dados e o vídeo não foram alterados por esta revisão cromática. Não houve commit nem push.
