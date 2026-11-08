class CreateGoodsReceiptItems < ActiveRecord::Migration[8.1]
  def change
    create_table :goods_receipt_items do |t|
      t.references :goods_receipt, null: false, foreign_key: true
      t.references :purchase_order_item, foreign_key: true
      t.decimal :quantity_received, precision: 15, scale: 4, null: false
      t.string :condition, default: 'good'
      t.text :notes
      t.timestamps
    end
  end
end
