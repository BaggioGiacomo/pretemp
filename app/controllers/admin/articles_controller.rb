class Admin::ArticlesController < AdminController
  before_action :set_article, only: [ :show, :edit, :update, :destroy ]

  def index
    @articles = Article.ordered
  end

  def show
    redirect_to edit_admin_article_path(@article)
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to admin_articles_path, notice: "Articolo creato con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @article.update(article_params)
      redirect_to admin_articles_path, notice: "Articolo aggiornato con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to admin_articles_path, notice: "Articolo eliminato con successo."
  end

  private

    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(:title, :body, :published)
    end
end
