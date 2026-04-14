class PurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order
  has_many :goods_receipt_items, dependent: :destroy

  validates :description, :quantity, :unit_price, :total_price, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  before_save :calculate_total_price

  def received_quantity
    goods_receipt_items.sum(:quantity_received)
  end

  def outstanding_quantity
    quantity - received_quantity
  end

  private

  def calculate_total_price
    self.total_price = quantity * unit_price if quantity && unit_price
  end
end
