cores_pinguins <- c(
  Todos = "#788591",
  Adelie = "#D55E00",
  Chinstrap = "#0072B2",
  Gentoo = "#00856A"
)
nomes_pinguins <- c(
  Todos = "Sem separar",
  Adelie = "Adélie",
  Chinstrap = "Chinstrap",
  Gentoo = "Gentoo"
)
etapas_pinguins <- c("1. Todos misturados", "2. Espécies reveladas")

montar_estados <- function(modelo) {
  dados <- modelo$dados
  # Duas leituras da mesma amostra: não são novas observações.
  todos <- dados |> dplyr::mutate(grupo = "Todos", etapa = etapas_pinguins[1])
  especies <- dados |> dplyr::mutate(grupo = as.character(species), etapa = etapas_pinguins[2])
  pontos <- dplyr::bind_rows(todos, especies) |>
    dplyr::mutate(etapa = factor(etapa, levels = etapas_pinguins)) |>
    as.data.frame()

  # Calcula uma tabela por grupo e reúne os resultados.
  linhas <- purrr::map_dfr(names(cores_pinguins), function(grupo) {
    dados_grupo <- if (grupo == "Todos") dados else dplyr::filter(dados, species == grupo)
    ajuste <- lm(bill_dep ~ bill_len, data = dados_grupo)
    x <- seq(min(dados_grupo$bill_len), max(dados_grupo$bill_len), length.out = 60)
    etapa_grupo <- if (grupo == "Todos") etapas_pinguins[1] else etapas_pinguins[2]
    tibble::tibble(
      bill_len = x,
      bill_dep = as.numeric(predict(ajuste, newdata = tibble::tibble(bill_len = x))),
      grupo = grupo,
      etapa = etapa_grupo
    )
  }) |>
    dplyr::mutate(etapa = factor(etapa, levels = etapas_pinguins)) |>
    as.data.frame()
  list(pontos = pontos, linhas = linhas)
}

criar_grafico <- function(modelo, separar = FALSE) {
  estados <- montar_estados(modelo)
  pontos <- estados$pontos
  linhas <- estados$linhas
  if (!is.null(separar)) {
    etapa_escolhida <- etapas_pinguins[if (separar) 2 else 1]
    pontos <- dplyr::filter(pontos, etapa == etapa_escolhida)
    linhas <- dplyr::filter(linhas, etapa == etapa_escolhida)
  }
  ggplot2::ggplot(pontos, ggplot2::aes(x = bill_len, y = bill_dep)) +
    ggplot2::geom_point(ggplot2::aes(colour = grupo, group = id),
                       size = 2.6, alpha = 0.76) +
    ggplot2::geom_line(data = linhas, ggplot2::aes(colour = grupo, group = grupo),
                      linewidth = 1.35) +
    ggplot2::scale_colour_manual(values = cores_pinguins, labels = nomes_pinguins,
                                 breaks = names(cores_pinguins), drop = FALSE) +
    ggplot2::coord_cartesian(xlim = c(30, 62), ylim = c(12, 23), expand = FALSE) +
    ggplot2::labs(
      title = "Os mesmos pinguins. Duas leituras.",
      subtitle = if (isTRUE(separar)) etapas_pinguins[2] else etapas_pinguins[1],
      x = "Comprimento do bico (mm)", y = "Profundidade do bico (mm)", colour = NULL,
      caption = paste0(nrow(modelo$dados), " pinguins com as duas medidas · ",
                       modelo$excluidos, " registros excluídos por medida ausente\n",
                       "A animação revela grupos; não representa passagem do tempo.")
    ) +
    ggplot2::theme_minimal(base_size = 15, base_family = "sans") +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#F8FAFC", colour = NA),
      panel.background = ggplot2::element_rect(fill = "#F8FAFC", colour = NA),
      plot.title = ggplot2::element_text(face = "bold", colour = "#132B3B", size = 22),
      plot.subtitle = ggplot2::element_text(colour = "#486174", margin = ggplot2::margin(b = 15)),
      plot.caption = ggplot2::element_text(colour = "#526675", hjust = 0, size = 10, lineheight = 1.3),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#E2E8F0", linewidth = 0.4),
      legend.position = "bottom", legend.text = ggplot2::element_text(size = 11),
      axis.title = ggplot2::element_text(colour = "#243E50"),
      plot.margin = ggplot2::margin(22, 24, 16, 18)
    )
}

