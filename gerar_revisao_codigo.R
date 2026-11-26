.libPaths(c(normalizePath(".biblioteca"), .libPaths()))

# Lê os arquivos principais do projeto, sem executar o conteúdo deles.
arquivos <- c("iniciar.R", "preparar.R", "app.R", "R/modelo.R", "R/graficos.R", "R/quadros.R", "www/quadros.js", "gerar_animacao.R")
blocos <- purrr::imap(arquivos, function(arquivo, indice) {
  linhas <- readr::read_lines(arquivo)
  codigo <- sprintf("%3d | %s", seq_along(linhas), linhas) |>
    trimws(which = "right") |>
    paste(collapse = "\n")
  htmltools::tags$details(
    open = if (indice == 1L) "open" else NULL,
    htmltools::tags$summary(arquivo),
    htmltools::tags$pre(htmltools::tags$code(codigo))
  )
})

# A página funciona como arquivo local: não depende de servidor nem de internet.
pagina <- htmltools::tags$html(lang = "pt-BR",
  htmltools::tags$head(
    htmltools::tags$meta(charset = "utf-8"),
    htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    htmltools::tags$title("Revisão do código — pinguins"),
    htmltools::tags$style("body{font:16px system-ui;max-width:1100px;margin:24px auto;padding:0 18px;color:#172b40;background:#fff}h1{font-size:26px}p{color:#526675}details{border-top:1px solid #dce5eb;padding:8px 0}summary{cursor:pointer;font-weight:600;padding:12px 0}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f0f4f8;padding:18px;border-radius:8px;font-size:14px;line-height:1.65}code{font-family:Consolas,monospace}")
  ),
  htmltools::tags$body(
    htmltools::tags$h1("Revisão do código — animação dos pinguins"),
    htmltools::tags$p("Clique no nome de cada arquivo para abrir ou fechar o código completo. Somente leitura; nada é executado nesta página."),
    htmltools::tags$p(paste("Cópia gerada em", format(Sys.time(), "%d/%m/%Y %H:%M %Z"))),
    blocos
  )
)
htmltools::save_html(pagina, "Revisao-Codigo-Pinguins.html")
cat("Revisor local gerado em Revisao-Codigo-Pinguins.html\n")
