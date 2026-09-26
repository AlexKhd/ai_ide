FactoryBot.define do
  factory :ai_session do
    association :user
    association :ai_connection
    association :ai_model
    active { true }
  end
end
