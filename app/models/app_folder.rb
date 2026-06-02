class AppFolder < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :path, presence: true, uniqueness: { scope: :user_id }
  validates :language, presence: true,
            inclusion: { in: %w[ruby python javascript typescript java go rust c] }

  validate :folder_exists_in_user_working_directory

  scope :active, -> { where(active: true) }
  scope :by_language, ->(lang) { where(language: lang) }

  # Get the full absolute path
  def full_path
    File.join(user.working_directory, path) if user.working_directory && path
  end

  def accessible?
    full_path && File.directory?(full_path) && File.readable?(full_path)
  end

  def file_count
    return 0 unless accessible?
    Dir.glob(File.join(full_path, "**/*")).count { |f| File.file?(f) }
  end

  def code_files
    return [] unless accessible?

    extensions = language_extensions[language.to_sym] || []
    Dir.glob(File.join(full_path, "**/*")).select do |f|
      File.file?(f) && extensions.any? { |ext| f.end_with?(ext) }
    end
  end

  private

  def folder_exists_in_user_working_directory
    return if path.blank? || user.blank? || user.working_directory.blank?

    full = File.join(user.working_directory, path)

    unless File.directory?(full)
      errors.add(:path, "folder does not exist in working directory")
    end

    unless File.readable?(full)
      errors.add(:path, "folder is not readable")
    end
  end

  def language_extensions
    {
      ruby: ['.rb', '.erb'],
      python: ['.py'],
      javascript: ['.js', '.jsx'],
      typescript: ['.ts', '.tsx'],
      java: ['.java'],
      go: ['.go'],
      rust: ['.rs'],
      c: ['.c', '.h']
    }
  end
end
