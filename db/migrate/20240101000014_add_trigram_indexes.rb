class AddTrigramIndexes < ActiveRecord::Migration[8.1]
  def up
    enable_extension 'pg_trgm'
    add_index :requisitions, :title, using: :gin, opclass: :gin_trgm_ops,
              name: 'idx_requisitions_title_trgm'
    add_index :invoices, :vendor, using: :gin, opclass: :gin_trgm_ops,
              name: 'idx_invoices_vendor_trgm'
    add_index :purchase_orders, :vendor, using: :gin, opclass: :gin_trgm_ops,
              name: 'idx_purchase_orders_vendor_trgm'
  end

  def down
    remove_index :requisitions, name: 'idx_requisitions_title_trgm'
    remove_index :invoices, name: 'idx_invoices_vendor_trgm'
    remove_index :purchase_orders, name: 'idx_purchase_orders_vendor_trgm'
  end
end
