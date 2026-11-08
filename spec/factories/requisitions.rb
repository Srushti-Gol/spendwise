FactoryBot.define do
  factory :requisition do
    association :tenant
    association :requester, factory: :user
    sequence(:title) { |n| "Requisition #{n}" }
    department { 'Engineering' }
    total_amount { 5_000 }
    status { 'draft' }
  end
end
