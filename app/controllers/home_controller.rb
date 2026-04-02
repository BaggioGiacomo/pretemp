class HomeController < ApplicationController
  def index
    @latest_forecasts = Forecast.order(created_at: :desc).limit(3)
    @latest_forecast = @latest_forecasts.first

    @latest_articles = Article.published.ordered.limit(3)
  end
end
