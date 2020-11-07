class LastNPaymentsOfEachCustomer
  attr_reader :customers, :payment_count, :scope

  # TODO: Use metaprogramming to delegate unimplemented methods to @scope:
  delegate :[], :each, :to_a, :group_by, :includes, to: :scope

  def initialize(customers:, payment_count:)
    @customers = customers
    @payment_count = payment_count

    build_scope
  end

  private

  # Builds the 'row_number () OVER (...)' SQL fragment:
  def customer_payment_row_number
    Arel::Nodes::Over.new Arel::Nodes::NamedFunction.new('row_number', []),
                          payments_window
  end

  # Builds the '(PARTITION BY ... ORDER BY ...)' SQL fragment:
  def payments_window
    Arel::Nodes::Window.new.tap do |window|
      window.partition Payment.arel_table[:customer_id]
      window.order Payment.arel_table[:created_at].desc
    end
  end

  def customer_payments
    Payment.where 'customer_id IN (:ids)', ids: @customers.select(:id)
  end

  def partitioned_customer_payments
    customer_payments.select(
      Payment.arel_table[Arel.star],
      customer_payment_row_number.as('"customer_payment_row_number"')
    )    
  end

  def build_scope
    @scope = Payment
      .from(partitioned_customer_payments, :payments)
      .where('customer_payment_row_number <= :max_row', max_row: payment_count)
  end
end