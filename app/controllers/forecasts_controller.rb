class ForecastsController < ApplicationController
  before_action :set_forecast, only: %i[show]

  def index
    @forecasts = Forecast.published.ordered
  end

  def show
    unless @forecast.published? || @forecast.archived?
      return redirect_to root_path, status: :not_found
    end

    # Newest first: the top one is the current picture, the ones below are kept
    # as history. Drafts never reach the public page.
    @forecast_updates = @forecast.forecast_updates.visible.ordered
                                 .includes(:users)
                                 .with_rich_text_short_text_and_embeds
                                 .with_rich_text_discussion_and_embeds
                                 .with_attached_image
  end

  private

    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

    def forecast_params
      params.require(:forecast).permit(:date, :image, :summary, :short_text, :discussion)
    end
end
