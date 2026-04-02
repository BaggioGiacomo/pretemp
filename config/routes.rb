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

  resources :archive, path: "archivio", only: [ :index, :show ], param: :year, as: :archivio

  get "modelli" => "templates#index", as: :templates
  get "modelli/:category" => "templates#show", as: :template_category

  get "guida_alle_previsioni" => "pages#guida_alle_previsioni", as: :guida_alle_previsioni

  get "monitoraggio/radar" => "pages#monitoraggio_radar", as: :monitoraggio_radar
  get "monitoraggio/fulmini" => "pages#monitoraggio_fulmini", as: :monitoraggio_fulmini
  get "monitoraggio/satelliti" => "pages#monitoraggio_satelliti", as: :monitoraggio_satelliti
  get "monitoraggio/stazioni_meteo" => "pages#monitoraggio_stazioni_meteo", as: :monitoraggio_stazioni_meteo
  get "monitoraggio/radiosondaggi" => "pages#monitoraggio_radiosondaggi", as: :monitoraggio_radiosondaggi

  resources :forecasts, path: "previsioni", only: [ :index, :show ]

  resources :articles, path: "blog", only: [ :index, :show ]

  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :invitations, only: [], param: :token do
      member do
        get :accept, action: :edit
        post :accept, action: :update
      end
    end

    resources :passwords, only: [ :new, :create, :edit, :update ], param: :token

    resources :password_resets, only: [], param: :token do
      member do
        get :edit
        patch :update
      end
    end

    resources :users, only: [] do
      member do
        post :generate_password_reset
      end
    end

    resources :forecasts

    resources :radar_monitorings, except: :show
    resources :satellite_monitorings, except: :show
    resources :radio_poll_monitorings, except: :show
    resources :weather_station_monitorings, except: :show
    resources :lightning_monitorings, except: :show

    resources :articles

    resources :invitations, only: [ :index, :new, :create, :destroy ]

    get "/", to: "dashboard#index", as: :root
  end

  # Defines the root path route ("/")
  root "home#index"
end
