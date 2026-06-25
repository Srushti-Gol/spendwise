require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login",    to: "auth#login"
      get  "auth/me",       to: "auth#me"

      get "dashboard/stats", to: "dashboard#stats"

      resources :requisitions do
        member do
          post :submit
          post :approve
          post :reject
          post :cancel
        end
      end

      resources :purchase_orders do
        member do
          post :send_to_vendor
        end
      end

      resources :goods_receipts, only: %i[index show create]

      resources :invoices do
        member do
          post :process_invoice
          post :approve_payment
        end
      end

      resources :audit_logs, only: %i[index show]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
