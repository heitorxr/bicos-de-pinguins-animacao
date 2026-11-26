/* O R calcula e desenha os quadros. Aqui apenas escolhemos a imagem já carregada. */
(() => {
  async function iniciar() {
    const painel = document.getElementById("grafico_transformacao");
    const entrada = document.getElementById("quadro");
    if (!painel || !entrada) return;
    const slider = window.jQuery?.(entrada).data("ionRangeSlider");
    if (!slider) return setTimeout(iniciar, 50);

    const carregamento = document.getElementById("carregamento_quadros");
    const controle = document.getElementById("controle_quadros");
    const posicao = document.getElementById("posicao_animacao");
    const rotulo = document.getElementById("estado_transicao");
    const pequeno = matchMedia("(max-width: 700px)");
    const bancos = {};
    let manifesto, banco, pronto = false, geracao = 0;

    function mostrar(quadro) {
      if (!pronto) return;
      const numero = Math.max(1, Math.min(manifesto.total, Math.round(Number(quadro))));
      const imagem = banco.get(manifesto.quadros[numero - 1]);
      imagem.alt = `Gráfico da animação: quadro ${numero} de ${manifesto.total}`;
      if (painel.firstElementChild !== imagem) painel.replaceChildren(imagem);
      painel.dataset.quadro = String(numero);
      rotulo.textContent = manifesto.rotulos[numero - 1];
      const segundos = ((numero - 1) / manifesto.fps).toFixed(1).replace(".", ",");
      posicao.textContent = `Quadro ${numero} de ${manifesto.total} · posição no vídeo: ${segundos} s`;
    }

    function habilitar(valor) {
      pronto = valor;
      slider.update({disable: !valor});
      controle.classList.toggle("quadros-carregando", !valor);
      painel.dataset.quadrosProntos = String(valor);
    }

    async function carregar() {
      const atual = ++geracao;
      const tamanho = pequeno.matches ? "compacto" : "desktop";
      habilitar(false);
      if (!bancos[tamanho]) {
        const imagens = new Map();
        const arquivos = [...new Set(manifesto.quadros)];
        let proximo = 0, carregados = 0;
        carregamento.textContent = "Carregando quadros…";
        async function trabalhador() {
          while (proximo < arquivos.length && atual === geracao) {
            const arquivo = arquivos[proximo++];
            const imagem = new Image();
            imagem.decoding = "async";
            imagem.src = new URL(`${tamanho}/${arquivo}`, new URL(painel.dataset.manifesto, document.baseURI)).href;
            await imagem.decode();
            imagens.set(arquivo, imagem);
            carregamento.textContent = `Carregando quadros: ${++carregados} de ${arquivos.length}`;
          }
        }
        // Limita as transferências simultâneas sem bloquear a página.
        await Promise.all(Array.from({length: 6}, trabalhador));
        if (atual !== geracao) return;
        bancos[tamanho] = imagens;
      }
      banco = bancos[tamanho];
      habilitar(true);
      mostrar(slider.result.from);
      carregamento.textContent = "Quadros carregados. Pronto para arrastar.";
    }

    function falhou(erro) {
      habilitar(false);
      carregamento.textContent = "Não foi possível carregar os quadros. Recarregue a página.";
      console.error("Carregamento da animação:", erro);
    }

    try {
      habilitar(false);
      const resposta = await fetch(painel.dataset.manifesto);
      if (!resposta.ok) throw new Error(`Manifesto: HTTP ${resposta.status}`);
      manifesto = await resposta.json();
      window.jQuery(entrada).on("input.quadros change.quadros", () => mostrar(slider.result.from));
      slider.update({onChange: dados => mostrar(dados.from)});
      // Um toque pode adiar o evento da biblioteca; o valor já está calculado ao soltar.
      controle.addEventListener("pointerup", () => mostrar(slider.result.from));
      pequeno.addEventListener("change", () => carregar().catch(falhou));
      await carregar();
    } catch (erro) {
      falhou(erro);
    }
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", iniciar);
  else iniciar();
})();
