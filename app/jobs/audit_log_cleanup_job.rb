class AuditLogCleanupJob
  include Sidekiq::Job
  sidekiq_options queue: "low", retry: 2

  RETENTION_DAYS = 365

  def perform
    cutoff = RETENTION_DAYS.days.ago
    deleted = AuditLog.where("created_at < ?", cutoff).delete_all
    Rails.logger.info "[AuditLogCleanupJob] Purged #{deleted} records older than #{RETENTION_DAYS} days"
  end
end
