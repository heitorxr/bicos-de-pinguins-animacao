source("preparar.R", encoding = "UTF-8")
if (!file.exists("www/pinguins.gif")) source("gerar_animacao.R", encoding = "UTF-8")
shiny::runApp(".", host = "127.0.0.1", port = 4287, launch.browser = TRUE)
