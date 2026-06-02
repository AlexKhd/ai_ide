FactoryBot.define do
  factory :user do
    email_address                   { "user@example.com" }
    nickname                        { rand(900..999) }
    password                        { 'admin123' }
    role                            { "user" }

    trait :admin do
      email_address                 { "admin@example.com" }
      nickname                      { "admin_#{rand(100..199)}" }
      password                      { 'admin123' }
      role                          { "admin" }
    end
  end
end
