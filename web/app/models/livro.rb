class Livro
  include Mongoid::Document
  store_in collection: "livros", database: ENV.fetch("MONGODB_DB", "biblioteca")

  field :titulo, type: String
  field :autor, type: String
  field :ano, type: Integer
  field :categorias, type: Array, default: []
  field :editora, type: String
  field :paginas, type: Integer
  field :disponivel, type: Mongoid::Boolean, default: true
  field :avaliacao, type: Float

  embeds_many :resenhas, order: :created_at.desc
  embeds_many :emprestimos

  # Criar no Atlas com: bin/rails db:mongoid:create_indexes
  index({ titulo: "text", autor: "text", categorias: "text" }, { name: "busca_texto", default_language: "portuguese" })
  index({ categorias: 1 }) # multikey: um registro de indice por item do array

  validates :titulo, :autor, presence: true
  validates :avaliacao, numericality: { in: 0..5 }, allow_nil: true

  # Form envia "Romance, Classico"; guarda como array no documento.
  def categorias=(valor)
    super(valor.is_a?(String) ? valor.split(",").map(&:strip).reject(&:empty?) : valor)
  end

  # $text usa o indice e devolve ids por relevancia; nao casa prefixo ("Dom Cas"), entao cai na regex quando vazio.
  def self.ids_por_relevancia(termo)
    collection.find({ "$text" => { "$search" => termo } }, projection: { score: { "$meta" => "textScore" } })
              .sort(score: { "$meta" => "textScore" }).map { _1["_id"] }
  rescue Mongo::Error::OperationFailure # indice de texto ainda nao criado
    []
  end

  def self.busca_regex(termo)
    regex = /#{Regexp.escape(termo)}/i # escape evita regex injetada pelo usuario
    any_of({ titulo: regex }, { autor: regex }, { categorias: regex })
  end

  # Um round-trip: $facet roda varios pipelines sobre a mesma leitura da colecao.
  def self.painel
    tamanho = ->(campo) { { "$size" => { "$ifNull" => [ "$#{campo}", [] ] } } }
    collection.aggregate([
      { "$facet" => {
        "resumo" => [ { "$group" => {
          "_id" => nil, "total" => { "$sum" => 1 },
          "disponiveis" => { "$sum" => { "$cond" => [ "$disponivel", 1, 0 ] } },
          "media" => { "$avg" => "$avaliacao" },
          "resenhas" => { "$sum" => tamanho.("resenhas") },
          "emprestimos" => { "$sum" => tamanho.("emprestimos") }
        } } ],
        "por_categoria" => [ { "$unwind" => "$categorias" },
                             { "$group" => { "_id" => "$categorias", "total" => { "$sum" => 1 } } },
                             { "$sort" => { "total" => -1, "_id" => 1 } }, { "$limit" => 8 } ],
        "por_decada" => [ { "$match" => { "ano" => { "$type" => "number" } } },
                          { "$group" => { "_id" => { "$multiply" => [ { "$floor" => { "$divide" => [ "$ano", 10 ] } }, 10 ] }, "total" => { "$sum" => 1 } } },
                          { "$sort" => { "_id" => 1 } } ],
        "mais_resenhados" => [ { "$unwind" => "$resenhas" },
                               { "$group" => { "_id" => "$_id", "titulo" => { "$first" => "$titulo" },
                                               "media" => { "$avg" => "$resenhas.nota" }, "qtd" => { "$sum" => 1 } } },
                               { "$sort" => { "media" => -1, "qtd" => -1 } }, { "$limit" => 5 } ],
        "leitores" => [ { "$unwind" => "$emprestimos" },
                        { "$group" => { "_id" => "$emprestimos.leitor", "total" => { "$sum" => 1 } } },
                        { "$sort" => { "total" => -1, "_id" => 1 } }, { "$limit" => 5 } ]
      } }
    ]).first.tap { _1["resumo"] = _1["resumo"].first || { "total" => 0, "disponiveis" => 0 } }
  end
end
