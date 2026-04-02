class Admin::ProfileController < AdminController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to edit_admin_profile_path, notice: "Profile updated successfully."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def remove_curriculum
    current_user.curriculum.purge
    redirect_to edit_admin_profile_path, notice: "Curriculum removed."
  end

  private

    def profile_params
      params.require(:user).permit(:first_name, :last_name, :profile_image, :curriculum, :description)
    end
end
