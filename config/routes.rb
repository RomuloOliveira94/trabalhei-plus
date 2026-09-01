Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Root: guests land on the sign-in page rendered at "/" (clean URL); signed-in
  # users are sent straight to their overtime list. Devise's after_sign_in_path
  # uses the authenticated root (user_root_path), so login lands on /overtimes
  # (SPEC §3). The unauthenticated root keeps the plain root_path helper and
  # must live inside devise_scope so Devise resolves the user mapping.
  authenticated :user do
    root to: "overtimes#index", as: :authenticated_root
  end

  devise_scope :user do
    root to: "devise/sessions#new"
  end

  # Export endpoints must be declared before the `resources` block so
  # `overtimes/export_pdf` is not swallowed by the `overtimes/:id` show route.
  get "overtimes/export_pdf", to: "overtimes#export_pdf", as: :export_overtimes_pdf
  get "overtimes/export_xlsx", to: "overtimes#export_xlsx", as: :export_overtimes_xlsx

  resources :overtimes

  # Custom pt-BR error pages (config.exceptions_app = self.routes). Declared
  # after the app routes so real paths win; these only catch unmatched paths
  # and exceptions re-dispatched by Rails.
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify the app is the live.
  get "up" => "rails/health#show", as: :rails_health_check
end
