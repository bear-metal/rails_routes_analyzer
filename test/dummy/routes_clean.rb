Rails.application.routes.draw do
  root 'home#index'

  resources :home, only: [:show]
  resources :full_items do
    member do
      get :custom
    end
    collection do
      get :custom_index
    end
  end
end
