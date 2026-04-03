class ApprovalRule < ApplicationRecord
  acts_as_tenant(:tenant)
  belongs_to :tenant

  validates :approver_role, :level, presence: true
  validates :level, numericality: { only_integer: true, greater_than: 0 }

  scope :for_amount, ->(amount) {
    where('min_amount <= ? AND (max_amount IS NULL OR max_amount >= ?)', amount, amount)
  }
  scope :for_department, ->(dept) {
    where('department IS NULL OR department = ?', dept)
  }
end
