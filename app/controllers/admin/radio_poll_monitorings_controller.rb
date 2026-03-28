class Admin::RadioPollMonitoringsController < AdminController
  before_action :set_monitoring, only: [ :edit, :update, :destroy ]

  def index
    @monitorings = RadioPollMonitoring.ordered
  end

  def new
    @monitoring = RadioPollMonitoring.new
  end

  def create
    @monitoring = RadioPollMonitoring.new(monitoring_params)

    if @monitoring.save
      redirect_to admin_radio_poll_monitorings_path, notice: "Radio poll monitoring created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @monitoring.update(monitoring_params)
      redirect_to admin_radio_poll_monitorings_path, notice: "Radio poll monitoring updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monitoring.destroy
    redirect_to admin_radio_poll_monitorings_path, notice: "Radio poll monitoring deleted."
  end

  private

    def set_monitoring
      @monitoring = RadioPollMonitoring.find(params[:id])
    end

    def monitoring_params
      params.require(:radio_poll_monitoring).permit(:name, :description, :url, :priority)
    end
end
