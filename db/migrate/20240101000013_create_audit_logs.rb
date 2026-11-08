class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.jsonb :changes_data, default: {}
      t.jsonb :metadata, default: {}
      t.string :ip_address
      t.timestamps
    end
    # Optimized indexes for sub-ms audit-log page loads
    add_index :audit_logs, %i[tenant_id created_at]
    add_index :audit_logs, %i[tenant_id auditable_type auditable_id],
              name: 'idx_audit_logs_auditable'
    add_index :audit_logs, %i[tenant_id user_id created_at],
              name: 'idx_audit_logs_user_timeline'
  end
end
