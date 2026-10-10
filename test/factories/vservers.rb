FactoryBot.define do
  factory :vserver do
    name                          { "an VPS" }
    host                          { "http://127.0.0.1" }
    healthcheck                   { "/up" }
    port                          { 1 }
    username                      { "user" }
    local_path                    { "/path" }
    enabled                       { true }
  end
end
