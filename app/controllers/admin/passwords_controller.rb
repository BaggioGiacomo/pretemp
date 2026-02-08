class Admin::PasswordsController < AdminController
  layout "admin_auth"

  before_action :set_user_by_token, only: [ :edit, :update ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to admin_login_path, notice: "If an account exists, you'll receive a password reset email."
  end

  def edit
  end

  def update
    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to admin_login_path, notice: "Your password has been reset. Please log in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_admin_password_path, alert: "Invalid or expired reset link."
    end
end
