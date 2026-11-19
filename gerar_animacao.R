source("preparar.R", encoding = "UTF-8")
source("R/modelo.R", encoding = "UTF-8")
source("R/graficos.R", encoding = "UTF-8")
modelo <- preparar_dados(read.csv("dados/pinguins.csv", stringsAsFactors = FALSE))
dir.create("www", showWarnings = FALSE)
ggplot2::ggsave("www/todos.png", criar_grafico(modelo, FALSE),
                width = 10, height = 6.5, dpi = 120)
ggplot2::ggsave("www/especies.png", criar_grafico(modelo, TRUE),
                width = 10, height = 6.5, dpi = 120)
for (valor in c(0, 0.18, 0.59, 1)) {
  nome <- c("inicio", "divisao", "meio", "fim")[[match(valor, c(0, 0.18, 0.59, 1))]]
  ggplot2::ggsave(paste0("www/transformacao_", nome, ".png"),
    criar_grafico_transformacao(modelo, valor), width = 10, height = 6.5, dpi = 120)
}
animacao <- gganimate::animate(
  montar_animacao(modelo), nframes = 180, fps = 12,
  width = 960, height = 640, res = 105,
  renderer = gganimate::gifski_renderer("www/pinguins.gif", loop = TRUE)
)
stopifnot(file.exists("www/pinguins.gif"), file.info("www/pinguins.gif")$size > 1000)
cat("Animacao real do gganimate gerada em www/pinguins.gif\n")
