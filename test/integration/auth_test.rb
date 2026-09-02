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
    assert_select "input[type=submit][value=Entrar]"
    assert_select "a", "Cadastre-se"
    assert_select "a", "Esqueceu a senha?"
  end

  test "sign up page renders in pt-BR with a name field" do
    get new_user_registration_path

    assert_response :success
    assert_select "label", "Nome"
    assert_select "label", "E-mail"
    assert_select "label", "Senha"
  end

  test "sign up persists the name and signs the user in" do
    assert_difference -> { User.count }, 1 do
      post user_registration_path, params: {
        user: {
          name: "Fulano da Silva",
          email: "fulano@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :redirect
    assert_equal "Fulano da Silva", User.find_by(email: "fulano@example.com").name
    assert_not_nil session["warden.user.user.key"]
  end

  test "sign up without a name is rejected with the pt-BR blank message" do
    assert_no_difference -> { User.count } do
      post user_registration_path, params: {
        user: {
          name: "",
          email: "sem.nome@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "Nome não pode ficar em branco", response.body
  end

  test "account update persists a new name" do
    sign_in users(:one)

    patch user_registration_path, params: {
      user: {
        name: "Ana Souza Atualizada",
        email: users(:one).email,
        current_password: "password123"
      }
    }

    assert_response :redirect
    assert_equal "Ana Souza Atualizada", users(:one).reload.name
  end

  test "signs in with valid credentials" do
    post user_session_path, params: { user: { email: users(:one).email, password: "password123" } }

    # Devise redirects to the authenticated root (user_root_path), which now
    # redirects to the overtime list at /overtimes (QA blocker fix).
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
    assert_select "a", "Cadastre-se"
  end

  test "the header menu links a signed-in user to their account settings" do
    sign_in users(:one)
    get overtimes_path

    assert_response :success
    assert_select "a[href=?]", edit_user_registration_path, text: "Minha conta"
  end

  test "signs out" do
    sign_in users(:one)
    delete destroy_user_session_path

    assert_redirected_to root_path
    get root_path
    assert_response :success
    assert_select "input[type=submit][value=Entrar]"
  end

  test "root renders the sign-in page for guests" do
    get root_path

    assert_response :success
    assert_select "input[type=submit][value=Entrar]"
    assert_select "a", "Cadastre-se"
    assert_select "button", "Entrar com Google"
  end

  test "root redirects signed-in users to the overtime list" do
    sign_in users(:one)
    get root_path

    assert_redirected_to overtimes_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Minhas horas extras"
  end

  test "google omniauth callback creates and signs in a new user" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "123456",
      info: { name: "Google User", email: "google@example.com", email_verified: true }
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
      info: { name: "Nome Google", email: users(:one).email, email_verified: true }
    )

    assert_no_difference -> { User.count } do
      post user_google_oauth2_omniauth_authorize_path
      assert_response :redirect
      post user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to root_path
  end

  test "google omniauth callback rejects an unverified email with a pt-BR flash" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "777777",
      info: { name: "Atacante", email: users(:one).email, email_verified: false }
    )

    assert_no_difference -> { User.count } do
      post user_google_oauth2_omniauth_authorize_path
      assert_response :redirect
      post user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_response :success
    assert_match "o e-mail da conta Google não foi verificado", response.body
    # The existing account was NOT signed in (no takeover).
    assert_nil session["warden.user.user.key"]
  end

  test "omniauth authorize with blank credentials does not blow up" do
    # Credentials are stubbed (see .env.example) — the request phase must
    # still answer without a server error.
    post user_google_oauth2_omniauth_authorize_path

    assert_not_equal 500, response.status
    assert_response :redirect
  end
end
