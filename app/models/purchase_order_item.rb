class PurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order

  validates :description, :quantity, :unit_price, :total_price, presence: true
  validates :quantity, :unit_price, numericality: { greater_than: 0 }
  validates :received_quantity, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total

  def fully_received?
    received_quantity >= quantity
  end

  private

  def calculate_total
    self.total_price = quantity * unit_price if quantity && unit_price
  end
end
