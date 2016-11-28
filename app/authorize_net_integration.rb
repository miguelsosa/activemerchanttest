# TRANSACTIONS:
#    /Users/miguelsosa/src/vendor/authnet-sdk-ruby//lib/authorize_net/api/transaction.rb
#
##############
# Of interest:
# See spec/api_spec.rb for usage examples
##############
# CUSTOMER PROFILES
#    def create_customer_profile(request)
#    def get_customer_profile(request)
#    def update_customer_profile(request)
#    def delete_customer_profile(request)
#
# CUSTOMER PAYMENT PROFILE
#    def create_customer_payment_profile(request)
#    def get_customer_payment_profile(request)
#    def update_customer_payment_profile(request)
#    def delete_customer_payment_profile(request)
#
# SHIPPING PROFILE
#    def create_customer_shipping_profile(request)
# ...
#
# This request enables you to create a customer profile, payment profile,
# and shipping profile from an existing successful transaction.
# NOTE: Tokenized transactions (e.g. Apple Pay), or PayPal should not be used to
# create payment profiles.
# 
#    def create_customer_profile_from_transaction(request)
#
########
#    def get_customer_payment_profile_list(request)
#    def validate_customer_payment_profile(request)  

# Use this class to join the functionality for communicating with
# authorize.net

#require 'yaml'
#require 'authorizenet'
require 'securerandom'
class AuthorizeNetIntegration
  include AuthorizeNet::API

  def self.new_transaction
    Transaction.new(ENV["HLS_AUTHNET_API_LOGIN_ID"],
                    ENV["HLS_AUTHNET_API_TXN_KEY_ID"],
                    gateway: ENV["HLS_AUTHNET_GATEWAY"].to_sym)
  end

  def self.avsonly(customer_profile_id, card_profile_id, shipping_address_id, cvv)
    request = validateCustomerPaymentProfileRequest
    request.customerProfileId
    request.customerPaymentProfileId
    # TBD - can't find an avs only transaction
    #    --- auth only with amount 0
  end

  def self.get_profile(profile_id)
    transaction = new_transaction
    request = GetCustomerProfileRequest.new
    #request.refId = (this is a sequence counter for matching request and responses)
    request.customerProfileId = profile_id
    request.unmaskExpirationDate = true

    response = transaction.get_customer_profile(request)

    if response.messages.resultCode == MessageTypeEnum::Ok

      cards = response.profile.paymentProfiles.collect { |pp|
        { card: pp.payment.creditCard, expdate: pp.payment.expirationDate }
      }

