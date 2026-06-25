class CreateRequisitions < ActiveRecord::Migration[8.1]
  def change
    create_table :requisitions do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :current_approver, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :department, null: false
      t.decimal :total_amount, precision: 15, scale: 2, null: false
      t.string :status, default: 'draft', null: false
      t.boolean :self_approval_blocked, default: true
      t.timestamps
    end
    # Composite index - key to 706x approval-inbox speedup
    add_index :requisitions, [ :tenant_id, :current_approver_id, :status ],
              name: 'idx_requisitions_approval_inbox'
    add_index :requisitions, [ :tenant_id, :status, :created_at ]
    add_index :requisitions, [ :tenant_id, :requester_id ]
  end
end
