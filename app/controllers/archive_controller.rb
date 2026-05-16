class ArchiveController < ApplicationController
  def index
  end

  def show
    @year = params[:year]
    @date_from = parse_date(params[:date_from])
    @date_to   = parse_date(params[:date_to])
    @risk_level = params[:risk_level].presence

    forecasts = Forecast.where("strftime('%Y', date) = ?", @year).ordered
    forecasts = forecasts.where("date >= ?", @date_from) if @date_from
    forecasts = forecasts.where("date <= ?", @date_to) if @date_to
    forecasts = forecasts.where(risk_level: @risk_level) if @risk_level && Forecast.risk_levels.key?(@risk_level)

    @pagy, @forecasts = pagy(forecasts, limit: 15)
  end

  private

  def parse_date(value)
    return nil if value.blank?
    Date.parse(value)
  rescue ArgumentError, TypeError
    nil
  end
end
