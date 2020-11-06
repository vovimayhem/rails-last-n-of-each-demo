class CreatePayments < ActiveRecord::Migration[6.0]
  def change
    create_table :payments do |t|
      t.references :customer, null: false, foreign_key: true
      t.decimal :amount, precision: 8, scale: 2

      t.datetime :created_at, null: false
    end

    # Index used to group or separate data by customer and creation timestamp:
    add_index :payments, %i[customer_id created_at]
  end
end
