FactoryBot.define do
  factory :tenant do
    sequence(:name)      { |n| "Company #{n}" }
    sequence(:subdomain) { |n| "company#{n}" }
    plan { 'starter' }
    active { true }
  end
end
