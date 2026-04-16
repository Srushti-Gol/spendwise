class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  validates :description, :quantity, :unit_price, :total_price, presence: true
end
