require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "sign in page renders in pt-BR" do
    get new_user_session_path

    assert_response :success
    assert_select "label", "E-mail"
    assert_select "label", "Senha"
    assert_select "label", "Lembre-se de mim"
    assert_select "h2", "Login"
  end

  test "sign up page renders in pt-BR with a name field" do
    get new_user_registration_path

    assert_response :success
    assert_select "label", "Nome"
    assert_select "label", "E-mail"
    assert_select "label", "Senha"
  end

  test "signs in with valid credentials" do
    post user_session_path, params: { user: { email: users(:one).email, password: "password123" } }

    assert_redirected_to root_path
    follow_redirect!
    assert_redirected_to overtimes_path
    follow_redirect!
    assert_select "h1", "Minhas horas extras"
  end

  test "does not sign in with invalid credentials" do
    post user_session_path, params: { user: { email: users(:one).email, password: "wrongpass" } }

    assert_response :unprocessable_entity
    get root_path
    assert_response :success
    assert_select "a", "Criar conta"
  end

  test "signs out" do
    sign_in users(:one)
    delete destroy_user_session_path

    assert_redirected_to root_path
    get root_path
    assert_response :success
    assert_select "a", "Entrar"
  end

  test "root renders the guest home page" do
    get root_path

    assert_response :success
    assert_select "a", "Entrar"
    assert_select "a", "Criar conta"
  end

  test "root bounces signed-in users to their overtime list" do
    sign_in users(:one)
    get root_path

    assert_redirected_to overtimes_path
  end

  test "google omniauth callback creates and signs in a new user" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "123456",
      info: { name: "Google User", email: "google@example.com" }
    )

    assert_difference -> { User.count }, 1 do
      post user_google_oauth2_omniauth_authorize_path
      assert_response :redirect
      post user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_redirected_to overtimes_path
    follow_redirect!
    assert_select "h1", "Minhas horas extras"
  end

  test "google omniauth callback signs in an existing user by email" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "999999",
      info: { name: "Nome Google", email: users(:one).email }
    )

    assert_no_difference -> { User.count } do
      post user_google_oauth2_omniauth_authorize_path
      assert_response :redirect
      post user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to root_path
  end

  test "omniauth authorize with blank credentials does not blow up" do
    # Credentials are stubbed (see .env.example) — the request phase must
    # still answer without a server error.
    post user_google_oauth2_omniauth_authorize_path

    assert_not_equal 500, response.status
    assert_response :redirect
  end
end
