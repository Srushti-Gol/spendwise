FactoryBot.define do
  factory :purchase_order do
    association :tenant
    association :created_by, factory: :user
    sequence(:vendor) { |n| "Vendor #{n}" }
    total_amount { 10_000 }
    status { 'draft' }
    price_tolerance { 0.05 }
    quantity_tolerance { 0.02 }
  end
end
