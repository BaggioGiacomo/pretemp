class ArchiveController < ApplicationController
  def index
  end

  def show
    @year = params[:year]
    @forecasts = Forecast.where("strftime('%Y', date) = ?", @year).ordered
  end
end
