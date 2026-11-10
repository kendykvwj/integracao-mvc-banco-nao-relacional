class ResenhasController < ApplicationController
  before_action { @livro = Livro.find(params.expect(:livro_id)) }

  # POST /livros/1/resenhas
  def create
    resenha = @livro.resenhas.build(params.expect(resenha: [ :leitor, :nota, :texto ]))
    if resenha.save
      redirect_to @livro, notice: "Resenha publicada."
    else
      redirect_to @livro, alert: resenha.errors.full_messages.to_sentence
    end
  end

  # DELETE /livros/1/resenhas/2
  def destroy
    @livro.resenhas.find(params.expect(:id)).destroy
    redirect_to @livro, notice: "Resenha removida.", status: :see_other
  end
end
