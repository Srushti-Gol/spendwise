class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :purchase_order, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :vendor, null: false
      t.string :invoice_number
      t.decimal :total_amount, precision: 15, scale: 2, null: false
      t.string :currency, default: 'USD'
      t.date :invoice_date
      t.string :status, default: 'pending', null: false
      t.string :pdf_url
      t.jsonb :extracted_data, default: {}
      t.jsonb :match_result, default: {}
      t.boolean :price_match
      t.boolean :quantity_match
      t.boolean :vendor_match
      t.decimal :price_variance, precision: 10, scale: 6
      t.decimal :quantity_variance, precision: 10, scale: 6
      t.boolean :is_duplicate, default: false
      t.datetime :processed_at
      t.timestamps
    end
    add_index :invoices, %i[tenant_id status]
    add_index :invoices, %i[tenant_id purchase_order_id]
    add_index :invoices, %i[tenant_id invoice_number],
              unique: true, where: 'invoice_number IS NOT NULL',
              name: 'idx_invoices_unique_number'
    add_index :invoices, :extracted_data, using: :gin
  end
end
