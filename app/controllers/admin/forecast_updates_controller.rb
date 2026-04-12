class Admin::ForecastUpdatesController < AdminController
  before_action :set_forecast
  before_action :set_forecast_update, only: [ :edit, :update, :destroy ]

  def index
    @forecast_updates = @forecast.forecast_updates.ordered
  end

  def new
    @forecast_update = @forecast.forecast_updates.build
    @forecast_update.user_ids = [ current_user.id ]
  end

  def create
    @forecast_update = @forecast.forecast_updates.build(forecast_update_params)

    if @forecast_update.save
      redirect_to admin_forecast_forecast_updates_path(@forecast), notice: "Aggiornamento creato con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @forecast_update.update(forecast_update_params)
      redirect_to admin_forecast_forecast_updates_path(@forecast), notice: "Aggiornamento aggiornato con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @forecast_update.destroy
    redirect_to admin_forecast_forecast_updates_path(@forecast), notice: "Aggiornamento eliminato con successo."
  end

  private

    def set_forecast
      @forecast = Forecast.find(params[:forecast_id])
    end

    def set_forecast_update
      @forecast_update = @forecast.forecast_updates.find(params[:id])
    end

    def forecast_update_params
      params.require(:forecast_update).permit(:body, :image, :status, :valid_until, :remove_image, user_ids: [])
    end
end
