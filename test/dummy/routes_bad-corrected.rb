Rails.application.routes.draw do
  root 'home#index'

  resources :home # SUGGESTION use only: [:index, :show]
  resources :full_items, except: [:destroy, :index] do
    member do
      get :missing_member_action # SUGGESTION delete line, :missing_member_action matches nothing
    end
    collection do
      post :missing_collection_action # SUGGESTION delete line, :missing_collection_action matches nothing
    end
  end
  resources :full_items, only: [:destroy, :index]

  get 'unknown_controller_index', action: :index, controller: 'unknown_controller' # SUGGESTION delete, UnknownControllerController not found
end
