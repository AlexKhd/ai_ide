class AiMessage < ApplicationRecord
  belongs_to :ai_session
  has_many :ai_tool_calls, class_name: "AiToolCall", dependent: :destroy

  scope :ordered, -> { order(:id) }

  validates :role, presence: true, inclusion: { in: %w[system user assistant tool] }
end
