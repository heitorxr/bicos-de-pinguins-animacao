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
