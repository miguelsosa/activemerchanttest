# http://www.rubydoc.info/gems/activemerchant/ActiveMerchant/Billing/AuthorizeNetCimGateway
# ActiveMerchant::Billing::Base.mode = :test
# 

class AuthnetService
  def self.gateway
    @gateway ||= ActiveMerchant::Billing::AuthorizeNetCimGateway.new(
      login: ENV['HLS_AUTHNET_API_LOGIN_ID'],
      password: ENV['HLS_AUTHNET_API_TXN_KEY_ID'],
      test: (ENV['HLS_AUTHNET_GATEWAY'] == 'sandbox'))
  end
  
  def self.avsonly(cardnumber, expdate, cvv)
    # :auth_only => 'profileTransAuthOnly',
  end

  def self.sale(customer_profile, payment_profile, amount)
    gateway.create_customer_profile_transaction(transaction: {
                                                  type: :auth_capture,
                                                  amount: amount, # as decimal
                                                  customer_profile_id: customer_profile
                                                  customer_payment_profile_id: payment_profile
                                                  # card_code: cvv optional - if passed
                                                })

    
    
  end
  
  def self.return_by_amount(payment_profile, amount)
    :refund => 'profileTransRefund',
  end
  
  def self.return(payment_profile, transaction_id)
    :refund => 'profileTransRefund',
  end
  
  def self.void(transaction_id)
    :void => 'profileTransVoid'
  end

  # Create a profile without any payment profiles
  def self.create_profile(customer)
    gateway.create_customer_profile(profile: {
                                      email: customer.email,
                                      description: customer,
                                      merchant_customer_id: customer.id
                                    })
  end

  def self.add_card_to_profile(customer_profile_id, card_number, mm, yyyy, cvv)
    cc = ActiveMerchant::Billing::CreditCard.new(
      first_name: customer.first_name,
      last_name: customer.last_name,
      number: card_number,
      month: mm,
      year: yyyy,
      verification_value: cvv
    )
    ### pepepopo_profile.params['customer_profile_id']
    gateway.create_customer_payment_profile(
      customer_profile_id: customer_profile_id,
      payment_profile: { payment: { credit_card: cc }}
    )
  end
  
  def self.add_address_to_profile(customer_profile_id, card_number, cvv)
    :create_customer_shipping_address => 'createCustomerShippingAddress',
  end
end
