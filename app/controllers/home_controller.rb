class HomeController < ApplicationController
  def index
    @latest_forecasts = Forecast.published.order(date: :desc).limit(3)
    @latest_forecast = Forecast.tomorrow || Forecast.today || Forecast.published_tendenze.order(date: :desc).first || @latest_forecasts.first
    @today_forecast = Forecast.today

    @active_update = @latest_forecast&.active_update
    @recent_active_updates = ForecastUpdate.where(status: "published").where("valid_until > ?", Time.current).ordered.limit(3)

    # Banner: is there a published tendenza for the day after tomorrow?
    @tendenza_banner = Forecast.published_tendenze.find_by(date: Date.current + 2)
    # Banner: is there a currently active update to highlight?
    @update_banner = @recent_active_updates.first

    @latest_articles = Article.published.ordered.limit(3)
  end
end
