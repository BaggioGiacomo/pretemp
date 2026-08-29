class HomeController < ApplicationController
  def index
    @latest_forecasts = Forecast.published.ordered.limit(3)
    # The hero always highlights a previsione: tendenze are announced by their
    # own banner above, so they never take over the main card.
    @latest_forecast = Forecast.featured_previsione
    @today_forecast = Forecast.previsione_for(Date.current)

    @active_update = @latest_forecast&.active_update
    @recent_active_updates = ForecastUpdate.active.ordered.limit(3)

    # Banner: is there a published tendenza still ahead of us?
    @tendenza_banner = Forecast.upcoming_tendenza
    # Banner: is there a currently active update to highlight?
    @update_banner = @recent_active_updates.first

    @latest_articles = Article.published.ordered.limit(3)
  end
end
