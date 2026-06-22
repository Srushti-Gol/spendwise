class ApprovalRule < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :tenant

  ROLES = %w[manager finance director admin].freeze
  validates :approver_role, inclusion: { in: ROLES }
  validates :level, :min_amount, presence: true
  validates :level, numericality: { only_integer: true, greater_than: 0 }
  validates :min_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:level) }
  scope :for_amount, ->(amount) {
    where('min_amount <= ?', amount)
      .where('max_amount IS NULL OR max_amount >= ?', amount)
  }
end
