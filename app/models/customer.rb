class Customer < ApplicationRecord
  has_many :payments, inverse_of: :customer

  def full_name
    "#{first_name} #{last_name}"
  end
end
