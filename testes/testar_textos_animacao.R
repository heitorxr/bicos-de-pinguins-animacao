args <- commandArgs(trailingOnly = TRUE)
raiz <- if (length(args)) args[[1]] else getwd()
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
source(file.path(raiz, "R", "modelo.R"), encoding = "UTF-8")
source(file.path(raiz, "R", "graficos.R"), encoding = "UTF-8")
modelo <- preparar_dados(ler_pinguins(file.path(raiz, "dados", "pinguins.csv")))
subtitulo <- "Comprimento e profundidade do bico: correlação geral e por espécie."
for (progresso in c(0, 0.18, 0.59, 1)) {
  grafico <- criar_grafico_transformacao(modelo, progresso)
  if (!identical(grafico$labels$subtitle, subtitulo)) {
    stop("RED: o subtítulo ainda descreve o movimento, não o estudo")
  }
  stopifnot(!grepl("passagem do tempo", grafico$labels$caption, fixed = TRUE),
    !grepl("mudam juntos", montar_transformacao(modelo, progresso)$rotulo, fixed = TRUE))
}
# Na segunda metade, os números são as correlações reais por espécie.
correlacoes <- paste0("Por espécie: ", paste0(
  nomes_pinguins[modelo$por_especie$especie], " ",
  formatC(modelo$por_especie$r, digits = 3, format = "f", flag = "+", decimal.mark = ","),
  collapse = "  |  "))
for (progresso in c(0.5, 0.59, 0.99, 1)) {
  stopifnot(identical(montar_transformacao(modelo, progresso)$rotulo, correlacoes))
}
stopifnot(identical(montar_animacao(modelo)$labels$subtitle, subtitulo))
cat("PASSOU: subtítulo do estudo, apenas correlações nos rótulos e rodapé sem a frase retirada.\n")
