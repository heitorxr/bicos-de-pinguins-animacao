arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(arquivo), ".."), winslash = "/")
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
source(file.path(raiz, "R", "modelo.R"), encoding = "UTF-8")
source(file.path(raiz, "R", "graficos.R"), encoding = "UTF-8")
pasta <- file.path(raiz, "roteiro")
imagens <- file.path(pasta, "imagens_originais")
dir.create(imagens, recursive = TRUE, showWarnings = FALSE)

# As ilustrações têm uso didático autorizado na página Art; preservamos os arquivos.
fontes <- tibble::tribble(
  ~nome, ~url,
  "especies.png", "https://allisonhorst.github.io/palmerpenguins/reference/figures/lter_penguins.png",
  "medidas.png", "https://allisonhorst.github.io/palmerpenguins/reference/figures/culmen_depth.png")
purrr::pwalk(fontes, function(nome, url) {
  destino <- file.path(imagens, nome)
  if (!file.exists(destino)) utils::download.file(url, destino, mode = "wb", quiet = TRUE)
  stopifnot(file.info(destino)$size > 1000)
})

modelo <- preparar_dados(ler_pinguins(file.path(raiz, "dados", "pinguins.csv")))
dados <- modelo$dados
resumo <- dados |>
  dplyr::group_by(species) |>
  dplyr::summarise(n = dplyr::n(), comprimento_medio_mm = mean(bill_len),
    profundidade_media_mm = mean(bill_dep), r = cor(bill_len, bill_dep), .groups = "drop")
stopifnot(nrow(dados) == 342L, modelo$excluidos == 2L,
  modelo$r_geral < 0, all(resumo$r > 0),
  resumo$comprimento_medio_mm[resumo$species == "Gentoo"] > resumo$comprimento_medio_mm[resumo$species == "Adelie"],
  resumo$profundidade_media_mm[resumo$species == "Gentoo"] < resumo$profundidade_media_mm[resumo$species == "Adelie"])

# Confere a explicação entre/dentro dos grupos sem propor uma causa biológica.
centrados <- dados |> dplyr::left_join(resumo, by = "species")
total <- sum((dados$bill_len - mean(dados$bill_len)) * (dados$bill_dep - mean(dados$bill_dep)))
dentro <- sum((centrados$bill_len - centrados$comprimento_medio_mm) *
  (centrados$bill_dep - centrados$profundidade_media_mm))
entre <- sum(resumo$n * (resumo$comprimento_medio_mm - mean(dados$bill_len)) *
  (resumo$profundidade_media_mm - mean(dados$bill_dep)))
stopifnot(isTRUE(all.equal(total, dentro + entre)), dentro > 0, entre < 0, total < 0)
readr::write_csv(resumo, file.path(pasta, "resumo_especies.csv"))
readr::write_csv(tibble::tibble(n = nrow(dados), excluidos = modelo$excluidos,
  r = modelo$r_geral, soma_produtos_total = total,
  soma_produtos_dentro = dentro, soma_produtos_entre = entre),
  file.path(pasta, "resumo_geral.csv"))

# Gera comparações apenas para as novas páginas; não altera a animação ou o Shiny.
for (separar in c(FALSE, TRUE)) {
  grafico <- criar_grafico(modelo, separar) +
    ggplot2::labs(title = if (separar) "Separando por espécie" else "Todos juntos",
      subtitle = if (separar) "Três associações positivas" else paste0("Correlação geral: r = ",
        formatC(modelo$r_geral, digits = 3, format = "f", decimal.mark = ",")), caption = NULL) +
    ggplot2::theme(plot.title = ggplot2::element_text(size = 20),
      plot.subtitle = ggplot2::element_text(size = 16), legend.position = "none",
      plot.margin = ggplot2::margin(14, 20, 14, 10))
  ggplot2::ggsave(file.path(pasta, if (separar) "comparacao_especies.png" else "comparacao_geral.png"),
    grafico, width = 9, height = 5.8, dpi = 150)
}
print(resumo)
cat("Amostra e explicação verificadas; ilustrações baixadas e gráficos de apoio gerados.\n")
