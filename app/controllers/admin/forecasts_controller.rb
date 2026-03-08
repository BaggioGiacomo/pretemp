class Admin::ForecastsController < AdminController
  before_action :set_forecast, only: [ :edit, :update, :destroy ]

  def index
    @forecasts = Forecast.ordered
  end

  def new
    @forecast = Forecast.new
  end

  def create
    @forecast = Forecast.new(forecast_params)

    if @forecast.save
      redirect_to admin_root_path, notice: "Previsione creata con successo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @forecast.update(forecast_params)
      redirect_to admin_root_path, notice: "Previsione aggiornata con successo."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @forecast.destroy
    redirect_to admin_root_path, notice: "Previsione eliminata con successo."
  end

  private

    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

    def forecast_params
      params.require(:forecast).permit(:date, :summary, :body, :image, :remove_image)
    end
end
