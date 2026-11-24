args <- commandArgs(trailingOnly = TRUE)
raiz <- if (length(args)) args[[1]] else getwd()
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
source(file.path(raiz, "R", "modelo.R"), encoding = "UTF-8")
source(file.path(raiz, "R", "graficos.R"), encoding = "UTF-8")
# Confere a preferência pedida sem substituir as regressões matemáticas anteriores.
arquivos <- c("R/modelo.R", "R/graficos.R", "app.R", "gerar_animacao.R")
purrr::walk(arquivos, function(arquivo) {
  texto <- paste(readLines(file.path(raiz, arquivo), encoding = "UTF-8"), collapse = "\n")
  if (!grepl("dplyr::|purrr::|tidyr::", texto)) stop(paste("RED: código ainda sem tidyverse em", arquivo))
})
normalizar <- function(x) {
  if (is.data.frame(x)) {
    x <- as.data.frame(x)
    rownames(x) <- NULL
    # Só os textos de apresentação foram alterados; a geometria continua comparável.
    x$label <- NULL
    return(x)
  }
  if (is.list(x)) {
    x$rotulo <- NULL
    return(purrr::map(x, normalizar))
  }
  x
}
# Compara com a versão aprovada, exceto nomes de linhas e textos de apresentação.
modelo <- preparar_dados(read.csv(file.path(raiz, "dados", "pinguins.csv"), stringsAsFactors = FALSE))
modelo_readr <- preparar_dados(ler_pinguins(file.path(raiz, "dados", "pinguins.csv")))
stopifnot(isTRUE(all.equal(as.list(modelo_readr$dados), as.list(modelo$dados))),
          isTRUE(all.equal(modelo_readr$por_especie, modelo$por_especie)))
atual <- list(modelo = modelo, estados = montar_estados(modelo),
  transformacoes = purrr::map(c(0, 0.09, 0.18, 0.3, 0.59, 0.8, 1), function(p) montar_transformacao(modelo, p)),
  desenhos = purrr::map(c(0, 0.18, 0.59, 1), function(p) ggplot2::ggplot_build(criar_grafico_transformacao(modelo, p))$data))
esperado <- readRDS(file.path(raiz, "testes", "referencia_refatoracao.rds"))
diferenca <- all.equal(normalizar(atual), normalizar(esperado), tolerance = 1e-12)
if (!isTRUE(diferenca)) stop(paste(diferenca, collapse = "\n"))
cat("PASSOU: tidyverse no código principal, amostra, estatísticas, cores, geometria e desenhos preservados.\n")
