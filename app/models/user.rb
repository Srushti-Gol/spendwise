class User < ApplicationRecord
  has_secure_password
  acts_as_tenant(:tenant)

  belongs_to :tenant
  has_many :requisitions, foreign_key: :requester_id, dependent: :nullify
  has_many :approval_steps, foreign_key: :approver_id, dependent: :nullify
  has_many :audit_logs, dependent: :nullify

  ROLES = %w[staff manager finance director admin].freeze
  validates :role, inclusion: { in: ROLES }
  validates :name, :email, presence: true
  validates :email, uniqueness: { scope: :tenant_id }
  validates :jti, presence: true, uniqueness: true

  before_validation :set_jti, on: :create

  scope :approvers, -> { where(role: %w[manager finance director admin]) }

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
