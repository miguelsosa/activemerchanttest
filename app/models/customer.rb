class Customer < ApplicationRecord
  has_many :addresses, dependent: :destroy
  has_many :cards, dependent: :destroy
  has_many :orders, dependent: :destroy

  def display_name
    "#{first_name} #{last_name}"
  end

  def to_s
    "#{display_name} <#{email}> - #{company}"
  end
end
