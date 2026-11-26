source("preparar.R", encoding = "UTF-8")
if (!file.exists("www/pinguins.gif")) source("gerar_animacao.R", encoding = "UTF-8")
porta <- as.integer(Sys.getenv("PINGUINS_PORTA", "4287"))
shiny::runApp(".", host = "127.0.0.1", port = porta, launch.browser = interactive())
