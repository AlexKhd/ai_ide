Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  root "home#dashboard"
  resources :ai_connections
  resources :app_folders do
    collection do
      get :browse_working_directory
    end
  end
  get "ai/code_suggest"
  post "/ai/code_suggest", to: "ai#code_suggest"
  get "ai/code_suggestsse"
  get "home/index"
  resources :ai_connections do
    collection do
      post :sync_models
      post :apply_sync
    end
  end
  resources :users do
    member do
      get :edit
      patch :update
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
