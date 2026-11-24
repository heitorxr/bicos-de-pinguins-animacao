# Roteiro do vídeo: comprimento e profundidade do bico

Proposta para revisão. O texto foi preparado para leitura em voz alta, com a skill humanizer. As duas páginas de apoio ainda não foram inseridas no Shiny. A animação atual permanece sem alterações.

## 1. Antes da animação: medidas e espécies

**Na tela:** página `apoio_antes.png`. Aponte primeiro para as setas das medidas. Depois, mostre as espécies: Chinstrap à esquerda, Gentoo ao centro e Adélie à direita na ilustração original. Os nomes sob as imagens usam as cores do gráfico.

**Fala:**

O trabalho compara duas medidas do bico dos pinguins: o comprimento e a profundidade. A pergunta é se bicos mais compridos também tendem a ser mais profundos.

O comprimento vai da base até a ponta, pela parte de cima do bico. A profundidade é a altura do bico, medida de cima para baixo, na região indicada pelas setas. As duas medidas estão em milímetros.

A base reúne três espécies. O Adélie tem um contorno branco nos olhos. O Chinstrap tem uma faixa preta sob a cabeça, parecida com uma barbicha. O Gentoo aparece com uma mancha branca na cabeça e o bico alaranjado.

Na análise, entram 342 pinguins com as duas medidas disponíveis. Cada ponto do gráfico representa um deles.

## 2. Durante a animação: 15 segundos

**Na tela:** reproduza a animação uma vez, mantendo o cursor fora do gráfico.

**Primeira metade, antes da troca aos 7,5 segundos:**

Quando misturamos as espécies, a correlação entre as medidas fica um pouco negativa.

**Segunda metade, depois da troca aos 7,5 segundos:**

Separando por espécie, a correlação é positiva nas três.

## 3. Depois da animação: por que o sinal muda

**Na tela:** página `apoio_depois.png`. Compare o gráfico geral, à esquerda, com o gráfico por espécie, à direita. Ao mencionar Gentoo e Adélie, aponte para os grupos verde e laranja.

**Fala:**

A diferença vem de juntar grupos com formatos de bico diferentes.

Na nossa amostra, o Gentoo tem, em média, um bico mais comprido e menos profundo que o Adélie. Essa diferença entre as espécies ajuda a puxar a reta geral para baixo.

Dentro de cada espécie, a comparação é outra: os indivíduos com bicos mais compridos tendem a ter bicos mais profundos. A reta geral mistura essa variação entre indivíduos com as diferenças entre as espécies.

Essa inversão é um exemplo do paradoxo de Simpson. A associação no conjunto tem o sentido contrário ao que aparece dentro dos grupos.

Se a pergunta é sobre pinguins da mesma espécie, o coeficiente geral sozinho não responde bem. Aqui, a reta cinza serve para mostrar o efeito da mistura, e não como um modelo único recomendado para prever a profundidade do bico.

O gráfico mostra associação. Ele não prova que mudar uma dessas medidas causa uma mudança na outra.

## 4. Fecho para a apresentação completa: mostrar o código

Este trecho pode vir no fim, para atender à demonstração do Shiny e dos códigos mencionada no LEIA-ME do projeto. Não é necessário ler caminhos ou nomes de funções em voz alta.

**Na tela:** mostre `R/modelo.R`, depois `R/graficos.R` e, por último, o aplicativo aberto.

**Fala:**

No R, o arquivo modelo lê os dados, exclui apenas os dois registros sem as medidas necessárias e calcula as correlações. O arquivo de gráficos monta os ajustes e a animação. O app reúne essas partes no Shiny, onde também dá para controlar a transição e comparar os resultados por espécie.

## Conferência dos resultados

Os valores abaixo são de Pearson e foram calculados novamente com a cópia local usada na animação. A amostra é a mesma nas duas leituras.

| Comparação | Pinguins com as duas medidas | Correlação de Pearson |
|---|---:|---:|
| Conjunto | 342 | -0,235 |
| Adélie | 151 | +0,391 |
| Chinstrap | 68 | +0,654 |
| Gentoo | 123 | +0,643 |

A base original tem 344 registros. Excluímos dois sem as medidas necessárias, sem preencher os valores ausentes. A explicação trata da composição dos grupos; não atribui o formato dos bicos a alimentação, evolução ou outra causa biológica não testada nesta análise.

## Fontes e créditos

- Dados locais: `dados/pinguins.csv`; preparação e cálculos: `R/modelo.R`.
- Ilustrações: Artwork by @allison_horst. Uso didático autorizado na página Art do projeto palmerpenguins. A página de medidas usa um recorte da ilustração original, sem alterar as setas ou a posição das medidas.
- Definição das medidas e ilustrações: site oficial do pacote palmerpenguins, seção Bill dimensions e página Art.
- Interpretação da inversão: Horst, Hill e Gorman (2022), *Palmer Archipelago Penguins Data in the palmerpenguins R Package — An Alternative to Anderson's Irises*, seção sobre o paradoxo de Simpson, figura 5.
- Endereços e proveniência dos arquivos: `fontes_imagens.md`.

Roteiro e montagem das páginas preparados com assistência de IA, para revisão do autor. Nenhum texto foi publicado nem inserido automaticamente no aplicativo.
