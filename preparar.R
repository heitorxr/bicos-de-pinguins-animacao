dir.create(".biblioteca", recursive = TRUE, showWarnings = FALSE)
.libPaths(c(normalizePath(".biblioteca"), .libPaths()))
pacotes <- c("shiny", "ggplot2", "gganimate", "gifski", "dplyr", "tidyr", "purrr", "tibble", "readr", "magrittr", "DBI", "jsonlite")
# Esta verificação usa R base para funcionar mesmo antes de instalar os pacotes.
faltam <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltam)) {
  install.packages(faltam, lib = .libPaths()[1], repos = "https://cloud.r-project.org", type = "binary")
}
