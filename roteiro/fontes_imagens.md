# Fontes das imagens e da explicação

## Ilustrações

Autoria e crédito solicitado: **Artwork by @allison_horst**.

A página oficial convida ao uso das ilustrações no ensino com palmerpenguins e solicita esse crédito. Não atribuímos às ilustrações uma licença diferente da autorização efetivamente descrita na página.

Página de origem e autorização:
`https://allisonhorst.github.io/palmerpenguins/articles/art.html`

Arquivos originais, preservados sem edição em `imagens_originais/`:

- `especies.png`: `https://allisonhorst.github.io/palmerpenguins/reference/figures/lter_penguins.png`
- `medidas.png`: `https://allisonhorst.github.io/palmerpenguins/reference/figures/culmen_depth.png`

A tela de medidas poderá usar um recorte da área do bico. As setas e a posição das medidas não serão alteradas. As explicações em português ficam fora da ilustração original.

Na cópia `especies_cores_grafico.png`, os fundos foram adaptados à paleta de `R/graficos.R`: Adélie `#D55E00`, Chinstrap `#0072B2` e Gentoo `#00856A`. Os nomes usam os mesmos códigos. As ilustrações originais permanecem intactas em `imagens_originais/`; bicos, patas e transparência são preservados na adaptação.

## Medidas

A página oficial identifica o cúlmen como a parte superior do bico e apresenta o desenho que indica onde comprimento e profundidade foram medidos:
`https://allisonhorst.github.io/palmerpenguins/#bill-dimensions`

As unidades são milímetros. A cópia local do projeto usa `bill_len` e `bill_dep`, a nomenclatura de `datasets::penguins`, em vez de `bill_length_mm` e `bill_depth_mm` do pacote palmerpenguins.

## Interpretação estatística

Horst, Allison M.; Hill, Alison Presmanes; Gorman, Kristen B. (2022). *Palmer Archipelago Penguins Data in the palmerpenguins R Package - An Alternative to Anderson's Irises*. The R Journal, 14(1), 244–254. DOI: `10.32614/RJ-2022-020`.

Artigo:
`https://journal.r-project.org/articles/RJ-2022-020/`

A figura 5 compara exatamente comprimento e profundidade do bico, com e sem a identificação das espécies, como exemplo do paradoxo de Simpson. A própria legenda adverte que a regressão geral é ilustrativa da inversão e não deve ser tomada como modelo único recomendado para essas medidas.

Exemplo dos próprios responsáveis pelo pacote:
`https://allisonhorst.github.io/palmerpenguins/articles/examples.html#simpsons-paradox-omitting-species-in-graph-above`

Os coeficientes e as médias usados nas telas e na narração foram calculados no R com `dados/pinguins.csv`, pela rotina `preparar_apoio.R`. Não foram copiados de uma amostra diferente.
