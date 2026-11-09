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

montar_animacao <- function(modelo) {
  criar_grafico(modelo, separar = NULL) +
    ggplot2::labs(subtitle = "{closest_state}") +
    gganimate::transition_states(etapa, transition_length = 2, state_length = 3, wrap = TRUE) +
    gganimate::enter_fade() + gganimate::exit_fade() +
    gganimate::ease_aes("cubic-in-out")
}
