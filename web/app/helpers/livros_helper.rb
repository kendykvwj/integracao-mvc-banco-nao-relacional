module LivrosHelper
  CAPAS = %w[#5b6b5e #7a6a55 #4f5b66 #6e5f6b #8a7660 #55625a].freeze

  # Cor da "capa" estavel por titulo, para a lista nao mudar a cada request.
  def capa_cor(livro)
    CAPAS[livro.titulo.to_s.sum % CAPAS.size]
  end

  def iniciais(livro)
    livro.titulo.to_s.split.first(2).map { _1[0] }.join.upcase
  end

  def estrelas(nota)
    return tag.span("Sem nota", class: "muted") if nota.nil?
    cheias = nota.round
    tag.span(class: "stars", title: "#{nota} de 5", "aria-label": "#{nota} de 5") do
      safe_join(1.upto(5).map { |i| tag.i(class: i <= cheias ? "on" : nil) }) + tag.b(format("%.1f", nota))
    end
  end

  def icone(nome)
    paths = {
      livros: "M4 19.5A2.5 2.5 0 0 1 6.5 17H20M4 19.5A2.5 2.5 0 0 0 6.5 22H20V2H6.5A2.5 2.5 0 0 0 4 4.5v15z",
      check: "M20 6 9 17l-5-5",
      estrela: "m12 2 3.1 6.3 6.9 1-5 4.9 1.2 6.8L12 17.8 5.8 21l1.2-6.8-5-4.9 6.9-1z",
      mais: "M12 5v14M5 12h14",
      busca: "M21 21l-4.3-4.3M11 18a7 7 0 1 1 0-14 7 7 0 0 1 0 14z",
      banco: "M4 6c0-1.7 3.6-3 8-3s8 1.3 8 3-3.6 3-8 3-8-1.3-8-3zm0 0v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"
    }
    tag.svg(tag.path(d: paths.fetch(nome)), class: "ico", viewBox: "0 0 24 24", "aria-hidden": true)
  end
end
