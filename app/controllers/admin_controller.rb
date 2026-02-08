class AdminController < ApplicationController
  include Authentication

  layout "admin"
  before_action :require_admin

  private

    def require_admin
      unless current_user
        redirect_to admin_login_path, alert: "You must be logged in as an admin."
      end
    end
end
