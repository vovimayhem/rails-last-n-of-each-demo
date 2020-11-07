# Demo: "Last N of each" query with PostgreSQL and Rails ActiveRecord

## 1: Setup

With Docker and Docker Compose, just clone the project and run:

```bash
docker-compose up
```

The database will initialize with records. You can then visit 
[http://localhost:3000](http://localhost:3000) to see the query in action.

## 2: Developing the SQL query

I usually work out the query that I'll want to perform first, using a database IDE:

```sql
-- Step 1: Get the customers we’ll display:

SELECT * FROM "customers" LIMIT 10

-- Step 2: Use the last query as a subquery to filter the Payments:

SELECT * FROM "payments" WHERE "customer_id" IN (SELECT "id" FROM "customers" LIMIT 10)

-- Step 3: Add a "row number" for each row, but partitioned for each customer, and start from latest to earliest.
-- We'll use this column to filter the last N of each in the following step:
SELECT
  "payments".*,
  row_number () OVER ( 
      PARTITION BY "customer_id"
      ORDER BY "created_at" DESC
  ) "payment_row_number"
FROM "payments"
WHERE "customer_id" IN (SELECT "id" FROM "customers" LIMIT 10)

-- Step 4: Use the last query as a subquery, and filter rows so only the last N rows for each customer make it
-- to the dataset:
SELECT * FROM (
  SELECT
    "payments".*,
    row_number () OVER ( 
        PARTITION BY "customer_id"
        ORDER BY "created_at" DESC
    ) "payment_row_number"
  FROM "payments"
  WHERE "customer_id" IN (SELECT "id" FROM "customers" LIMIT 10)
) "payments" WHERE "payment_row_number" <= 5
```

## 3: Developing the ActiveRecord query that generates the desired SQL query

Next, I'll work out the code required to generate the SQL query, using the rails
console.

Remember that ActiveRecord queries/scopes are only executed (evaluated) whenever
an iterator or inspection is called on it... so don't worry if some of these lines
execute queries inside the console. When run in the web app, it will just issue
the final query.

```ruby
# Step 1: The query/scope we'll use as the list of customers:
@customers = Customer.limit(10)

# Step 2: The query/scope we'll use to get ALL the payments from our list of customers:
@customer_payments = Payment.where('customer_id IN (:ids)', ids: @customers.select(:id))

# Step 3: Construct the SQL fragments we'll need using Arel:

# The '(PARTITION BY ... ORDER BY ...)' SQL fragment, which is the "window":
payment_window = Arel::Nodes::Window.new.tap do |window|
  window.partition  Payment.arel_table[:customer_id]
  window.order Payment.arel_table[:created_at]
end

# The 'row_number () OVER (...)' SQL fragment, which is the "window function":
customer_payment_row_number = Arel::Nodes::Over.new \
  Arel::Nodes::NamedFunction.new('row_number', []),
  payment_window

# Step 4: The query that will bring the payments along with the partitioned 
# row numbers:
@partitioned_customer_payments = @customer_payments.select(
  Payment.arel_table[Arel.star],
  customer_payment_row_number.as('"customer_payment_row_number"')
)

# Step 5: The final query where we get the last 5 payments of each customer:
@last_five_payments_of_each_customer = Payment
  .from(@partitioned_customer_payments, :payments)
  .where('customer_payment_row_number <= :max_row', max_row: 5)
```

## 4: The "LastNPaymentsOfEachCustomer" Query Object

I tidy up the query logic into a "Query Object" class. If you haven't checked
[this old article](https://codeclimate.com/blog/7-ways-to-decompose-fat-activerecord-models/) yet,
I truly recommend you to check it out!

See [the `LastNPaymentsOfEachCustomer` class code](app/queries/last_n_payments_of_each_customer.rb)
to see how it looks like.

Then, see [the `CustomerPaymentsController` code](app/controllers/customer_payments_controller.rb)
to see how it's used.