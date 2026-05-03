class ArchiveController < ApplicationController
  def index
  end

  def show
    @year = params[:year]
    forecasts = Forecast.where("strftime('%Y', date) = ?", @year).ordered
    @pagy, @forecasts = pagy(forecasts, limit: 30)
  end
end
