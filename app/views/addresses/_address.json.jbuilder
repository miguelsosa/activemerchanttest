json.extract! address, :id, :customer_id, :street, :city, :state, :zip, :created_at, :updated_at
json.url address_url(address, format: :json)