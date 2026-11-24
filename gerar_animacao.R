source("preparar.R", encoding = "UTF-8")
source("R/modelo.R", encoding = "UTF-8")
source("R/graficos.R", encoding = "UTF-8")

# Usa a mesma amostra nos gráficos geral, por espécie e em todos os quadros.
modelo <- preparar_dados(ler_pinguins())
dir.create("www", showWarnings = FALSE)

# Salva os gráficos de apoio, sem precisar abrir o aplicativo.
ggplot2::ggsave("www/todos.png", criar_grafico(modelo, FALSE),
                width = 10, height = 6.5, dpi = 120)
ggplot2::ggsave("www/especies.png", criar_grafico(modelo, TRUE),
                width = 10, height = 6.5, dpi = 120)
purrr::walk2(c(0, 0.18, 0.59, 1), c("inicio", "divisao", "meio", "fim"), function(valor, nome) {
  ggplot2::ggsave(paste0("www/transformacao_", nome, ".png"),
    criar_grafico_transformacao(modelo, valor), width = 10, height = 6.5, dpi = 120)
})

# O GIF é exportado diretamente pelo gganimate; os pontos permanecem fixos.
animacao <- gganimate::animate(
  montar_animacao(modelo),
  nframes = 180,
  fps = 12,
  width = 960,
  height = 640,
  res = 105,
  renderer = gganimate::gifski_renderer("www/pinguins.gif", loop = TRUE)
)
stopifnot(file.exists("www/pinguins.gif"), file.info("www/pinguins.gif")$size > 1000)
cat("Animacao real do gganimate gerada em www/pinguins.gif\n")
