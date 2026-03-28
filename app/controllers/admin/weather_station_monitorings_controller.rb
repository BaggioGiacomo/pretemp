class Admin::WeatherStationMonitoringsController < AdminController
  before_action :set_monitoring, only: [ :edit, :update, :destroy ]

  def index
    @monitorings = WeatherStationMonitoring.ordered
  end

  def new
    @monitoring = WeatherStationMonitoring.new
  end

  def create
    @monitoring = WeatherStationMonitoring.new(monitoring_params)

    if @monitoring.save
      redirect_to admin_weather_station_monitorings_path, notice: "Weather station monitoring created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @monitoring.update(monitoring_params)
      redirect_to admin_weather_station_monitorings_path, notice: "Weather station monitoring updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monitoring.destroy
    redirect_to admin_weather_station_monitorings_path, notice: "Weather station monitoring deleted."
  end

  private

    def set_monitoring
      @monitoring = WeatherStationMonitoring.find(params[:id])
    end

    def monitoring_params
      params.require(:weather_station_monitoring).permit(:name, :description, :url, :priority)
    end
end