#      response.profile.paymentProfiles.each do |paymentProfile|
#        puts "Payment Profile ID #{paymentProfile.customerPaymentProfileId}"
#        puts "Payment Details:"
#
#        if paymentProfile.billTo != nil
#          puts "Last Name #{paymentProfile.billTo.lastName}"
#          puts "Address #{paymentProfile.billTo.address}"
#        end
#      end
#      response.profile.shipToList.each do |ship|
#        puts "Shipping Details:"
#        puts "First Name #{ship.firstName}"
#        puts "Last Name #{ship.lastName}"
#        puts "Address #{ship.address}"
#        puts "Customer Address ID #{ship.customerAddressId}"
#      end
#
#      if response.subscriptionIds != nil && response.subscriptionIds.subscriptionId != nil
#        puts "List of subscriptions : "
#        response.subscriptionIds.subscriptionId.each do |subscriptionId|
#          puts "#{subscriptionId}"
#        end
#      end

    else
      cards = []
      raise "Failed to get customer profile information with id #{request.customerProfileId}"
    end
    return response
  end

  def self.sale_with_profile(profile_id, payment_profile_id, amount, cvv = nil)

    transaction = new_transaction
    request = CreateTransactionRequest.new

    request.transactionRequest = TransactionRequestType.new()
    request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
    request.transactionRequest.amount = amount

    request.transactionRequest.profile = CustomerProfilePaymentType.new
    request.transactionRequest.profile.customerProfileId = profile_id
    request.transactionRequest.profile.paymentProfile = PaymentProfile.new(payment_profile_id)
    request.transactionRequest.profile.paymentProfile.cardCode=cvv if cvv
    # [order + other fields if we want]

    response = transaction.create_transaction(request)
    if response != nil
      if response.messages.resultCode == MessageTypeEnum::Ok
        if response.transactionResponse != nil && response.transactionResponse.messages != nil
          puts "Success, Auth Code : #{response.transactionResponse.authCode}"
          puts "Transaction Response code : #{response.transactionResponse.responseCode}"
          puts "Code : #{response.transactionResponse.messages.messages[0].code}"
		      puts "Description : #{response.transactionResponse.messages.messages[0].description}"
        else
          puts "Transaction Failed"
          if response.transactionResponse.errors != nil
            puts "Error Code : #{response.transactionResponse.errors.errors[0].errorCode}"
            puts "Error Message : #{response.transactionResponse.errors.errors[0].errorText}"
          end
          raise "Failed to charge customer profile."
        end
      else
        puts "Transaction Failed"
        if response.transactionResponse != nil && response.transactionResponse.errors != nil
          puts "Error Code : #{response.transactionResponse.errors.errors[0].errorCode}"
          puts "Error Message : #{response.transactionResponse.errors.errors[0].errorText}"
        else
          puts "Error Code : #{response.messages.messages[0].code}"
          puts "Error Message : #{response.messages.messages[0].text}"
        end
        raise "Failed to charge customer profile."
      end
    else
      puts "Response is null"
      raise "Failed to charge customer profile."
    end

    return response
  end

  # '4111111111111111','2020-05'
  def self.create_customer_profile()
  end

  def self.add_card(customer, card_number, expdate, cvv)
    # get a token
    # Create transactions for token
    # Create model to store tokens
    # on read, returns ID + last 4
    # Question: Do we need to return 'expired'?
    #
    transaction = new_transaction

    # Create profile if it doesn't exist, otherwise create payment profile
    request = if customer.has_authnet_profile
                CreateCustomerPaymentProfile()
                request.customerProfileId = customer.authnet_profile
              else
                CreateCustomerProfileRequest.new
              end

    # merchantAuthentication = nil, refId = nil, profile = nil, validationMode = nil)
    
    payment = PaymentType.new(CreditCardType.new(card_number, expdate, cvv))
    # creditCard = nil, bankAccount = nil, trackData = nil, encryptedTrackData = nil, payPal = nil, opaqueData = nil, emv = nil

    # XXX
    billing_addr = if customer.addresses.billing.present?
                      customer.addresses.billing.first
                   else
                     customer.addresses.default.first
                   end
    address = CustomerAddressType.new(customer.first_name, customer.last_name, customer.company.name, billing_addr.address1, billing_addr.city, billing_addr.province, billing_addr.zip, billing_addr.country, billing_addr.phone, nil)

    # def initialize(firstName = nil, lastName = nil, company = nil,
    # address = nil, city = nil, state = nil, zip = nil, country =
    # nil, phone, faxNumber
    
    profile = CustomerPaymentProfileType.new(:business,address,payment,nil,nil)
    # :customerType
    #   individual or business
    # :billTo, :as => CustomerAddressType
    #   Customer information. 
    # :payment, :as => PaymentType
    #   Contains payment information for the customer profile.
    #   Can contain CreditCardSimpleType or BankAccountType.
    # :driversLicense, :as => DriversLicenseType
    # :taxId
    
    # XXX
    request.profile = CustomerProfileType.new(customer.id, customer.display_name, customer.email, [profile], nil)
    # :merchantCustomerId
    #    Merchant assigned ID for the customer.
    # :description
    #    Description of the customer profile
    # :email
    #    Email associated with the profile
    # :paymentProfiles, :from => 'paymentProfiles', :as => [CustomerPaymentProfileType]
    #    Multiple instances of this element can be submitted to create
    #    multiple payment profiles for the customer profile.
    # :shipToList, :from => 'shipToList', :as => [CustomerAddressType]
    #    Contains shipping address information for the customer profile.
    #    TODO: Why would this be needed?
    response = transaction.create_customer_profile(request)

    # validationMode : none, test, live (test does luhn check, live goes to bank) - passes $0.00 auth
    request.validationMode  = :live

    # The element 'paymentProfiles' in namespace 'AnetApi/xml/v1/schema/AnetApiSchema.xsd'
    #
    # cannot contain text. List of possible elements expected:
    #
    # customerType, billTo, payment, driversLicense, taxId,
    # defaultPaymentProfile
    #
    # in namespace 'AnetApi/xml/v1/schema/AnetApiSchema.xsd'.

    if response.messages.resultCode == MessageTypeEnum::Ok
      puts "Successfully created aX customer profile with id:  #{response.customerProfileId}"
      puts "Customer Payment Profile Id List:"
      response.customerPaymentProfileIdList.numericString.each do |id|
        # TODO STORE ID INTO MODEL:
        #    BigInt
        #    customer.id
        #    last4
        # 
        puts id
      end
      puts "Customer Shipping Address Id List:"
      response.customerShippingAddressIdList.numericString.each do |id|
        puts id
      end
    else
      puts response.messages.messages[0].text
      raise "Failed to create a new customer profile."
    end
    return response
  end
end
