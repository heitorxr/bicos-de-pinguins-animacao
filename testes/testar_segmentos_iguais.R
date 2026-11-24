args <- commandArgs(trailingOnly = TRUE)
raiz <- if (length(args)) args[[1]] else getwd()
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
source(file.path(raiz, "R", "modelo.R"), encoding = "UTF-8")
source(file.path(raiz, "R", "graficos.R"), encoding = "UTF-8")
modelo <- preparar_dados(read.csv(file.path(raiz, "dados", "pinguins.csv")))
inicio <- montar_transformacao(modelo, 0)
partes <- split(inicio$ramos, inicio$ramos$grupo)
ajuste <- lm(bill_dep ~ bill_len, data = modelo$dados)
faixa <- range(modelo$dados$bill_len)
comprimento_total <- diff(faixa) * sqrt(1 + coef(ajuste)[[2]]^2)
comprimentos <- vapply(partes, function(z) sqrt(diff(range(z$x))^2 + diff(range(z$y))^2), numeric(1))
if (!isTRUE(all.equal(unname(comprimentos), rep(unname(comprimento_total / 3), 3))))
  stop("RED: a reta geral deve ser repartida em tres segmentos iguais, nao copiada tres vezes")
intervalos <- do.call(rbind, lapply(partes, function(z) range(z$x)))
intervalos <- intervalos[order(intervalos[, 1]), , drop = FALSE]
stopifnot(isTRUE(all.equal(unname(intervalos[1, 1]), faixa[1])), isTRUE(all.equal(unname(intervalos[3, 2]), faixa[2])),
  isTRUE(all.equal(unname(intervalos[1:2, 2]), unname(intervalos[2:3, 1]))))
separado <- inicio
meio <- montar_transformacao(modelo, 0.59)
fim <- montar_transformacao(modelo, 1)
for (estado in list(inicio, separado, meio, fim)) {
  stopifnot(all(c("angulo", "comprimento", "sincronia", "cor") %in% names(estado$ramos)),
    identical(estado$pontos$id, modelo$dados$id), identical(estado$pontos$bill_len, modelo$dados$bill_len),
    identical(estado$pontos$bill_dep, modelo$dados$bill_dep))
}
cedo <- montar_transformacao(modelo, 0.09)
if (cedo$sincronia <= 0 || all(cedo$ramos$cor == cores_pinguins[["Todos"]]))
  stop("RED: giro e cor devem comecar juntos, sem abrir lacunas antes")
for (grupo in names(partes)) {
  a <- inicio$ramos[inicio$ramos$grupo == grupo, ]; b <- meio$ramos[meio$ramos$grupo == grupo, ]
  c <- fim$ramos[fim$ramos$grupo == grupo, ]; s <- separado$ramos[separado$ramos$grupo == grupo, ]
  centro <- function(z) c(mean(range(z$x)), mean(range(z$y)))
  stopifnot(isTRUE(all.equal(centro(b), (1-b$sincronia[1])*centro(a) + b$sincronia[1]*centro(c))),
    all(b$sincronia > 0 & b$sincronia < 1),
    isTRUE(all.equal((b$angulo - s$angulo) / (c$angulo - s$angulo), b$sincronia)))
  w <- b$sincronia[1]
  rgb <- round((1-w)*grDevices::col2rgb(cores_pinguins[["Todos"]]) + w*grDevices::col2rgb(cores_pinguins[[grupo]]))
  esperado <- grDevices::rgb(rgb[1], rgb[2], rgb[3], maxColorValue = 255)
  stopifnot(all(b$cor == esperado), all(a$cor == cores_pinguins[["Todos"]]), all(c$cor == cores_pinguins[[grupo]]))
  regressao <- lm(bill_dep ~ bill_len, data = modelo$dados[modelo$dados$species == grupo, ])
  stopifnot(isTRUE(all.equal(c$y, as.numeric(predict(regressao, newdata = data.frame(bill_len = c$x))))))
}
escala <- ggplot2::ggplot_build(criar_grafico_transformacao(modelo, 0))$plot$scales$get_scales("colour")
if (!identical(unname(escala$get_labels(escala$get_breaks())), c("Geral", unname(nomes_pinguins[c("Adelie", "Chinstrap", "Gentoo")]))))
  stop("RED: a legenda deve mostrar Geral e os nomes das especies, nao codigos hexadecimais")
cat("PASSOU: tres partes inicialmente coladas; separacao pelo proprio movimento; giro e cor sincronizados.\n")
