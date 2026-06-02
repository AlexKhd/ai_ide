FactoryBot.define do
  factory :ai_model do
    external_id                             { "model_external_id" }
    name                                    { "connection name" }
    provider                                { 'OpenAI' }
    context_length                          { 999999 }
    input_modalities                        { ["text", "image", "file"] }
    output_modalities                       { ["text"] }
    supports_tools                          {}
    supports_reasoning                      {}
    prompt_price                            { 0 }
    completion_price                        { 0 }
    architecture                            {}
    raw                                     {}
    active                                  { true }
  end
end
