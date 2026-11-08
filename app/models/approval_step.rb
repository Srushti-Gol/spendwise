class ApprovalStep < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :tenant
  belongs_to :requisition
  belongs_to :approver, class_name: 'User'

  STATUSES = %w[pending approved rejected skipped].freeze
  validates :status, inclusion: { in: STATUSES }
  validates :level, numericality: { only_integer: true, greater_than: 0 }

  scope :pending, -> { where(status: 'pending') }
  scope :ordered_by_level, -> { order(:level) }

  def approve!(comment: nil)
    update!(status: 'approved', comment: comment, decided_at: Time.current)
  end

  def reject!(comment: nil)
    update!(status: 'rejected', comment: comment, decided_at: Time.current)
  end
end
