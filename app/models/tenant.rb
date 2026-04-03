class Tenant < ApplicationRecord
  validates :name, :subdomain, presence: true
  validates :subdomain, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

  has_many :users, dependent: :destroy
  has_many :requisitions, dependent: :destroy
  has_many :purchase_orders, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
end
