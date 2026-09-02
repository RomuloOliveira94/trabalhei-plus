require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Trabalheiamais
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "America/Sao_Paulo"
    config.active_record.default_timezone = :utc

    # The default locale is pt-BR (see SPEC.md §10 Q2). English is the single
    # fallback, so any key a gem ships only in :en (or leaves nil in pt-BR)
    # still resolves instead of rendering "translation missing".
    config.i18n.default_locale = :"pt-BR"
    config.i18n.available_locales = [ :"pt-BR", :en ]
    config.i18n.fallbacks = [ :en ]

    # Route exceptions through the app so the pt-BR error pages render
    # (ErrorsController + config/routes.rb /404 /422 /500).
    config.exceptions_app = self.routes

    # config.eager_load_paths << Rails.root.join("extras")
  end
end
