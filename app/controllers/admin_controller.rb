class AdminController < ApplicationController
  layout "admin"
  before_action :require_admin

  private

    def require_admin
      puts "Current user: #{current_user}"
      unless current_user
        redirect_to admin_login_path, alert: "You must be logged in as an admin."
      end
    end
end
