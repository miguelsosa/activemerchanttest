json.extract! card, :id, :customer_id, :last4, :profile_id, :created_at, :updated_at
json.url card_url(card, format: :json)