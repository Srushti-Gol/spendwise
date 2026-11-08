FactoryBot.define do
  factory :user do
    association :tenant
    sequence(:name)  { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    role { 'staff' }
    department { 'Engineering' }

    trait :manager  do role { 'manager' }  end
    trait :finance  do role { 'finance' }  end
    trait :director do role { 'director' } end
    trait :admin    do role { 'admin' }    end
  end
end
