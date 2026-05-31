class AppFoldersController < ApplicationController
  before_action :set_app_folder, only: %i[show edit update destroy]

  def index
    @app_folders = current_user.admin? ? AppFolder.all : current_user.app_folders
  end

  def show; end

  def new
    @app_folder = current_user.app_folders.build
  end

  def create
    @app_folder = current_user.app_folders.build(app_folder_params)
    if @app_folder.save
      redirect_to app_folders_path, notice: "App Folder created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @app_folder.update(app_folder_params)
      redirect_to app_folders_path, notice: "App Folder updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @app_folder.destroy
    redirect_to app_folders_path, notice: "App Folder deleted."
  end

  private

  def set_app_folder
    @app_folder = current_user.admin? ? AppFolder.find(params[:id]) : current_user.app_folders.find(params[:id])
  end

  def app_folder_params
    params.require(:app_folder).permit(:name, :path, :description, :language, :active)
  end
end
