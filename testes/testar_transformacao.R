args <- commandArgs(trailingOnly = TRUE)
raiz <- if (length(args)) args[[1]] else getwd()
.libPaths(c(file.path(raiz, ".biblioteca"), .libPaths()))
source(file.path(raiz, "R", "modelo.R"), encoding = "UTF-8")
source(file.path(raiz, "R", "graficos.R"), encoding = "UTF-8")
if (!exists("montar_transformacao", mode = "function")) {
  stop("A transformacao da reta geral em tres retas ainda nao foi implementada.")
}
modelo <- preparar_dados(read.csv(file.path(raiz, "dados", "pinguins.csv")))
a <- montar_transformacao(modelo, 0)
b <- montar_transformacao(modelo, 0.6)
c <- montar_transformacao(modelo, 1)

# Os dados nao se movem: so as retas interpoladas e seus estilos mudam.
for (estado in list(a, b, c)) {
  stopifnot(identical(estado$pontos$id, modelo$dados$id))
  stopifnot(identical(estado$pontos$bill_len, modelo$dados$bill_len))
  stopifnot(identical(estado$pontos$bill_dep, modelo$dados$bill_dep))
  stopifnot(setequal(unique(estado$ramos$grupo), levels(modelo$dados$species)))
}
ajuste_geral <- lm(bill_dep ~ bill_len, data = modelo$dados)
for (grupo in levels(modelo$dados$species)) {
  inicio <- a$ramos[a$ramos$grupo == grupo, ]
  fim <- c$ramos[c$ramos$grupo == grupo, ]
  dados <- modelo$dados[modelo$dados$species == grupo, ]
  ajuste <- lm(bill_dep ~ bill_len, data = dados)
  stopifnot(isTRUE(all.equal(inicio$y, as.numeric(predict(
    ajuste_geral, newdata = data.frame(bill_len = inicio$x)
  )))))
  stopifnot(isTRUE(all.equal(fim$y, as.numeric(predict(
    ajuste, newdata = data.frame(bill_len = fim$x)
  )))))
  stopifnot(coef(lm(y ~ x, data = inicio))[[2]] < 0)
  stopifnot(coef(lm(y ~ x, data = fim))[[2]] > 0)
}
stopifnot(!isTRUE(all.equal(a$ramos$y, b$ramos$y)))
stopifnot(!isTRUE(all.equal(b$ramos$y, c$ramos$y)))
stopifnot(a$alpha_ramos == 1, a$alpha_geral == 0, a$sincronia == 0)
stopifnot(c$alpha_ramos == 1, c$alpha_geral == 0)
stopifnot(b$intermediario, !a$intermediario, !c$intermediario)
stopifnot(identical(b$rotulo, c$rotulo))

# O grafico usa limites fixos e a animacao continua sendo gganimate.
paineis <- lapply(c(0, 0.6, 1), function(t) {
  p <- criar_grafico_transformacao(modelo, t)
  stopifnot(inherits(p, "ggplot"))
  ggplot2::ggplot_build(p)$layout$panel_params[[1]]
})
stopifnot(identical(paineis[[1]]$x.range, paineis[[3]]$x.range))
stopifnot(identical(paineis[[1]]$y.range, paineis[[3]]$y.range))
stopifnot(inherits(montar_animacao(modelo), "gganim"))
cat("PASSOU: partes da reta geral no inicio, ajustes corretos no fim, movimento real das retas, dados fixos e eixos preservados.\n")
