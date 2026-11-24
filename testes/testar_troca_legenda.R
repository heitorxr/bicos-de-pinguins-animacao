args <- commandArgs(trailingOnly = TRUE)
raiz <- if (length(args)) args[[1]] else getwd()
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
source(file.path(raiz, "R", "modelo.R"), encoding = "UTF-8")
source(file.path(raiz, "R", "graficos.R"), encoding = "UTF-8")
modelo <- preparar_dados(ler_pinguins(file.path(raiz, "dados", "pinguins.csv")))
geral <- montar_transformacao(modelo, 0)$rotulo
especies <- montar_transformacao(modelo, 1)$rotulo
for (progresso in c(0.01, 0.18, 0.49)) {
  if (!identical(montar_transformacao(modelo, progresso)$rotulo, geral)) {
    stop("RED: a correlação por espécie aparece antes da metade")
  }
}
for (progresso in c(0.5, 0.59, 1)) {
  stopifnot(identical(montar_transformacao(modelo, progresso)$rotulo, especies))
}

# Metade do tempo do vídeo, incluindo as pausas, não apenas metade do movimento.
animacao <- montar_animacao(modelo)
rotulos <- animacao$layers[[3]]$data |> dplyr::arrange(quadro)
stopifnot(nrow(rotulos) == 180L,
  all(rotulos$rotulo[rotulos$quadro <= 90] == geral),
  all(rotulos$rotulo[rotulos$quadro >= 91] == especies))
for (progresso in c(0, 0.5, 1)) {
  grafico <- criar_grafico_transformacao(modelo, progresso)
  escala <- grafico$scales$get_scales("colour")
  stopifnot(identical(as.character(escala$get_breaks()), unname(cores_pinguins)),
    identical(unname(escala$get_labels()), c("Geral", "Adélie", "Chinstrap", "Gentoo")),
    isTRUE(grafico$layers[[1]]$show.legend),
    isTRUE(grafico$layers[[2]]$show.legend))
}
cat("PASSOU: troca aos", 90 / 12, "segundos e legenda com ponto/traço Geral em cinza.\n")
