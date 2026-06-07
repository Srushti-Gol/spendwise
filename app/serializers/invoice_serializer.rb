class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :vendor, :invoice_number, :total_amount, :currency,
             :status, :price_match, :quantity_match, :vendor_match,
             :is_duplicate, :price_variance, :quantity_variance,
             :purchase_order_id, :processed_at, :invoice_date, :created_at

  has_many :invoice_items
end
