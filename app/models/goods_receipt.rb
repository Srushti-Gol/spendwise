class GoodsReceipt < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :tenant
  belongs_to :purchase_order
  belongs_to :received_by, class_name: 'User'
  has_many :goods_receipt_items, dependent: :destroy
  has_many :audit_logs, as: :auditable

  accepts_nested_attributes_for :goods_receipt_items, allow_destroy: true

  validates :received_at, presence: true

  after_create :update_purchase_order_status

  private

  def update_purchase_order_status
    po = purchase_order
    total_ordered = po.purchase_order_items.sum(:quantity)
    total_received = po.total_received_quantity

    if total_received >= total_ordered
      po.mark_received! if po.may_mark_received?
    elsif total_received > 0
      po.mark_partial! if po.may_mark_partial?
    end
  end
end
