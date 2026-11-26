# Verificação curta do modelo e do controle da animação.
.libPaths(c(normalizePath(".biblioteca"), .libPaths()))
ambiente <- new.env(parent = globalenv())
source("app.R", local = ambiente, encoding = "UTF-8")
modelo <- ambiente$modelo
stopifnot(nrow(modelo$dados) == 342L, modelo$excluidos == 2L,
          modelo$r_geral < 0, all(modelo$por_especie$r > 0))
if (!exists("estado_do_quadro", mode = "function"))
  stop("RED: falta controlar os quadros reais da animação no Shiny")

progressos <- sequencia_animacao()
inicio <- estado_do_quadro(modelo, 1)
fim <- estado_do_quadro(modelo, length(progressos))
stopifnot(inicio$sincronia == 0, fim$sincronia == 1,
          identical(inicio$pontos$id, fim$pontos$id),
          identical(inicio$pontos$bill_len, fim$pontos$bill_len),
          identical(inicio$pontos$bill_dep, fim$pontos$bill_dep),
          estado_do_quadro(modelo, 90)$rotulo == rotulo_correlacao(modelo, FALSE),
          estado_do_quadro(modelo, 91)$rotulo == rotulo_correlacao(modelo, TRUE))

# Avança, retrocede e volta ao começo pela mesma entrada usada pelo slider.
shiny::testServer(ambiente$server, {
  purrr::walk(c(1L, 90L, 91L, 180L, 60L, 1L), function(quadro) {
    session$setInputs(quadro = quadro)
    session$flushReact()
    esperado <- estado_do_quadro(modelo, quadro)
    stopifnot(quadro_atual() == quadro,
              identical(estado_transformacao()$ramos, esperado$ramos),
              grepl(esperado$rotulo, output$estado_transicao$html, fixed = TRUE),
              length(output$grafico_transformacao$src) == 1L)
  })
})
html <- as.character(ambiente$ui)
stopifnot(grepl('id="quadro"', html, fixed = TRUE),
          !grepl('id="reproducao"', html, fixed = TRUE))
cat("OK: dados, slider para frente e para trás, correlações e gráfico reativo.\n")