rotulo_correlacao <- function(modelo, por_especie = FALSE) {
  if (!por_especie) {
    return(paste0("Todos misturados: r = ",
      formatC(modelo$r_geral, digits = 3, format = "f", decimal.mark = ",")))
  }
  paste0("Por espécie: ", paste0(
    nomes_pinguins[modelo$por_especie$especie], " ",
    formatC(modelo$por_especie$r, digits = 3, format = "f", flag = "+", decimal.mark = ","),
    collapse = "  |  "))
}

montar_transformacao <- function(modelo, progresso) {
  if (length(progresso) != 1L || !is.numeric(progresso) ||
      !is.finite(progresso) || progresso < 0 || progresso > 1) {
    stop("progresso deve ser um número entre 0 e 1.")
  }
  dados <- modelo$dados
  geral <- lm(bill_dep ~ bill_len, data = dados)
  faixa <- range(dados$bill_len)
  x_geral <- seq(faixa[1], faixa[2], length.out = 60)
  y_geral <- as.numeric(predict(geral, newdata = data.frame(bill_len = x_geral)))
  angulo_inicial <- atan(coef(geral)[[2]])
  comprimento_inicial <- diff(faixa) * sqrt(1 + coef(geral)[[2]]^2) / 3
  # As três partes começam coladas. O movimento cria a separação, sem afastamento prévio.
  # A suavização faz o movimento começar e terminar devagar.
  mover <- 3 * progresso^2 - 2 * progresso^3
  grupos <- levels(dados$species)
  # Ordena as espécies pelo centro da faixa de comprimentos, sem mover os pontos.
  ordem <- dados |>
    dplyr::group_by(species) |>
    dplyr::summarise(centro_da_faixa = mean(range(bill_len)), .groups = "drop") |>
    dplyr::arrange(centro_da_faixa) |>
    dplyr::pull(species) |>
    as.character()
  # Mistura o cinza inicial com a cor da espécie usando o mesmo peso do giro.
  cores <- grupos |>
    purrr::set_names() |>
    purrr::map_chr(function(grupo) {
      rgb <- round((1 - mover) * grDevices::col2rgb(cores_pinguins[["Todos"]]) +
        mover * grDevices::col2rgb(cores_pinguins[[grupo]]))
      grDevices::rgb(rgb[1], rgb[2], rgb[3], maxColorValue = 255)
    })
  ramos <- purrr::map_dfr(grupos, function(grupo) {
    dados_especie <- dplyr::filter(dados, species == grupo)
    ajuste <- lm(bill_dep ~ bill_len, data = dados_especie)
    x_final <- range(dados_especie$bill_len)
    y_final <- as.numeric(predict(ajuste, newdata = tibble::tibble(bill_len = x_final)))
    indice <- match(grupo, ordem)
    centro_x <- faixa[1] + (indice - 0.5) * diff(faixa) / 3
    centro_y <- as.numeric(predict(geral, newdata = data.frame(bill_len = centro_x)))
    # Ângulo, comprimento, posição e cor usam exatamente o mesmo progresso.
    angulo <- (1 - mover) * angulo_inicial + mover * atan2(diff(y_final), diff(x_final))
    comprimento <- (1 - mover) * comprimento_inicial + mover * sqrt(diff(x_final)^2 + diff(y_final)^2)
    centro_x <- (1 - mover) * centro_x + mover * mean(x_final)
    centro_y <- (1 - mover) * centro_y + mover * mean(y_final)
    posicao <- seq(-0.5, 0.5, length.out = 60)
    cor_atual <- cores[[grupo]]
    tibble::tibble(
      x = centro_x + posicao * comprimento * cos(angulo),
      y = centro_y + posicao * comprimento * sin(angulo),
      grupo = grupo, alpha = 1, cor = cor_atual,
      angulo = angulo, comprimento = comprimento, sincronia = mover
    )
  }) |> as.data.frame()
  pontos <- dados |>
    dplyr::mutate(grupo = as.character(species), cor = unname(cores[grupo])) |>
    as.data.frame()
  referencia <- tibble::tibble(x = x_geral, y = y_geral,
                            alpha_solida = 0, alpha_tracejada = 0) |> as.data.frame()
  intermediario <- progresso > 0 && progresso < 1
  rotulo <- rotulo_correlacao(modelo, por_especie = progresso >= 0.5)
  list(pontos = pontos, ramos = ramos, referencia = referencia,
       alpha_ramos = 1, alpha_geral = 0, sincronia = mover,
       etapa = if (progresso == 0) "unida" else "transformacao",
       intermediario = intermediario, rotulo = rotulo)
}

