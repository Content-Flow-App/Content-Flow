Rails.application.routes.draw do
  resources :chats do
    resources :messages, only: [ :create ]

    # Singular nested resource — like `resource :creator`, it generates NO :id
    # segment because a chat has at most one generation action:
    #   POST /chats/:chat_id/generation  ->  GenerationsController#create
    #     (named `chat_generation_path(chat)`)
    # only: [:create] keeps it to that single route; the chat_id comes from the
    # nesting, so the controller reads params[:chat_id].
    resource :generation, only: [ :create ]
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

  # Substack idea feed.
  #
  # `resources :substack_sources, only: [...]` generates exactly these four routes:
  #   GET    /substack_sources          → SubstackSourcesController#index
  #   GET    /substack_sources/new      → SubstackSourcesController#new
  #   POST   /substack_sources          → SubstackSourcesController#create
  #   DELETE /substack_sources/:id      → SubstackSourcesController#destroy
  # No show/edit/update — we don't need them for this MVP.
  resources :substack_sources, only: [ :index, :new, :create, :destroy ]

  # The feed is a flat list of posts across all sources.
  # `resources :substack_posts, only: [:index]` gives us:
  #   GET /substack_posts → SubstackPostsController#index
  # The `collection do` block adds a route that acts on the whole group (no :id):
  #   POST /substack_posts/refresh → SubstackPostsController#refresh
  # If we used `member do` instead it would add an :id segment — wrong here because
  # refresh fires jobs for *all* sources, not one specific post.
  resources :substack_posts, only: [ :index ] do
    collection do
      post :refresh
    end
  end

  resources :ideas do
    # Direct-flow posts (idea → post, no script). Singular resource generates no
    # :id segment — all paths scoped via :idea_id, e.g. GET /ideas/:idea_id/linkedin_post.
    # New route helpers: idea_linkedin_post_path(@idea), new_idea_linkedin_post_path(@idea), etc.
    resource :linkedin_post,  only: [ :show, :new, :create, :edit, :update, :destroy ]
    resource :twitter_post,   only: [ :show, :new, :create, :edit, :update, :destroy ]
    resource :instagram_post, only: [ :show, :new, :create, :edit, :update, :destroy ]

    # Scripted-flow posts (idea → script → post). shallow: true means show/edit/
    # update/destroy use /scripts/:id (no idea_id needed); new/create stay nested
    # under /ideas/:idea_id/scripts. Post resources are nested further under scripts.
    resources :scripts, shallow: true do
      resource :linkedin_post,  only: [ :show, :new, :create, :edit, :update, :destroy ]
      resource :twitter_post,   only: [ :show, :new, :create, :edit, :update, :destroy ]
      resource :instagram_post, only: [ :show, :new, :create, :edit, :update, :destroy ]
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
