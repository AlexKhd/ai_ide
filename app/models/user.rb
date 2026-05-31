class User < ApplicationRecord
  has_secure_password

  enum :role,
       {
         user: "user",
         admin: "admin"
       },
       validate: true

  has_many :sessions, dependent: :destroy
  has_many :app_folders, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
