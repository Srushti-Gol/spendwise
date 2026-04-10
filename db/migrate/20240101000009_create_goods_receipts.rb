class CreateGoodsReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :goods_receipts do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :purchase_order, null: false, foreign_key: true
      t.references :received_by, null: false, foreign_key: { to_table: :users }
      t.date :received_at, null: false
      t.text :notes
      t.string :delivery_reference
      t.timestamps
    end
    add_index :goods_receipts, %i[tenant_id purchase_order_id]
  end
end
