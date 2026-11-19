cores_pinguins <- c(Todos = "#788591", Adelie = "#D55E00", Chinstrap = "#0072B2", Gentoo = "#00856A")
nomes_pinguins <- c(Todos = "Sem separar", Adelie = "Adélie", Chinstrap = "Chinstrap", Gentoo = "Gentoo")
etapas_pinguins <- c("1. Todos misturados", "2. Espécies reveladas")

montar_estados <- function(modelo) {
  dados <- modelo$dados
  todos <- dados
  todos$grupo <- "Todos"
  todos$etapa <- etapas_pinguins[1]
  especies <- dados
  especies$grupo <- as.character(especies$species)
  especies$etapa <- etapas_pinguins[2]
  pontos <- rbind(todos, especies)
  pontos$etapa <- factor(pontos$etapa, levels = etapas_pinguins)

  linhas <- do.call(rbind, lapply(names(cores_pinguins), function(grupo) {
    parte <- if (grupo == "Todos") dados else dados[dados$species == grupo, , drop = FALSE]
    ajuste <- lm(bill_dep ~ bill_len, data = parte)
    x <- seq(min(parte$bill_len), max(parte$bill_len), length.out = 60)
    data.frame(bill_len = x,
               bill_dep = as.numeric(predict(ajuste, newdata = data.frame(bill_len = x))),
               grupo = grupo,
               etapa = if (grupo == "Todos") etapas_pinguins[1] else etapas_pinguins[2])
  }))
  linhas$etapa <- factor(linhas$etapa, levels = etapas_pinguins)
  list(pontos = pontos, linhas = linhas)
}

