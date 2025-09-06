Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  
  namespace :api do
    namespace :v1 do
      post "encode", to: "encode#create"
      get "decode/:slug", to: "decode#show"
      get "decode", to: "decode#show"
    end
  end
  
  # Legacy routes (backward compatibility)
  post "encode", to: "api/v1/encode#create"
  get "decode/:slug", to: "api/v1/decode#show"
  get "decode", to: "api/v1/decode#show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
