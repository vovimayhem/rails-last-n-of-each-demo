class Customer < ApplicationRecord
  has_many :payments, inverse_of: :customer
end
