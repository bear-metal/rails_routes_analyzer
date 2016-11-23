Rails.application.routes.draw do
  [:something, :full_items].each do |controller|
    resource controller, only: [:destroy]
  end

  [:index, :unknown_action, :other_action].each do |action|
    get "home/#{action}", action: action, controller: 'home'
  end
end
