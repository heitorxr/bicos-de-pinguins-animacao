# Lê a cópia local, mantendo as unidades e os tipos originais das medidas.
ler_pinguins <- function(arquivo = "dados/pinguins.csv") {
  readr::read_csv(
    arquivo,
    show_col_types = FALSE,
    col_types = readr::cols(
      species = readr::col_character(),
      island = readr::col_character(),
      bill_len = readr::col_double(),
      bill_dep = readr::col_double(),
      flipper_len = readr::col_integer(),
      body_mass = readr::col_integer(),
      sex = readr::col_character(),
      year = readr::col_integer()
    )
  ) |>
    as.data.frame()
}

preparar_dados <- function(dados) {
  # Criar o identificador antes da exclusão preserva a origem de cada ponto.
  dados_limpos <- dados |>
    dplyr::mutate(id = dplyr::row_number()) |>
    tidyr::drop_na(species, bill_len, bill_dep) |>
    dplyr::mutate(species = factor(species, levels = c("Adelie", "Chinstrap", "Gentoo"))) |>
    as.data.frame()

  # Correlação e contagem são calculadas separadamente dentro de cada espécie.
  por_especie <- dados_limpos |>
    dplyr::group_by(species) |>
    dplyr::summarise(
      n = dplyr::n(),
      r = cor(bill_len, bill_dep),
      .groups = "drop"
    ) |>
    dplyr::transmute(especie = as.character(species), n, r) |>
    as.data.frame()

  list(
    dados = dados_limpos,
    excluidos = nrow(dados) - nrow(dados_limpos),
    r_geral = cor(dados_limpos$bill_len, dados_limpos$bill_dep),
    por_especie = por_especie
  )
}
