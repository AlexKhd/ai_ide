class UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[ edit update destroy ]

  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: "User created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # allow blank password
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update(user_params)
      redirect_to users_path, notice: "User updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: t('message.was_successfully_deleted') }
      format.json { head :no_content }
    end
  end

  private
    def set_user
      @user = User.find(params.expect(:id))
    end

    def user_params
      params.expect(user: [ :email_address, :nickname, :password, { role_ids: [] } ])
    end

    def require_admin!
      redirect_to root_path, alert: "Not authorized" unless current_user&.admin?
    end
end
