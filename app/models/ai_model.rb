class AiModel < ApplicationRecord
  belongs_to :ai_connection

  validates :external_id, uniqueness: { scope: :ai_connection_id }
end
