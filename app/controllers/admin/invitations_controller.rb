class Admin::InvitationsController < AdminController
  layout "admin_auth", only: [ :edit, :update ]

  before_action :require_admin, only: [ :index, :new, :create, :destroy ]
  before_action :set_invitation_by_token, only: [ :edit, :update ]

  def index
    @invitations = Invitation.order(created_at: :desc)
  end

  def new
    @invitation = Invitation.new
  end

  def create
    @invitation = current_user.sent_invitations.build(invitation_params)

    if @invitation.save
      @invite_url = accept_admin_invitation_url(token: @invitation.token)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_invitations_path, notice: "Invitation created!" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @invitation = Invitation.find(params[:id])
    @invitation.destroy
    redirect_to admin_invitations_path, notice: "Invitation cancelled."
  end

  def edit
    if @invitation.nil?
      redirect_to admin_login_path, alert: "Invalid invitation link."
    elsif !@invitation.acceptable?
      redirect_to admin_login_path, alert: "This invitation has expired or was already used."
    end
  end

  def update
    if !@invitation.acceptable?
      redirect_to admin_login_path, alert: "This invitation has expired or was already used."
      return
    end

    @user = User.new(
      email_address: @invitation.email,
      password: params[:password],
      password_confirmation: params[:password_confirmation],
    )

    if @user.save
      @invitation.accept!
      start_new_session_for(@user)
      redirect_to admin_root_path, notice: "Welcome! Your admin account is ready."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def set_invitation_by_token
      @invitation = Invitation.find_by(token: params[:token])
    end

    def invitation_params
      params.require(:invitation).permit(:email)
    end
end
