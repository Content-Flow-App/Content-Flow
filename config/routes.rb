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
  root to: "pages#home"

  # Authed home. `get "dashboard"` expands to a single GET route:
  #   GET /dashboard  ->  DashboardController#show   (named `dashboard_path`)
  # Unlike `resources`, this generates ONLY this one route — no index/new/
  # edit/etc. The `as:` isn't needed; Rails derives the `dashboard_path`
  # helper from the path string "dashboard".
  get "dashboard", to: "dashboard#show"

  # Singular resource — one creator per user, accessed at /creator.
  # only: [:show, :create, :update] generates three routes:
  #   GET    /creator      → CreatorsController#show   (creator_path)
  #   POST   /creator      → CreatorsController#create (creator_path)
  #   PATCH  /creator      → CreatorsController#update (creator_path)
  # No :new or :edit — the show action handles both display and form states.
  resource  :creator, only: [ :show, :create, :update ]
  
  resources :generated_ideas
  
  resources :ideas do
    resources :scripts, shallow: true do
      resource :linkedin_post, only: [:show, :new, :create, :edit, :update, :destroy]
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
