json.extract! order, :id, :customer_id, :amount_in_cents, :description, :created_at, :updated_at
json.url order_url(order, format: :json)