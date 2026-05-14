class AiConnection < ApplicationRecord
  PROVIDERS = [
    "OpenAI",
    "Anthropic",
    "Ollama",
    "LM Studio",
    "OpenRouter"
  ].freeze

  has_many :ai_models, dependent: :destroy

  scope :active, -> { find_by(active: true) }

  validates :name, presence: true, uniqueness: true
  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :model, presence: true

  validates :api_key,
            presence: true,
            unless: :local_provider?

  before_save :deactivate_other_connections, if: :active?

  def self.active_connection
    find_by(active: true)
  end

  private

  def local_provider?
    provider.in?(["Ollama", "LM Studio"])
  end

  def deactivate_other_connections
    AiConnection.where.not(id: id).update_all(active: false)
  end

  def self.provider_options
    PROVIDERS
  end
end
