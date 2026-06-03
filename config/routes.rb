Rails.application.routes.draw do
  resources :chats do
    resources :messages, only: [ :create ]
  end
  resources :models, only: [ :index, :show ] do
    collection do
      post :refresh
    end
  end
  devise_for :users
  get "onboarding/welcome", to: "onboarding#welcome", as: :onboarding_welcome
  root to: "pages#home"

  resource  :creator, only: [:show, :new, :create, :edit, :update]
  
  resources :generated_ideas
  
  resources :ideas do
    resources :scripts, shallow: true
  end
  
  resources :scripts do
    resource :linkedin_post, only: [:show, :new, :create, :edit, :update, :destroy]
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
