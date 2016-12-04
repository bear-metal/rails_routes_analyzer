Rails.application.routes.draw do
  root to: 'home#index'

  resources :home # SUGGESTION use only: [:index, :show]
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

  2.times do |i|
    get "unknown_index#{i}", action: :index, controller: "unknown_#{i}"
  end
  resources :home # random comment
  resources :home
end
