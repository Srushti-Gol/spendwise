class ApprovalRule < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :tenant
  belongs_to :approver, class_name: 'User'

  validates :department, :min_amount, :step_order, presence: true
  validates :min_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :step_order, numericality: { only_integer: true, greater_than: 0 }

  scope :for_department, ->(dept) { where(department: [dept, 'ALL']).order(:step_order) }
  scope :applicable_to_amount, ->(amount) { where('min_amount <= ?', amount) }
end
