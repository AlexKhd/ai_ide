class AppFolder < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :path, presence: true, uniqueness: { scope: :user_id }
  # validates :language, presence: true,
  #          inclusion: { in: %w[ruby python javascript typescript java go rust c],
  #                      message: "%{value} is not a valid language" }

  scope :active, -> { where(active: true) }
  scope :by_language, ->(lang) { where(language: lang) }

  def accessible?
    File.directory?(path) && File.readable?(path)
  end

  def file_count
    Dir.glob(File.join(path, "**/*")).count { |f| File.file?(f) }
  end

  def code_files
    extensions = language_extensions[language.to_sym] || []
    Dir.glob(File.join(path, "**/*")).select do |f|
      File.file?(f) && extensions.any? { |ext| f.end_with?(ext) }
    end
  end

  private

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
