class PurchaseOrder < ApplicationRecord
  include AASM
  acts_as_tenant(:tenant)

  belongs_to :tenant
  belongs_to :requisition, optional: true
  belongs_to :created_by, class_name: 'User'
  has_many :purchase_order_items, dependent: :destroy
  has_many :goods_receipts, dependent: :destroy
  has_many :invoices, dependent: :nullify
  has_many :audit_logs, as: :auditable

  accepts_nested_attributes_for :purchase_order_items, allow_destroy: true

  validates :vendor, :total_amount, presence: true
  validates :total_amount, numericality: { greater_than: 0 }
  validates :price_tolerance, :quantity_tolerance,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  aasm column: :status do
    state :draft, initial: true
    state :sent, :partial, :received, :closed

    event :send_to_vendor do
      transitions from: :draft, to: :sent
    end
    event :mark_partial do
      transitions from: :sent, to: :partial
    end
    event :mark_received do
      transitions from: %i[sent partial], to: :received
    end
    event :close do
      transitions from: :received, to: :closed
    end
  end

  def total_received_quantity
    goods_receipts.joins(:goods_receipt_items)
                  .sum('goods_receipt_items.quantity_received')
  end
end
