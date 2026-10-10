class Vserver < ApplicationRecord
  has_many :deployments, dependent: :destroy
end
