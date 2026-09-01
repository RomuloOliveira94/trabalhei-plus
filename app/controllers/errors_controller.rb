# Renders the pt-BR error pages via config.exceptions_app = self.routes.
# No authentication: 404/500 must render for guests too. Uses a minimal
# layout so error handling never depends on the signed-in header/menu.
class ErrorsController < ApplicationController
  skip_before_action :verify_authenticity_token

  layout "errors"

  def not_found
    render status: :not_found
  end

  def unprocessable_entity
    render status: :unprocessable_entity
  end

  def internal_server_error
    render status: :internal_server_error
  end
end
