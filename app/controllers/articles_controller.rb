class ArticlesController < ApplicationController
  before_action :set_article, only: :show

  def index
    @articles = Article.published.ordered
  end

  def show
  end

  private

    def set_article
      @article = Article.published.find(params[:id])
    end
end
