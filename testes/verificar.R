# Verificação curta do modelo, dos quadros locais e das outras abas.
.libPaths(c(normalizePath(".biblioteca"), .libPaths()))
if (!file.exists("R/quadros.R")) stop("Falta preparar os quadros para reprodução local no navegador.")
ambiente <- new.env(parent = globalenv())
source("app.R", local = ambiente, encoding = "UTF-8")
modelo <- ambiente$modelo
stopifnot(nrow(modelo$dados) == 342L, modelo$excluidos == 2L,
          modelo$r_geral < 0, all(modelo$por_especie$r > 0))

inicio <- estado_do_quadro(modelo, 1)
fim <- estado_do_quadro(modelo, 180)
stopifnot(inicio$sincronia == 0, fim$sincronia == 1,
          identical(inicio$pontos$id, fim$pontos$id),
          identical(inicio$pontos$bill_len, fim$pontos$bill_len),
          identical(inicio$pontos$bill_dep, fim$pontos$bill_dep))

# O navegador recebe os 180 índices e os rótulos calculados no R.
manifesto <- file.path("www", ambiente$quadros_locais$manifesto)
quadros <- jsonlite::read_json(manifesto, simplifyVector = TRUE)
stopifnot(quadros$total == 180, length(quadros$quadros) == 180,
          length(quadros$rotulos) == 180,
          quadros$rotulos[[90]] == rotulo_correlacao(modelo, FALSE),
          quadros$rotulos[[91]] == rotulo_correlacao(modelo, TRUE))
purrr::walk(c("desktop", "compacto"), function(tamanho) {
  stopifnot(all(file.exists(file.path(dirname(manifesto), tamanho, quadros$quadros))))
})

shiny::testServer(ambiente$server, {
  session$setInputs(modo = "geral")
  stopifnot(grepl("Sem separar", output$metricas$html, fixed = TRUE))
  session$setInputs(modo = "especies")
  stopifnot(grepl("Adélie", output$metricas$html, fixed = TRUE),
            grepl("Gentoo", output$metricas$html, fixed = TRUE))
})
pagina <- htmltools::renderTags(ambiente$ui)
html <- paste(pagina$head, pagina$html)
stopifnot(grepl('data-manifesto=', html, fixed = TRUE),
          grepl('quadros.js', html, fixed = TRUE),
          !grepl('id="reproducao"', html, fixed = TRUE))
cat("OK: dados preservados, quadros locais, rótulos e abas reativas.\n")
