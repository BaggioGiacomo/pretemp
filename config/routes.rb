Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "archivio" => "archive#index", as: :archive
  get "archivio/:year" => "archive#show", as: :archive_year

  get "modelli" => "templates#index", as: :templates
  get "modelli/:category" => "templates#show", as: :template_category

  get "guida_alle_previsioni" => "pages#guida_alle_previsioni", as: :guida_alle_previsioni

  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    # Invitation acceptance (public, but token-protected)
    resources :invitations, only: [], param: :token do
      member do
        get :accept, action: :edit
        post :accept, action: :update
      end
    end

    # Password reset
    resources :passwords, only: [ :new, :create, :edit, :update ], param: :token

    get "/", to: "dashboard#index", as: :root
    resources :invitations, only: [ :index, :new, :create, :destroy ]
  end

  # Defines the root path route ("/")
  root "home#index"
end
