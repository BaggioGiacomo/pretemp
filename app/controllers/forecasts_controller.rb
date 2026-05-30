class ForecastsController < ApplicationController
  before_action :set_forecast, only: %i[show]

  def index
    @forecasts = Forecast.published.ordered
  end

  def show
    @active_update = @forecast.active_update
    unless @forecast.published? || @forecast.archived?
      redirect_to root_path, status: :not_found
    end
  end

  private

    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

    def forecast_params
      params.require(:forecast).permit(:date, :image, :summary, :short_text, :discussion)
    end
end
