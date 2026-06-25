class Requisition < ApplicationRecord
  include AASM
  include PgSearch::Model
  acts_as_tenant(:tenant)

  pg_search_scope :search_by_title,
                  against: :title,
                  using: { trigram: { threshold: 0.1 } }

  belongs_to :tenant
  belongs_to :requester, class_name: "User"
  belongs_to :current_approver, class_name: "User", optional: true
  has_many :requisition_items, dependent: :destroy
  has_many :approval_steps, dependent: :destroy
  has_one :purchase_order
  has_many :audit_logs, as: :auditable

  accepts_nested_attributes_for :requisition_items, allow_destroy: true

  validates :title, :department, :total_amount, presence: true
  validates :total_amount, numericality: { greater_than: 0 }

  aasm column: :status do
    state :draft, initial: true
    state :pending, :approved, :rejected, :cancelled, :ordered

    event :submit do
      transitions from: :draft, to: :pending, guard: :no_self_approval?
    end
    event :approve do
      transitions from: :pending, to: :approved
    end
    event :reject do
      transitions from: :pending, to: :rejected
    end
    event :cancel do
      transitions from: %i[draft pending], to: :cancelled
    end
    event :convert_to_order do
      transitions from: :approved, to: :ordered
    end
  end

  def no_self_approval?
    return true unless self_approval_blocked
    current_approver_id != requester_id
  end
end
