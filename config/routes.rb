Rails.application.routes.draw do

  resources :orders
  root :to => 'home#index'
  
  resources :customers
  resources :cards
  resources :addresses
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  controller :home do
    get 'home' => :index
  end
end
