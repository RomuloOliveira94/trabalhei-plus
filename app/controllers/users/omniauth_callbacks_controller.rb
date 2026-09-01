# frozen_string_literal: true

# Devise OmniAuth callbacks for the Google provider. Keeps the controller
# thin: all lookup/creation logic lives in User.from_omniauth.
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])

    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
  rescue OmniAuth::EmailNotVerified
    redirect_to new_user_session_path
    set_flash_message(:alert, :email_not_verified, kind: "Google") if is_navigational_format?
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_user_session_path
    set_flash_message(:alert, :failure, kind: "Google", reason: e.message) if is_navigational_format?
  end
end
