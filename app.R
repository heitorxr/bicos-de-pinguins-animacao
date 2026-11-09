if (dir.exists(".biblioteca")) .libPaths(c(normalizePath(".biblioteca"), .libPaths()))
library(shiny)
source("R/modelo.R", encoding = "UTF-8")
source("R/graficos.R", encoding = "UTF-8")
modelo <- preparar_dados(read.csv("dados/pinguins.csv", stringsAsFactors = FALSE))

ui <- fluidPage(
  tags$head(
    tags$title("Os mesmos pinguins. Duas leituras."),
    tags$link(rel = "stylesheet", type = "text/css", href = "estilo.css"),
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
            tags$h2("Olhe primeiro o conjunto. Depois, os grupos."),
            tags$p("Os pontos ficam no mesmo lugar. A animação revela as espécies e troca a reta geral pelas retas de cada grupo.")
          ),
          tags$img(src = "pinguins.gif", class = "animacao",
                   alt = "Animação: correlação negativa no conjunto misturado e positiva nas três espécies, mantendo as mesmas coordenadas."),
          tags$p(class = "nota", "Transição didática, não passagem do tempo. As medidas dos pinguins não são alteradas.")
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
      ),
      tabPanel("O que isso significa?", value = "explicacao",
        tags$section(class = "painel explicacao",
          tags$h2("A conta está certa. O contexto estava escondido."),
          tags$p("Ao misturar as espécies, a reta geral combina diferenças entre grupos com as relações dentro de cada grupo. Revelar a espécie muda a pergunta que fazemos aos mesmos dados."),
          tags$h3("O que foi comparado"),
          tags$p("Comprimento e profundidade do bico, ambos em milímetros. Cada ponto é um pinguim e cada reta é um ajuste linear."),
          tags$h3("O que não podemos concluir"),
          tags$p("Correlação não demonstra causalidade. As retas descrevem associações nesta amostra; não afirmam que mudar uma medida faria a outra mudar."),
          tags$h3("Dados ausentes"),
          tags$p(paste0("A base tem 344 registros. Foram excluídos somente ", modelo$excluidos,
                        " registros sem as duas medidas necessárias. Espécie, coordenadas e amostra são as mesmas nas duas leituras.")),
          tags$h3("Fonte"),
          tags$p("Palmer Penguins, dados coletados entre 2007 e 2009. Cópia incluída a partir de datasets::penguins do R 4.5.2, derivada dos dados de Gorman, Williams e Fraser. Dados disponibilizados sob CC0."),
          tags$a("Documentação da base no R", href = "https://stat.ethz.ch/R-manual/R-devel/library/datasets/html/penguins.html", target = "_blank", rel = "noopener")
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
      data.frame(especie = "Todos", n = nrow(modelo$dados), r = modelo$r_geral)
    }
  })
  output$metricas <- renderUI({
    resumo <- resumo_ativo()
    tags$div(class = "metricas", lapply(seq_len(nrow(resumo)), function(i) {
      grupo <- resumo$especie[[i]]
      tags$div(class = "metrica", style = paste0("--cor:", cores_pinguins[[grupo]]),
        tags$span(class = "nome-grupo", nomes_pinguins[[grupo]]),
        tags$strong(paste0("r = ", formatC(resumo$r[[i]], format = "f", digits = 3, decimal.mark = ","))),
        tags$span(class = "amostra", paste(resumo$n[[i]], "observações · Pearson"))
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
