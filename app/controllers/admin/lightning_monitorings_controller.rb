class Admin::LightningMonitoringsController < AdminController
  before_action :set_monitoring, only: [ :edit, :update, :destroy ]

  def index
    @monitorings = LightningMonitoring.ordered
  end

  def new
    @monitoring = LightningMonitoring.new
  end

  def create
    @monitoring = LightningMonitoring.new(monitoring_params)

    if @monitoring.save
      redirect_to admin_lightning_monitorings_path, notice: "Lightning monitoring created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @monitoring.update(monitoring_params)
      redirect_to admin_lightning_monitorings_path, notice: "Lightning monitoring updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monitoring.destroy
    redirect_to admin_lightning_monitorings_path, notice: "Lightning monitoring deleted."
  end

  private

    def set_monitoring
      @monitoring = LightningMonitoring.find(params[:id])
    end

    def monitoring_params
      params.require(:lightning_monitoring).permit(:name, :description, :url, :priority)
    end
end
