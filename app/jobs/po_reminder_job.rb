class PoReminderJob
  include Sidekiq::Job
  sidekiq_options queue: "low", retry: 3

  def perform
    PurchaseOrder.where(status: "sent")
                 .where("created_at < ?", 7.days.ago)
                 .find_each do |po|
      ActsAsTenant.with_tenant(po.tenant) do
        AuditLog.record(
          action: "po_overdue_reminder",
          auditable: po,
          user: nil,
          ip_address: nil,
          changes_data: { days_open: (Time.current - po.created_at).to_i / 86_400 }
        )
      end
    end
  end
end
