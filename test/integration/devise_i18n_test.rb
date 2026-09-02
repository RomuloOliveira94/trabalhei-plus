require "test_helper"

# The Devise views live inside `render "devise/shared/auth_card" do ... end`
# blocks, where relative i18n keys resolve against the *partial* path
# (`devise.shared.auth_card.*`) instead of the view's own. Every Devise page
# must therefore use absolute keys, and the handful of keys devise-i18n ships
# as nil for pt-BR must be filled in by config/locales/pt-BR.yml.
class DeviseI18nTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  MISSING = /translation missing|translation_missing/i

  test "guest Devise pages render without a missing translation" do
    [ new_user_registration_path, new_user_session_path, new_user_password_path ].each do |path|
      get path

      assert_response :success
      assert_no_match MISSING, response.body, "#{path} has a missing translation"
    end
  end

  test "account settings page renders without a missing translation" do
    sign_in users(:one)
    get edit_user_registration_path

    assert_response :success
    assert_no_match MISSING, response.body
    # Absolute-key strings that used to resolve to devise.shared.auth_card.*
    assert_match "Atualizar", response.body
    assert_match "Cancelar minha conta", response.body
    assert_match "Não está contente?", response.body
  end

  test "sign up page shows the pt-BR minimum password length hint" do
    get new_user_registration_path

    assert_response :success
    assert_match(/mínimo de \d+ caracteres/, response.body)
  end

  test "a failed sign up shows the pt-BR error header" do
    post user_registration_path, params: { user: { name: "", email: "", password: "" } }

    assert_response :unprocessable_entity
    assert_no_match MISSING, response.body
    assert_match(/erros? impedi(u|ram) o salvamento do usuário/, response.body)
  end
end
