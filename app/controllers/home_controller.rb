class HomeController < ApplicationController
  def index
    @latest_forecast = Forecast.order(created_at: :desc).first
  end
end
