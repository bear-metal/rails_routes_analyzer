Rails.application.routes.draw do
  [:something, :full_items].each do |controller|
    resource controller, only: [:destroy] # SUGGESTION remove case for SomethingsController as it doesn't exist
  end

  [:index, :unknown_action, :other_action].each do |action|
    get "home/#{action}", action: action, controller: 'home' # SUGGESTION remove cases for [:other_action, :unknown_action]
  end
end
