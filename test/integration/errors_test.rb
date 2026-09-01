require "test_helper"

# Exercises the dynamic pt-BR error pages (ErrorsController) through
# config.exceptions_app = self.routes. In test env Rails normally shows
# debug pages (consider_all_requests_local = true), so this test flips that
# flag to simulate production error handling.
class ErrorsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.config.consider_all_requests_local = false
    # Test env defaults to :rescuable (only mapped exceptions); :all routes
    # every exception through exceptions_app like production does.
    Rails.application.config.action_dispatch.show_exceptions = :all
    # env_config is memoized at boot; force a recompute so the request-time
    # middleware reads the values above.
    Rails.application.instance_variable_set(:@app_env_config, nil)
  end

  teardown do
    Rails.application.config.consider_all_requests_local = true
    Rails.application.config.action_dispatch.show_exceptions = :rescuable
    Rails.application.instance_variable_set(:@app_env_config, nil)
  end

  test "unmatched route renders the pt-BR 404 page" do
    get "/pagina-que-nao-existe"

    assert_response :not_found
    assert_select "h1", "Página não encontrada"
    assert_select "a", "Voltar para minhas horas extras"
  end

  test "record not found renders the pt-BR 404 page" do
    sign_in users(:one)
    get overtime_path(999_999)

    assert_response :not_found
    assert_select "h1", "Página não encontrada"
  end

  test "internal server error renders the pt-BR 500 page" do
    # Force an exception through the app so exceptions_app re-dispatches to /500.
    original_kept = Overtime.method(:kept)
    Overtime.define_singleton_method(:kept) { raise "boom" }

    sign_in users(:one)
    get overtimes_path

    assert_response :internal_server_error
    assert_select "h1", "Algo deu errado"
  ensure
    Overtime.define_singleton_method(:kept, original_kept)
  end
end
