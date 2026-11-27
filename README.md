# Bicos de pinguins

Animação em R que compara a correlação entre comprimento e profundidade do bico no conjunto dos pinguins e dentro de cada espécie, ilustrando o paradoxo de Simpson.

A análise utiliza grupos já conhecidos pelas espécies, não um algoritmo de clustering.

## Aplicativo

**[Abrir o Shiny no navegador](https://heitorxr.github.io/bicos-de-pinguins-animacao/)**

O aplicativo roda no navegador, sem instalação de R. O primeiro carregamento pode levar mais tempo.

Para executar a cópia local, na pasta do projeto:

```r
source("iniciar.R", encoding = "UTF-8")
```

## Materiais

- [Animação em MP4](pinguins_movimento_continuo.mp4)
- [Apresentação em PDF](roteiro/paginas_de_apoio_cores_conferidas.pdf)
- [Revisor do código — HTML para abrir localmente](Revisao-Codigo-Pinguins.html)

## Código

- `R/modelo.R`: preparação dos dados e correlações.
- `R/graficos.R`: gráficos e quadros da animação.
- `gerar_animacao.R`: exportação do GIF.

Para gerar novamente o GIF, execute no R, a partir da pasta do projeto:

```r
source("gerar_animacao.R", encoding = "UTF-8")
```

A primeira execução pode instalar os pacotes necessários na pasta `.biblioteca`.

## Fontes e créditos

Dados: Palmer Penguins. Ilustrações: Allison Horst (@allison_horst).

Detalhes em `dados/FONTE.txt` e `roteiro/fontes_cores_conferidas.md`.
