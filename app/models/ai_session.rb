class AiSession < ApplicationRecord
  belongs_to :user
  belongs_to :ai_model
  belongs_to :ai_connection, optional: true
  has_many :ai_messages, -> { order(:created_at) }, class_name: "AiMessage", dependent: :destroy

  validates :user_id, presence: true
  validates :ai_model_id, presence: true
end
