class AiModel < ApplicationRecord
  scope :zero_cost, -> { where(prompt_price: 0, completion_price: 0) }
  scope :ordered, -> { order(:name) }
  scope :ordered_ext_id, -> { order(:external_id) }
  scope :active, -> { where(active: true) }
  scope :supports_tools, -> { where(supports_tools: true) }
  scope :supports_reasoning, -> { where(supports_reasoning: true) }

  has_many :ai_connections, foreign_key: :model_id, dependent: :nullify

  validates :external_id, presence: true, uniqueness: true

  def is_free?
    prompt_price == 0 && completion_price == 0
  end
end
