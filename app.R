preparar <- function(animacao = FALSE) {
  dir.create(".biblioteca", recursive = TRUE, showWarnings = FALSE)
  .libPaths(c(normalizePath(".biblioteca"), .libPaths()))
  pacotes <- c("shiny", "ggplot2", "dplyr", "tidyr", "purrr", "tibble", "readr", "jsonlite")
  if (animacao) pacotes <- c(pacotes, "gganimate", "gifski")
  # R base permite verificar os pacotes antes de instalar qualquer dependência.
  faltam <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
  if (length(faltam)) {
    install.packages(faltam, lib = .libPaths()[1], repos = "https://cloud.r-project.org")
  }
}

gerar_animacao <- function() {
  preparar(animacao = TRUE)
  source("R/modelo.R", encoding = "UTF-8")
  source("R/graficos.R", encoding = "UTF-8")
  modelo <- preparar_dados(ler_pinguins())
  dir.create("www", showWarnings = FALSE)

  # Os gráficos de apoio usam a mesma amostra da animação.
  ggplot2::ggsave("www/todos.png", criar_grafico(modelo, FALSE),
                  width = 10, height = 6.5, dpi = 120)
  ggplot2::ggsave("www/especies.png", criar_grafico(modelo, TRUE),
                  width = 10, height = 6.5, dpi = 120)
  purrr::walk2(c(0, 0.18, 0.59, 1), c("inicio", "divisao", "meio", "fim"), function(valor, nome) {
    ggplot2::ggsave(paste0("www/transformacao_", nome, ".png"),
      criar_grafico_transformacao(modelo, valor), width = 10, height = 6.5, dpi = 120)
  })

  # O GIF é exportado pelo gganimate, sem mover as observações.
  gganimate::animate(montar_animacao(modelo), nframes = 180, fps = 12,
    width = 960, height = 640, res = 105,
    renderer = gganimate::gifski_renderer("www/pinguins.gif", loop = TRUE))
  stopifnot(file.exists("www/pinguins.gif"), file.info("www/pinguins.gif")$size > 1000)
  cat("Animacao real do gganimate gerada em www/pinguins.gif\n")
}

gerar_site <- function() {
  preparar()
  if (!requireNamespace("shinylive", quietly = TRUE)) stop("Instale o pacote shinylive para gerar o site.")
  source("R/modelo.R", encoding = "UTF-8")
  source("R/graficos.R", encoding = "UTF-8")
  source("R/quadros.R", encoding = "UTF-8")
  modelo <- preparar_dados(ler_pinguins())
  quadros <- preparar_quadros(modelo)

  # O site recebe apenas os dados e recursos necessários ao aplicativo.
  entrada <- tempfile("pinguins-shinylive-")
  dir.create(entrada)
  on.exit(unlink(entrada, recursive = TRUE), add = TRUE)
  arquivos <- c("R/modelo.R", "R/graficos.R", "R/quadros.R", "dados/pinguins.csv",
                "www/estilo.css", "www/transformacao.css", "www/quadros.js")
  purrr::walk(arquivos, function(arquivo) {
    destino <- file.path(entrada, arquivo)
    dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(arquivo, destino)) stop("Não foi possível copiar: ", arquivo)
  })

  # As imagens ficam fora do R virtual para não aumentar o download do aplicativo.
  pasta_quadros <- file.path("www", dirname(quadros$manifesto))
  quadros$manifesto <- paste0("../", quadros$manifesto)
  quadros$primeiro <- paste0("../", quadros$primeiro)
  jsonlite::write_json(quadros, file.path(entrada, "quadros_prontos.json"), auto_unbox = TRUE)

  # O navegador não precisa das funções de preparação nem do exportador de GIF.
  arquivo_graficos <- file.path(entrada, "R", "graficos.R")
  expressoes <- parse(arquivo_graficos, keep.source = TRUE)
  exportador <- vapply(expressoes, function(expressao) {
    is.call(expressao) && identical(expressao[[1]], as.name("<-")) &&
      identical(expressao[[2]], as.name("montar_animacao"))
  }, logical(1))
  stopifnot(sum(exportador) == 1L)
  trecho <- attr(expressoes, "srcref")[[which(exportador)]]
  linhas <- readr::read_lines(arquivo_graficos)
  readr::write_lines(linhas[-seq.int(trecho[[1]], trecho[[3]])], arquivo_graficos)

  app <- paste(deparse(body(criar_aplicativo), width.cutoff = 500L), collapse = "\n")
  origem <- "quadros_locais <- preparar_quadros(modelo)"
  if (length(gregexpr(origem, app, fixed = TRUE)[[1]]) != 1L || !grepl(origem, app, fixed = TRUE)) {
    stop("A inicialização dos quadros mudou; revise a exportação.")
  }
  app <- sub(origem,
    'quadros_locais <- jsonlite::read_json("quadros_prontos.json", simplifyVector = TRUE)',
    app, fixed = TRUE)
  readr::write_file(app, file.path(entrada, "app.R"))

  # Somente a pasta gerada é recriada; dados e materiais originais não mudam.
  if (dir.exists("site")) unlink("site", recursive = TRUE)
  shinylive::export(entrada, "site", wasm_packages = TRUE,
    template_params = list(title = "Bicos de pinguins",
      include_in_head = '<link rel="icon" href="data:,">'))
  dir.create(file.path("site", "quadros"))
  if (!file.copy(pasta_quadros, file.path("site", "quadros"), recursive = TRUE)) {
    stop("Não foi possível copiar os quadros da animação.")
  }
  file.create(file.path("site", ".nojekyll"))
  cat("Site gerado em site/.\n")
}

