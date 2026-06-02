class User < ApplicationRecord
  has_secure_password

  enum :role,
       {
         user: "user",
         admin: "admin"
       },
       validate: true

  has_many :sessions, dependent: :destroy
  has_many :app_folders, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :working_directory, presence: true, on: :update
  validate :working_directory_exists_and_readable, on: :update

  # Get full path for app folder
  def full_path_for(app_folder)
    File.join(working_directory, app_folder.path) if working_directory && app_folder.path
  end

  # List available folders in working directory
  def available_folders
    return [] unless working_directory && File.directory?(working_directory)

    Dir.entries(working_directory)
      .reject { |entry| entry.start_with?('.') }
      .map { |entry| File.join(working_directory, entry) }
      .select { |entry| File.directory?(entry) }
      .sort
  end

  private

  def working_directory_exists_and_readable
    return if working_directory.blank?

    expanded_path = File.expand_path(working_directory)

    unless File.directory?(expanded_path)
      errors.add(:working_directory, "does not exist")
    end

    unless File.readable?(expanded_path)
      errors.add(:working_directory, "is not readable")
    end
  end
end
