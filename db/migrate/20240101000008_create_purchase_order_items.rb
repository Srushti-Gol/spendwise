class CreatePurchaseOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_order_items do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :quantity, precision: 15, scale: 4, null: false
      t.decimal :unit_price, precision: 15, scale: 2, null: false
      t.decimal :total_price, precision: 15, scale: 2, null: false
      t.decimal :received_quantity, precision: 15, scale: 4, default: 0
      t.string :unit
      t.timestamps
    end
  end
end