criar_aplicativo <- function() {
  if (dir.exists(".biblioteca")) .libPaths(c(normalizePath(".biblioteca"), .libPaths()))
  library(shiny)
  source("R/modelo.R", encoding = "UTF-8")
  source("R/graficos.R", encoding = "UTF-8")
  source("R/quadros.R", encoding = "UTF-8")
  modelo <- preparar_dados(ler_pinguins())
  quadros_locais <- preparar_quadros(modelo)

  ui <- fluidPage(
    tags$head(
      tags$title("visualização de dados com animação - bicos de pinguin"),
      tags$link(rel = "stylesheet", type = "text/css", href = "estilo.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "transformacao.css"),
      tags$script(src = paste0("quadros.js?v=", unname(tools::md5sum("www/quadros.js"))), defer = "defer"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
    ),
    tags$main(class = "pagina",
      tags$header(class = "cabecalho",
        tags$p(class = "sobretitulo", "DESAFIO 03 · EXEMPLO EM SHINY + GGANIMATE"),
        tags$h1("O grupo muda a história."),
        tags$p(class = "abertura", "Uma correlação negativa no conjunto inteiro. Relações positivas dentro de cada espécie."),
        tags$div(class = "etiquetas",
          tags$span(paste(nrow(modelo$dados), "pinguins analisados")),
          tags$span("3 espécies"), tags$span("Mesmos pontos · mesmos eixos")
        )
      ),
      tabsetPanel(id = "aba", type = "pills",
        tabPanel("Animação", value = "animacao",
          tags$section(class = "painel",
            tags$div(class = "titulo-painel",
              tags$h2("Uma reta geral. Três relações diferentes."),
              tags$p("Comprimento e profundidade do bico: correlação geral e por espécie.")
            ),
            tags$p(id = "estado_transicao", class = "estado-transformacao", rotulo_correlacao(modelo, FALSE)),
            tags$div(id = "grafico_transformacao", class = "quadros-animacao",
              `data-manifesto` = quadros_locais$manifesto,
              tags$img(src = quadros_locais$primeiro, alt = "Gráfico da animação dos pinguins")),
            tags$div(id = "controle_quadros", class = "controle-slider",
              sliderInput("quadro", "Avançar ou voltar na animação",
                min = 1, max = length(sequencia_animacao()), value = 1, step = 1,
                width = "100%", animate = animationOptions(interval = 1000 / 12, loop = FALSE)),
              tags$div(id = "posicao_animacao", "Quadro 1 de 180 · posição no vídeo: 0,0 s"),
              tags$p(id = "carregamento_quadros", role = "status", `aria-live` = "polite", "Carregando quadros…")
            ),
            tags$p(class = "nota", "Arraste o controle para frente ou para trás. Os pontos e os eixos permanecem fixos.")
          )
        ),
        tabPanel("Explore as duas leituras", value = "explorar",
          tags$section(class = "painel explorador",
            tags$div(class = "titulo-painel",
              tags$h2("Qual comparação estamos fazendo?"),
              radioButtons("modo", NULL,
                           choices = c("Todos misturados" = "geral", "Separar por espécie" = "especies"),
                           selected = "geral", inline = TRUE)
            ),
            uiOutput("metricas"),
            plotOutput("grafico", height = "480px"),
            uiOutput("interpretacao")
          )
        )
      ),
      tags$footer("Protótipo didático · Dados reais · Associação não é causalidade")
    )
  )

  server <- function(input, output, session) {
    resumo_ativo <- reactive({
      if (identical(input$modo, "especies")) {
        modelo$por_especie
      } else {
        tibble::tibble(especie = "Todos", n = nrow(modelo$dados), r = modelo$r_geral)
      }
    })
    output$metricas <- renderUI({
      resumo <- resumo_ativo()
      # pmap cria um cartão para cada linha do resumo, usando seus nomes de coluna.
      tags$div(class = "metricas", purrr::pmap(resumo, function(especie, n, r) {
        tags$div(class = "metrica", style = paste0("--cor:", cores_pinguins[[especie]]),
          tags$span(class = "nome-grupo", nomes_pinguins[[especie]]),
          tags$strong(paste0("r = ", formatC(r, format = "f", digits = 3, decimal.mark = ","))),
          tags$span(class = "amostra", paste(n, "observações · Pearson"))
        )
      }))
    })
    output$grafico <- renderPlot({
      criar_grafico(modelo, separar = identical(input$modo, "especies")) +
        ggplot2::labs(title = NULL, subtitle = NULL, caption = NULL) +
        ggplot2::guides(colour = ggplot2::guide_legend(nrow = 2, byrow = TRUE))
    }, res = 110)
    output$interpretacao <- renderUI({
      if (identical(input$modo, "especies")) {
        tags$p(class = "conclusao", "Dentro de cada espécie, a associação é positiva: as duas medidas tendem a variar juntas. Os pinguins não mudaram; revelamos os grupos.")
      } else {
        tags$p(class = "conclusao", "No conjunto misturado, a associação é negativa. Esse resumo sozinho esconde o comportamento dentro das espécies.")
      }
    })
  }

  shinyApp(ui = ui, server = server)
}

iniciar <- function() {
  preparar()
  if (!file.exists("www/pinguins.gif")) gerar_animacao()
  porta <- as.integer(Sys.getenv("PINGUINS_PORTA", "4287"))
  shiny::runApp(".", host = "127.0.0.1", port = porta, launch.browser = interactive())
}

# No terminal, permite escolher uma tarefa sem abrir o Shiny para gerar arquivos.
if (sys.nframe() == 0L) {
  argumentos <- commandArgs(trailingOnly = TRUE)
  if (length(argumentos) > 1L) stop("Use: Rscript app.R [app|animacao|site|preparar]")
  acao <- if (length(argumentos)) argumentos[[1]] else "app"
  switch(acao, app = iniciar(), animacao = gerar_animacao(), site = gerar_site(),
    preparar = preparar(), stop("Use: Rscript app.R [app|animacao|site|preparar]"))
} else {
  # Mantém app.R compatível com Run App e shiny::runApp().
  preparar()
  criar_aplicativo()
}
