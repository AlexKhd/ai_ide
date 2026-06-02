class AppFoldersController < ApplicationController
  before_action :set_app_folder, only: %i[show edit update destroy]
  before_action :check_user_working_directory, only: %i[new create]

  def index
    @app_folders = current_user.admin? ? AppFolder.all : current_user.app_folders
  end

  def show; end

  def new
    @app_folder = current_user.app_folders.build
    @available_folders = current_user.available_folders
  end

  def create
    @app_folder = current_user.app_folders.build(app_folder_params)
    if @app_folder.save
      redirect_to app_folders_path, notice: "App Folder created."
    else
      @available_folders = current_user.available_folders
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

  # API endpoint for browsing working directory
  def browse_working_directory
    user = current_user

    unless user.working_directory.present? && File.directory?(user.working_directory)
      return render json: { error: "Working directory not set or not accessible" }, status: :bad_request
    end

    folders = user.available_folders.map { |dir|
      {
        name: File.basename(dir),
        path: File.basename(dir),  # Store relative path
        file_count: Dir.glob(File.join(dir, '**/*')).count { |f| File.file?(f) }
      }
    }

    render json: {
      working_directory: user.working_directory,
      folders: folders
    }
  end

  private

  def set_app_folder
    @app_folder = current_user.admin? ? AppFolder.find(params[:id]) : current_user.app_folders.find(params[:id])
  end

  def app_folder_params
    params.require(:app_folder).permit(:name, :path, :description, :language, :active)
  end

  def check_user_working_directory
    unless current_user.working_directory.present?
      redirect_to edit_user_path(current_user), alert: "Please set your working directory first"
    end
  end
end
