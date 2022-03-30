Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: 'application#version'
  get '/version', to: 'application#version'

  namespace :api do
    namespace :v1 do
      resources :users, only: :create do
        resources :sleep_sessions, only: :index

        resources :samsung_health, only: :create
        resources :room_sensors, only: :create
        resources :data, only: :index
      end
    end
  end
end
