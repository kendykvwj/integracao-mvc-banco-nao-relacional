# Historico de emprestimos embutido: emprestar/devolver altera um unico documento (atomico).
class Emprestimo
  include Mongoid::Document
  embedded_in :livro

  field :leitor, type: String
  field :retirado_em, type: Date, default: -> { Date.current }
  field :devolvido_em, type: Date

  validates :leitor, presence: true

  def aberto? = devolvido_em.nil?
end
