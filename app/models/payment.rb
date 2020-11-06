class Payment < ApplicationRecord
  belongs_to :customer, inverse_of: :payments
end
