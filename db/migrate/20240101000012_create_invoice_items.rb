class CreateInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :quantity, precision: 15, scale: 4
      t.decimal :unit_price, precision: 15, scale: 2
      t.decimal :total_price, precision: 15, scale: 2
      t.timestamps
    end
  end
end
