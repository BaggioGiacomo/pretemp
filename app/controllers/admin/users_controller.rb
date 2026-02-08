class Admin::UsersController < AdminController
  def generate_password_reset
    @user = User.find(params[:id])
    token = @user.generate_token_for(:password_reset)
    @reset_url = edit_admin_password_reset_url(token: token)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_invitations_path, notice: "Password reset link generated!" }
    end
  end
end
