class GoodsReceipt < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :tenant
  belongs_to :purchase_order
  belongs_to :received_by, class_name: 'User'
  has_many :goods_receipt_items, dependent: :destroy

  accepts_nested_attributes_for :goods_receipt_items

  validates :received_at, presence: true

  after_create :update_po_received_quantities

  private

  def update_po_received_quantities
    goods_receipt_items.each do |item|
      next unless item.purchase_order_item_id
      po_item = PurchaseOrderItem.find(item.purchase_order_item_id)
      po_item.increment!(:received_quantity, item.quantity_received)
    end

    total_ordered = purchase_order.purchase_order_items.sum(:quantity)
    total_received = purchase_order.purchase_order_items.sum(:received_quantity)

    if total_received >= total_ordered
      purchase_order.mark_received! rescue nil
    elsif total_received > 0
      purchase_order.mark_partial! rescue nil
    end
  end
end
