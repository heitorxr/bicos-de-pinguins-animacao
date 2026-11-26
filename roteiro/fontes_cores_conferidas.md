# Fontes e créditos

## Ilustrações

Autoria: **Allison Horst (@allison_horst)**. Crédito solicitado: **Artwork by @allison_horst**.

A página Art do projeto palmerpenguins convida ao uso didático dessas ilustrações e solicita esse crédito. Os desenhos não foram gerados por IA nesta conversa.

- Origem e autorização: `https://allisonhorst.github.io/palmerpenguins/articles/art.html`
- Ilustração das espécies: `https://allisonhorst.github.io/palmerpenguins/reference/figures/lter_penguins.png`
- Ilustração das medidas: `https://allisonhorst.github.io/palmerpenguins/reference/figures/culmen_depth.png`
- Definição das medidas: `https://allisonhorst.github.io/palmerpenguins/#bill-dimensions`

Na apresentação, os fundos foram adaptados à paleta dos gráficos e os rótulos das medidas foram traduzidos para português. As setas, os contornos, os bicos e as patas foram preservados. O aviso de assistência de IA refere-se ao texto, à montagem e à adaptação por software, não à autoria das ilustrações.

## Dados e interpretação estatística

A análise usa a cópia local `dados/pinguins.csv`, com preparação e cálculos em `R/modelo.R`. Comprimento e profundidade são medidos em milímetros. A amostra é a mesma no conjunto e na comparação por espécie.

Horst, Allison M.; Hill, Alison Presmanes; Gorman, Kristen B. (2022). *Palmer Archipelago Penguins Data in the palmerpenguins R Package — An Alternative to Anderson's Irises*. The R Journal, 14(1), 244–254. DOI: `10.32614/RJ-2022-020`.

- Artigo, figura 5: `https://journal.r-project.org/articles/RJ-2022-020/`
- Exemplo do projeto: `https://allisonhorst.github.io/palmerpenguins/articles/examples.html#simpsons-paradox-omitting-species-in-graph-above`

A regressão geral ilustra a inversão e não é apresentada como modelo único recomendado para essas medidas. Os coeficientes foram calculados com os dados locais, não copiados de outra amostra.

## Cores da apresentação

A fonte da paleta é `cores_pinguins`, em `R/graficos.R`:

- Adélie: `#D55E00`.
- Chinstrap: `#0072B2`.
- Gentoo: `#00856A`.

Os nomes e os fundos das espécies usam esses códigos. As telas finais estão em `apoio_antes_cores_conferidas.png` e `apoio_depois_cores_conferidas.png`, reunidas em `paginas_de_apoio_cores_conferidas.pdf`.

Os originais, geradores, versões intermediárias e relatórios de conferência foram preservados em arquivo local fora do Git.
