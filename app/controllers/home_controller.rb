class HomeController < ApplicationController
  def index
    @latest_forecasts = Forecast.order(date: :desc).limit(3)
    @latest_forecast = Forecast.today || @latest_forecasts.first
    @active_update = @latest_forecast&.active_update
    @recent_active_updates = ForecastUpdate.where(status: "published").where("valid_until > ?", Time.current).ordered.limit(3)

    @latest_articles = Article.published.ordered.limit(3)
  end
end
