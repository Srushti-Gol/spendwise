class CreateApprovalSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :approval_steps do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :requisition, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.integer :level, null: false
      t.string :status, default: 'pending', null: false
      t.text :comment
      t.datetime :decided_at
      t.timestamps
    end
    add_index :approval_steps, [:tenant_id, :approver_id, :status]
    add_index :approval_steps, [:requisition_id, :level]
    # Partial index — only index pending steps (huge win at scale)
    add_index :approval_steps, [:tenant_id, :status],
              where: "status = 'pending'",
              name: 'idx_approval_steps_pending'
  end
end
