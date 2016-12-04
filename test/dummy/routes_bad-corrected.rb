Rails.application.routes.draw do
  root to: 'home#index'

  resources :home, only: [:index, :show]
  resources :full_items, except: [:destroy, :index] do
    member do
    end
    collection do
    end
  end
  resources :full_items, only: [:destroy, :index]


  2.times do |i|
    get "unknown_index#{i}", action: :index, controller: "unknown_#{i}" # SUGGESTION delete, Unknown0Controller not found, delete, Unknown1Controller not found
  end
  resources :home, only: [:index, :show] # random comment
  resources :home, only: [:index, :show]
end
