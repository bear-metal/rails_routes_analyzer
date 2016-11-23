Rails.application.routes.draw do
  root 'home#index'

  resources :home
  resources :full_items, except: [:destroy, :index] do
    member do
      get :missing_member_action
    end
    collection do
      post :missing_collection_action
    end
  end
  resources :full_items, only: [:destroy, :index]

  get 'unknown_controller_index', action: :index, controller: 'unknown_controller'
end
