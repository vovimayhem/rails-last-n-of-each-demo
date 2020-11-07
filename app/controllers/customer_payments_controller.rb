class CustomerPaymentsController < ApplicationController
  def index
    # Get the customers we're going to get the payments for:
    @customers = Customer.all.limit(10)
    
    # Query the payments we'll display using our Query object:
    @displayed_customer_payments = LastNPaymentsOfEachCustomer.new(
      customers: @customers,
      payment_count: 5
    ).includes(:customer)
  end
end