plotar_transformacao <- function(modelo, dados) {
  ggplot2::ggplot() +
    ggplot2::geom_point(data = dados$pontos,
      ggplot2::aes(bill_len, bill_dep, group = id, colour = cor),
      size = 2.6, alpha = 0.76, show.legend = TRUE) +
    ggplot2::geom_line(data = dados$ramos,
      ggplot2::aes(x, y, group = grupo, colour = cor), linewidth = 1.35, show.legend = TRUE) +
    ggplot2::geom_text(data = dados$rotulos,
      ggplot2::aes(x = 30.8, y = 22.8, label = rotulo, group = 1),
      hjust = 0, vjust = 1, size = 3.8, colour = "#425E70") +
    ggplot2::scale_colour_identity(guide = "legend",
      limits = unique(c(unname(cores_pinguins), dados$pontos$cor, dados$ramos$cor)),
      labels = c("Geral", unname(nomes_pinguins[c("Adelie", "Chinstrap", "Gentoo")])),
      breaks = unname(cores_pinguins), drop = FALSE) +
    ggplot2::coord_cartesian(xlim = c(30, 62), ylim = c(12, 23), expand = FALSE) +
    ggplot2::labs(
      title = "Uma reta geral. Três relações diferentes.",
      subtitle = "Comprimento e profundidade do bico: correlação geral e por espécie.",
      x = "Comprimento do bico (mm)", y = "Profundidade do bico (mm)", colour = NULL,
      caption = paste0(nrow(modelo$dados), " pinguins com as duas medidas · ", modelo$excluidos,
        " registros excluídos por medida ausente\n",
        "Pontos e eixos fixos. Movimento ilustrativo.")
    ) + criar_grafico(modelo, FALSE)$theme
}

criar_grafico_transformacao <- function(modelo, progresso) {
  estado <- montar_transformacao(modelo, progresso)
  estado$rotulos <- tibble::tibble(rotulo = estado$rotulo)
  plotar_transformacao(modelo, estado)
}

sequencia_animacao <- function() {
  # A mesma sequência é usada pelo GIF e pelo slider do Shiny.
  c(rep(0, 18), seq(0, 1, length.out = 138), rep(1, 24))
}

estado_do_quadro <- function(modelo, quadro) {
  progressos <- sequencia_animacao()
  if (length(quadro) != 1L || !is.finite(quadro) ||
      quadro != as.integer(quadro) || quadro < 1 || quadro > length(progressos)) {
    stop("Escolha um quadro válido da animação.")
  }
  estado <- montar_transformacao(modelo, progressos[[quadro]])
  # A correlação troca na metade do vídeo, contando também as pausas.
  estado$rotulo <- rotulo_correlacao(modelo, por_especie = quadro > length(progressos) / 2)
  estado$rotulos <- tibble::tibble(rotulo = estado$rotulo)
  estado
}

montar_animacao <- function(modelo) {
  estados <- purrr::imap(sequencia_animacao(), function(progresso, quadro) {
    estado <- estado_do_quadro(modelo, quadro)
    purrr::map(estado[c("pontos", "ramos", "referencia", "rotulos")], function(tabela) {
      dplyr::mutate(tabela, quadro = quadro)
    })
  })
  dados <- c("pontos", "ramos", "referencia", "rotulos") |>
    purrr::set_names() |>
    purrr::map(function(nome) purrr::map_dfr(estados, nome))
  plotar_transformacao(modelo, dados) + gganimate::transition_manual(quadro)
}
