module ApplicationHelper
  # pagy_url_for and friends for the custom pagination partials. Pagy ships
  # its own pt-BR locale (gem locales/pt-BR.yml), but the overtime pager is
  # a custom partial that uses the app's Rails i18n keys instead.
  include Pagy::Frontend
end
