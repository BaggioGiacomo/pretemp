class Admin::RadarMonitoringsController < AdminController
  before_action :set_monitoring, only: [ :edit, :update, :destroy ]

  def index
    @monitorings = RadarMonitoring.ordered
  end

  def new
    @monitoring = RadarMonitoring.new
  end

  def create
    @monitoring = RadarMonitoring.new(monitoring_params)

    if @monitoring.save
      redirect_to admin_radar_monitorings_path, notice: "Radar monitoring created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @monitoring.update(monitoring_params)
      redirect_to admin_radar_monitorings_path, notice: "Radar monitoring updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monitoring.destroy
    redirect_to admin_radar_monitorings_path, notice: "Radar monitoring deleted."
  end

  private

    def set_monitoring
      @monitoring = RadarMonitoring.find(params[:id])
    end

    def monitoring_params
      params.require(:radar_monitoring).permit(:name, :description, :url, :priority)
    end
end
