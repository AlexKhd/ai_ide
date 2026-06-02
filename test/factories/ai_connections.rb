FactoryBot.define do
  factory :ai_connection do
    name                            { "connection name" }
    provider                        { "OpenAI" }
    api_key                         { 'api_key_xxxxxxxxx' }
    active                          { true }
    model_id                        { AiModel.first.id }
  end
end
