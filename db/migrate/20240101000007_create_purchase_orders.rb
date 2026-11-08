class CreatePurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_orders do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :requisition, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :vendor, null: false
      t.string :vendor_email
      t.decimal :total_amount, precision: 15, scale: 2, null: false
      t.string :status, default: 'draft', null: false
      t.decimal :price_tolerance, precision: 5, scale: 4, default: 0.05
      t.decimal :quantity_tolerance, precision: 5, scale: 4, default: 0.02
      t.date :expected_delivery_date
      t.text :notes
      t.timestamps
    end
    add_index :purchase_orders, %i[tenant_id status]
    add_index :purchase_orders, %i[tenant_id vendor]
  end
end
