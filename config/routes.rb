Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :customer_payments, only: %i[index]

  root to: 'customer_payments#index'
end
