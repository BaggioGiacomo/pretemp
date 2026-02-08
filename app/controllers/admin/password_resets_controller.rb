class Admin::PasswordResetsController < ApplicationController
  layout "admin_auth"

  before_action :set_user_by_token

  def edit
    if @user.nil?
      redirect_to admin_login_path, alert: "Invalid or expired password reset link."
    end
  end

  def update
    if @user.nil?
      redirect_to admin_login_path, alert: "Invalid or expired password reset link."
      return
    end

    if params[:password].blank?
      flash.now[:alert] = "Password can't be blank"
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to admin_login_path, notice: "Password updated! Please log in."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
  end
end
