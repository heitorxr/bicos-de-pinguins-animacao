preparar_dados <- function(dados) {
  usados <- complete.cases(dados[, c("species", "bill_len", "bill_dep")])
  limpos <- dados[usados, , drop = FALSE]
  limpos$species <- factor(limpos$species, levels = c("Adelie", "Chinstrap", "Gentoo"))
  limpos$id <- which(usados)
  por_especie <- do.call(rbind, lapply(levels(limpos$species), function(especie) {
    parte <- limpos[limpos$species == especie, , drop = FALSE]
    data.frame(especie = especie, n = nrow(parte),
               r = cor(parte$bill_len, parte$bill_dep))
  }))
  rownames(por_especie) <- NULL
  list(dados = limpos, excluidos = sum(!usados),
       r_geral = cor(limpos$bill_len, limpos$bill_dep),
       por_especie = por_especie)
}
