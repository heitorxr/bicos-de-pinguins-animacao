args <- commandArgs(trailingOnly = TRUE)
raiz <- if (length(args)) args[[1]] else getwd()
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))

# A revisão no painel não deve acrescentar uma interface ao Shiny antigo.
codigo_app <- readr::read_file(file.path(raiz, "app.R"))
if (grepl("ler_codigo_revisao|codigo_animacao|arquivos_codigo", codigo_app)) {
  stop("RED: a revisão de código ainda está incorporada ao Shiny")
}
stopifnot(file.exists(file.path(raiz, "R", "graficos.R")))
cat("PASSOU: revisão no próprio arquivo R, sem a aba adicional no Shiny.\n")
