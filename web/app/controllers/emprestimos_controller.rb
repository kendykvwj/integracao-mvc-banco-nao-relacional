class EmprestimosController < ApplicationController
  before_action { @livro = Livro.find(params.expect(:livro_id)) }

  # POST /livros/1/emprestimos
  def create
    return redirect_to(@livro, alert: "Livro já está emprestado.") unless @livro.disponivel
    emprestimo = @livro.emprestimos.build(params.expect(emprestimo: [ :leitor ]))
    @livro.disponivel = false
    # Um unico update no documento: $push do emprestimo + $set disponivel=false.
    if emprestimo.valid? && @livro.save
      redirect_to @livro, notice: "Empréstimo registrado para #{emprestimo.leitor}."
    else
      redirect_to @livro, alert: emprestimo.errors.full_messages.to_sentence.presence || "Não foi possível emprestar."
    end
  end

  # PATCH /livros/1/emprestimos/2/devolver
  def devolver
    emprestimo = @livro.emprestimos.find(params.expect(:id))
    emprestimo.devolvido_em = Date.current
    @livro.disponivel = true
    @livro.save!
    redirect_to @livro, notice: "Devolução registrada.", status: :see_other
  end
end
