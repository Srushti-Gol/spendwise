class AuditLog < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :tenant
  belongs_to :user
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true

  # Append-only: prevent any updates or deletes
  before_update { raise ActiveRecord::ReadOnlyRecord, 'AuditLog is append-only' }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, 'AuditLog is append-only' }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_resource, ->(type, id) { where(auditable_type: type, auditable_id: id) }

  def self.record(user:, action:, record: nil, changes: {}, metadata: {}, ip: nil)
    create!(
      tenant: ActsAsTenant.current_tenant,
      user: user,
      action: action,
      auditable: record,
      changes_data: changes,
      metadata: metadata,
      ip_address: ip
    )
  end
end
