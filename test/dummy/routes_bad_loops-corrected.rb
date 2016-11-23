Rails.application.routes.draw do
  [:something, :full_items].each do |controller|
    resource controller, only: [:destroy] # SUGGESTION delete, SomethingsController not found
  end

  [:index, :unknown_action, :other_action].each do |action|
    get "home/#{action}", action: action, controller: 'home' # SUGGESTION action :other_action not found for HomeController, action :unknown_action not found for HomeController
  end
end
