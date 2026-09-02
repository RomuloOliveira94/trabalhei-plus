class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Devise only permits its own fields by default, so `user[name]` was being
  # stripped and `validates :name, presence: true` failed on every sign-up
  # and account update. Every Devise controller inherits from this one, so
  # declaring the extra parameter here covers all of them.
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
      devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
    end
end
