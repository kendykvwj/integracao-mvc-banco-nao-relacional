class LivrosController < ApplicationController
  before_action :set_livro, only: %i[ show edit update destroy ]

  # GET /livros
  def index
    @todos = Livro.all.to_a
    @livros = Livro.order_by(titulo: :asc)
    if params[:q].present?
      termo = /#{Regexp.escape(params[:q])}/i  # escape evita regex injetada pelo usuario
      @livros = @livros.any_of({ titulo: termo }, { autor: termo }, { categorias: termo })
    end
    @livros = @livros.where(disponivel: params[:status] == "disponivel") if %w[disponivel emprestado].include?(params[:status])
  end

  # GET /livros/1
  def show
  end

  # GET /livros/new
  def new
    @livro = Livro.new
  end

  # GET /livros/1/edit
  def edit
  end

  # POST /livros
  def create
    @livro = Livro.new(livro_params)

    if @livro.save
      redirect_to @livro, notice: "Livro cadastrado."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /livros/1
  def update
    if @livro.update(livro_params)
      redirect_to @livro, notice: "Livro atualizado.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /livros/1
  def destroy
    @livro.destroy!
    redirect_to livros_path, notice: "Livro excluído.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_livro
      @livro = Livro.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def livro_params
      params.expect(livro: [ :titulo, :autor, :ano, :categorias, :editora, :paginas, :disponivel, :avaliacao ])
    end
end
