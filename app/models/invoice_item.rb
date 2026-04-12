class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  validates :description, presence: true
end
