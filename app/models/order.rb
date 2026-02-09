class Order < ApplicationRecord
  enum :status, {
    paid: 0,
    shipped: 1,
    delivered: 2,
    cancelled: 3,
    pending: 4,
  }

  before_validation :normalize_fields

  validates :customer_id, presence: true, numericality: { only_integer: true, greater_than: 0 }

  validates :product_name, presence: true, length: { maximum: 255 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :status, presence: true

  private

  def normalize_fields
    self.product_name = product_name.to_s.strip
    self.customer_name = customer_name.to_s.strip.presence
    self.address = address.to_s.strip.presence
  end
end
