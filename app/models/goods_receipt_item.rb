class GoodsReceiptItem < ApplicationRecord
  belongs_to :goods_receipt
  belongs_to :purchase_order_item, optional: true

  validates :quantity_received, presence: true, numericality: { greater_than: 0 }
  validates :condition, inclusion: { in: %w[good damaged partial] }
end
