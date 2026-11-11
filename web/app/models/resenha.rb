# Embutida no documento do livro: lida sempre junto com ele, sem JOIN.
class Resenha
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  embedded_in :livro

  field :leitor, type: String
  field :nota, type: Integer
  field :texto, type: String

  validates :leitor, presence: true
  validates :nota, numericality: { only_integer: true, in: 1..5 }
end
