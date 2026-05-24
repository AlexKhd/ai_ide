class AiModel < ApplicationRecord
  scope :zero_cost, -> { where(prompt_price: 0, completion_price: 0) }
  scope :ordered, -> { order(:name) }
  scope :ordered_ext_id, -> { order(:external_id) }

  belongs_to :ai_connection

  validates :external_id, uniqueness: { scope: :ai_connection_id }
end
