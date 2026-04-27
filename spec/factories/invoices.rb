FactoryBot.define do
  factory :invoice do
    association :tenant
    association :created_by, factory: :user
    sequence(:vendor) { |n| "Vendor #{n}" }
    sequence(:invoice_number) { |n| "INV-#{n.to_s.rjust(4, '0')}" }
    total_amount { 10_000 }
    currency { 'USD' }
    invoice_date { Date.today }
    status { 'pending' }
  end
end
