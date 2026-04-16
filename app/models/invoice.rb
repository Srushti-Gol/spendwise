class Invoice < ApplicationRecord
  include AASM
  acts_as_tenant(:tenant)

  belongs_to :tenant
  belongs_to :purchase_order, optional: true
  belongs_to :created_by, class_name: 'User'
  has_many :invoice_items, dependent: :destroy
  has_many :audit_logs, as: :auditable

  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  validates :vendor, :total_amount, presence: true
  validates :total_amount, numericality: { greater_than: 0 }

  aasm column: :status do
    state :pending, initial: true
    state :processing, :matched, :exception, :approved, :paid

    event :start_processing do
      transitions from: :pending, to: :processing
    end
    event :mark_matched do
      transitions from: :processing, to: :matched
    end
    event :flag_exception do
      transitions from: :processing, to: :exception
    end
    event :approve_payment do
      transitions from: :matched, to: :approved
    end
    event :mark_paid do
      transitions from: :approved, to: :paid
    end
  end

  def matched?
    price_match? && quantity_match? && vendor_match? && !is_duplicate?
  end

  def exceptions
    match_result['exceptions'] || []
  end
end
