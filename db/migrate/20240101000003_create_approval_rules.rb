class CreateApprovalRules < ActiveRecord::Migration[8.1]
  def change
    create_table :approval_rules do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :department
      t.decimal :min_amount, precision: 15, scale: 2, default: 0
      t.decimal :max_amount, precision: 15, scale: 2
      t.string :approver_role, null: false
      t.integer :level, null: false
      t.timestamps
    end
    add_index :approval_rules, [ :tenant_id, :department, :level ]
  end
end
