class Admin::SessionsController < AdminController
  layout "admin_auth"

  before_action :redirect_if_authenticated, only: [ :new, :create ]

  skip_before_action :require_admin, only: [ :new, :create ]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email])

    if user&.authenticate(params[:password])
      start_new_session_for(user)
      redirect_to admin_root_path, notice: "Welcome back!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to admin_login_path, notice: "You've been logged out."
  end

  private

    def redirect_if_authenticated
      puts "Current user: #{current_user.inspect}"
      redirect_to admin_root_path if current_user
    end
end
