class ForecastsController < ApplicationController
  before_action :set_forecast, only: %i[show]

  def index
    @forecasts = Forecast.ordered
  end

  def show
  end

  private

    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

    def forecast_params
      params.require(:forecast).permit(:date, :image, :summary, :body)
    end
end
