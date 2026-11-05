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

  validates :titulo, :autor, presence: true
  validates :avaliacao, numericality: { in: 0..5 }, allow_nil: true

  # Form envia "Romance, Classico"; guarda como array no documento.
  def categorias=(valor)
    super(valor.is_a?(String) ? valor.split(",").map(&:strip).reject(&:empty?) : valor)
  end
end