criar_grafico <- function(modelo, separar = FALSE) {
  estados <- montar_estados(modelo)
  pontos <- estados$pontos
  linhas <- estados$linhas
  if (!is.null(separar)) {
    etapa <- etapas_pinguins[if (separar) 2 else 1]
    pontos <- pontos[pontos$etapa == etapa, , drop = FALSE]
    linhas <- linhas[linhas$etapa == etapa, , drop = FALSE]
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
  # Primeiro abre pequenos espaços entre os três terços, sem mudar seu tamanho.
  dividir <- min(progresso / 0.18, 1)
  dividir <- 3 * dividir^2 - 2 * dividir^3
  mover <- max((progresso - 0.18) / 0.82, 0)
  mover <- 3 * mover^2 - 2 * mover^3
  grupos <- levels(dados$species)
  centros <- vapply(grupos, function(grupo) mean(range(dados$bill_len[dados$species == grupo])), numeric(1))
  ordem <- grupos[order(centros)]
  cores <- setNames(vapply(grupos, function(grupo) {
    rgb <- round((1 - mover) * grDevices::col2rgb(cores_pinguins[["Todos"]]) +
      mover * grDevices::col2rgb(cores_pinguins[[grupo]]))
    grDevices::rgb(rgb[1], rgb[2], rgb[3], maxColorValue = 255)
  }, character(1)), grupos)
  ramos <- do.call(rbind, lapply(grupos, function(grupo) {
    parte <- dados[dados$species == grupo, , drop = FALSE]
    ajuste <- lm(bill_dep ~ bill_len, data = parte)
    x_final <- range(parte$bill_len)
    y_final <- as.numeric(predict(ajuste, newdata = data.frame(bill_len = x_final)))
    indice <- match(grupo, ordem)
    centro_x <- faixa[1] + (indice - 0.5) * diff(faixa) / 3 + (indice - 2) * diff(faixa) * 0.03 * dividir
    centro_y <- as.numeric(predict(geral, newdata = data.frame(bill_len = centro_x)))
    # Ângulo, comprimento, posição e cor usam exatamente o mesmo progresso.
    angulo <- (1 - mover) * angulo_inicial + mover * atan2(diff(y_final), diff(x_final))
    comprimento <- (1 - mover) * comprimento_inicial + mover * sqrt(diff(x_final)^2 + diff(y_final)^2)
    centro_x <- (1 - mover) * centro_x + mover * mean(x_final)
    centro_y <- (1 - mover) * centro_y + mover * mean(y_final)
    posicao <- seq(-0.5, 0.5, length.out = 60)
    data.frame(
      x = centro_x + posicao * comprimento * cos(angulo),
      y = centro_y + posicao * comprimento * sin(angulo),
      grupo = grupo, alpha = 1, cor = cores[[grupo]],
      angulo = angulo, comprimento = comprimento, sincronia = mover
    )
  }))
  pontos <- dados
  pontos$grupo <- as.character(pontos$species)
  pontos$cor <- unname(cores[pontos$grupo])
  referencia <- data.frame(x = x_geral, y = y_geral,
                            alpha_solida = 0, alpha_tracejada = 0)
  intermediario <- progresso > 0 && progresso < 1
  rotulo <- if (progresso == 0) {
    paste0("Todos misturados: r = ", formatC(modelo$r_geral, digits = 3, format = "f", decimal.mark = ","))
  } else if (progresso == 1) {
    paste0("Por espécie: ", paste0(
      nomes_pinguins[modelo$por_especie$especie], " ",
      formatC(modelo$por_especie$r, digits = 3, format = "f", flag = "+", decimal.mark = ","),
      collapse = "  |  "
    ))
  } else if (progresso <= 0.18) {
    "DIVISÃO: três segmentos iguais, ainda com a mesma inclinação"
  } else {
    "TRANSIÇÃO VISUAL: cor, ângulo e tamanho mudam juntos"
  }
  list(pontos = pontos, ramos = ramos, referencia = referencia,
       alpha_ramos = 1, alpha_geral = 0, sincronia = mover,
       etapa = if (progresso <= 0.18) "divisao" else "transformacao",
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
      labels = unname(nomes_pinguins[c("Adelie", "Chinstrap", "Gentoo")]),
      breaks = unname(cores_pinguins[c("Adelie", "Chinstrap", "Gentoo")]), drop = FALSE) +
    ggplot2::coord_cartesian(xlim = c(30, 62), ylim = c(12, 23), expand = FALSE) +
    ggplot2::labs(
      title = "Uma reta geral. Três relações diferentes.",
      subtitle = "Três partes iguais giram e mudam de tamanho e cor até os ajustes por espécie.",
      x = "Comprimento do bico (mm)", y = "Profundidade do bico (mm)", colour = NULL,
      caption = paste0(nrow(modelo$dados), " pinguins com as duas medidas · ", modelo$excluidos,
        " registros excluídos por medida ausente\n",
        "Pontos e eixos fixos. Movimento ilustrativo, sem passagem do tempo.")
    ) + criar_grafico(modelo, FALSE)$theme
}

criar_grafico_transformacao <- function(modelo, progresso) {
  estado <- montar_transformacao(modelo, progresso)
  estado$rotulos <- data.frame(rotulo = estado$rotulo)
  plotar_transformacao(modelo, estado)
}

montar_animacao <- function(modelo) {
  # Pausas nos extremos e movimento calculado quadro a quadro.
  progressos <- c(rep(0, 18), seq(0, 0.18, length.out = 30), rep(0.18, 12),
                 seq(0.18, 1, length.out = 96), rep(1, 24))
  estados <- lapply(seq_along(progressos), function(i) {
    estado <- montar_transformacao(modelo, progressos[[i]])
    estado$rotulos <- data.frame(rotulo = estado$rotulo)
    for (nome in c("pontos", "ramos", "referencia", "rotulos")) {
      estado[[nome]]$quadro <- i
    }
    estado
  })
  dados <- lapply(c("pontos", "ramos", "referencia", "rotulos"), function(nome) {
    do.call(rbind, lapply(estados, function(estado) estado[[nome]]))
  })
  names(dados) <- c("pontos", "ramos", "referencia", "rotulos")
  plotar_transformacao(modelo, dados) + gganimate::transition_manual(quadro)
}
