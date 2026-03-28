class Admin::SatelliteMonitoringsController < AdminController
  before_action :set_monitoring, only: [ :edit, :update, :destroy ]

  def index
    @monitorings = SatelliteMonitoring.ordered
  end

  def new
    @monitoring = SatelliteMonitoring.new
  end

  def create
    @monitoring = SatelliteMonitoring.new(monitoring_params)

    if @monitoring.save
      redirect_to admin_satellite_monitorings_path, notice: "Satellite monitoring created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @monitoring.update(monitoring_params)
      redirect_to admin_satellite_monitorings_path, notice: "Satellite monitoring updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monitoring.destroy
    redirect_to admin_satellite_monitorings_path, notice: "Satellite monitoring deleted."
  end

  private

    def set_monitoring
      @monitoring = SatelliteMonitoring.find(params[:id])
    end

    def monitoring_params
      params.require(:satellite_monitoring).permit(:name, :description, :url, :priority)
    end
end
