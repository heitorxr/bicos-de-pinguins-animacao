grafico_do_quadro <- function(modelo, quadro, compacto = FALSE) {
  grafico <- plotar_transformacao(modelo, estado_do_quadro(modelo, quadro))
  # O rótulo fica em HTML; o desenho é o mesmo da animação aprovada.
  grafico$layers <- purrr::discard(grafico$layers, function(camada) inherits(camada$geom, "GeomText"))
  if (compacto) {
    grafico$layers[[1]]$aes_params$size <- 1.6
    grafico <- grafico + ggplot2::theme(
      axis.title = ggplot2::element_text(size = 10),
      axis.text = ggplot2::element_text(size = 9),
      legend.text = ggplot2::element_text(size = 10),
      plot.margin = ggplot2::margin(10, 12, 8, 10))
  }
  grafico + ggplot2::labs(title = NULL, subtitle = NULL, caption = NULL) +
    ggplot2::guides(colour = ggplot2::guide_legend(nrow = 2, byrow = TRUE))
}

preparar_quadros <- function(modelo) {
  # Invalida o cache quando os dados ou o código dos gráficos mudam.
  assinatura <- tempfile(fileext = ".txt")
  on.exit(unlink(assinatura), add = TRUE)
  writeLines(unname(tools::md5sum(c("dados/pinguins.csv", "R/modelo.R",
                                  "R/graficos.R", "R/quadros.R"))), assinatura)
  versao <- substr(unname(tools::md5sum(assinatura)), 1, 12)
  pasta <- file.path("www", "quadros", versao)
  manifesto <- file.path(pasta, "manifesto.json")
  progressos <- sequencia_animacao()
  primeiros <- match(unique(progressos), progressos)
  arquivos <- sprintf("quadro-%03d.png", seq_along(primeiros))
  # As pausas reutilizam imagens: são 180 posições, não 180 desenhos diferentes.
  mapa <- arquivos[match(progressos, unique(progressos))]
  tamanhos <- tibble::tribble(
    ~nome, ~largura, ~altura, ~compacto,
    "desktop", 1060, 440, FALSE,
    "compacto", 360, 320, TRUE)
  esperados <- unlist(purrr::map(tamanhos$nome, function(nome) file.path(pasta, nome, arquivos)))
  if (!file.exists(manifesto) || !all(file.exists(esperados))) {
    message("Preparando os quadros locais. Isso só é necessário quando os gráficos mudam.")
    purrr::pwalk(tamanhos, function(nome, largura, altura, compacto) {
      destino <- file.path(pasta, nome)
      dir.create(destino, recursive = TRUE, showWarnings = FALSE)
      purrr::walk(seq_along(primeiros), function(indice) {
        ggplot2::ggsave(file.path(destino, arquivos[[indice]]),
          grafico_do_quadro(modelo, primeiros[[indice]], compacto),
          width = largura, height = altura, units = "px", dpi = 110,
          bg = "#F8FAFC", limitsize = FALSE)
      })
    })
    rotulos <- ifelse(seq_along(progressos) <= length(progressos) / 2,
                     rotulo_correlacao(modelo, FALSE), rotulo_correlacao(modelo, TRUE))
    jsonlite::write_json(list(total = length(progressos), fps = 12,
      quadros = unname(mapa), rotulos = unname(rotulos)),
      manifesto, auto_unbox = TRUE, pretty = TRUE)
  }
  list(manifesto = paste0("quadros/", versao, "/manifesto.json"),
       primeiro = paste0("quadros/", versao, "/desktop/", arquivos[[1]]),
       total = length(progressos))
}
