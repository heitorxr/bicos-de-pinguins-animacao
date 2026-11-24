arquivo <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
raiz <- normalizePath(file.path(dirname(arquivo), ".."), winslash = "/")
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
source(file.path(raiz, "R", "graficos.R"), encoding = "UTF-8")
# A apresentação recebe as cores dos próprios gráficos, sem uma segunda paleta manual.
paleta <- tibble::enframe(cores_pinguins, name = "species", value = "hex") |>
  dplyr::mutate(hex = toupper(hex))
rgb <- t(grDevices::col2rgb(paleta$hex))
paleta <- paleta |> dplyr::mutate(R = rgb[, 1], G = rgb[, 2], B = rgb[, 3])
readr::write_csv(paleta, file.path(raiz, "roteiro", "paleta_graficos.csv"))
print(paleta)
