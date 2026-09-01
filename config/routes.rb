Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Guests land on the marketing/home page; signed-in users are bounced
  # to their overtime list by HomeController (SPEC §3 "Dashboard / Index").
  root "home#show"

  # Export endpoints must be declared before the `resources` block so
  # `overtimes/export_pdf` is not swallowed by the `overtimes/:id` show route.
  get "overtimes/export_pdf", to: "overtimes#export_pdf", as: :export_overtimes_pdf
  get "overtimes/export_xlsx", to: "overtimes#export_xlsx", as: :export_overtimes_xlsx

  resources :overtimes

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify the app is the live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
