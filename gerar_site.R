# Executar da raiz do projeto, com os pacotes do app e shinylive instalados.
if (dir.exists(".biblioteca")) .libPaths(c(normalizePath(".biblioteca"), .libPaths()))
if (!requireNamespace("shinylive", quietly = TRUE)) stop("Instale o pacote shinylive para gerar o site.")

source("R/modelo.R", encoding = "UTF-8")
source("R/graficos.R", encoding = "UTF-8")
source("R/quadros.R", encoding = "UTF-8")
modelo <- preparar_dados(ler_pinguins())
quadros <- preparar_quadros(modelo)

# O site recebe apenas os dados e recursos necessários ao aplicativo.
entrada <- tempfile("pinguins-shinylive-")
dir.create(entrada)
arquivos <- c("R/modelo.R", "R/graficos.R", "R/quadros.R", "dados/pinguins.csv",
              "www/estilo.css", "www/transformacao.css", "www/quadros.js")
purrr::walk(arquivos, function(arquivo) {
  destino <- file.path(entrada, arquivo)
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(arquivo, destino)) stop("Não foi possível copiar: ", arquivo)
})

# As imagens ficam fora do R virtual; o navegador baixa apenas o tamanho necessário.
pasta_quadros <- file.path("www", dirname(quadros$manifesto))
quadros$manifesto <- paste0("../", quadros$manifesto)
quadros$primeiro <- paste0("../", quadros$primeiro)
jsonlite::write_json(quadros, file.path(entrada, "quadros_prontos.json"), auto_unbox = TRUE)

# A exportação do GIF não é usada no navegador; evita baixar suas dependências.
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

# Na versão web, evita desenhar novamente todos os quadros em cada visita.
app <- readr::read_file("app.R")
origem <- "quadros_locais <- preparar_quadros(modelo)"
if (length(gregexpr(origem, app, fixed = TRUE)[[1]]) != 1L || !grepl(origem, app, fixed = TRUE)) {
  stop("A inicialização dos quadros mudou; revise a exportação.")
}
app <- sub(origem,
           'quadros_locais <- jsonlite::read_json("quadros_prontos.json", simplifyVector = TRUE)',
           app, fixed = TRUE)
readr::write_file(app, file.path(entrada, "app.R"))

# Somente a pasta de saída gerada é recriada; os materiais do projeto não mudam.
if (dir.exists("site")) unlink("site", recursive = TRUE)
shinylive::export(entrada, "site", wasm_packages = TRUE,
                  template_params = list(title = "Bicos de pinguins",
                    include_in_head = '<link rel="icon" href="data:,">'))
dir.create(file.path("site", "quadros"))
if (!file.copy(pasta_quadros, file.path("site", "quadros"), recursive = TRUE)) {
  stop("Não foi possível copiar os quadros da animação.")
}
file.create(file.path("site", ".nojekyll"))
unlink(entrada, recursive = TRUE)
cat("Site gerado em site/.\n")
