# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

sample_data = Rails.root.join('db', 'sample_data')

Customer.transaction do
  Customer.connection.execute File.read(sample_data.join('customers.sql'))
end unless Customer.any?

Payment.transaction do
  Payment.connection.execute File.read(sample_data.join('payments.sql'))
end unless Payment.any?
