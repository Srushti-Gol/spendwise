class GoodsReceiptItem < ApplicationRecord
  belongs_to :goods_receipt
  belongs_to :purchase_order_item

  validates :quantity_received, numericality: { greater_than: 0 }
  validates :condition, inclusion: { in: %w[good damaged partial] }
end
