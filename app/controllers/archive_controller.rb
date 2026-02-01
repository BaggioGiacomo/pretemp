class ArchiveController < ApplicationController
  def index
  end

  def show
    @year = params[:year]
    @forecasts = []
  end
end
