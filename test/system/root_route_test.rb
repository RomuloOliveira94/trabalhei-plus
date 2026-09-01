require "application_system_test_case"

# Phase 6: the root route is the sign-in page for guests (login IS the
# landing) and redirects signed-in users to the overtime list at /overtimes
# (SPEC §3). The redirect (not direct render) keeps the browser URL honest.
class RootRouteTest < ApplicationSystemTestCase
  test "guest GET / renders the sign-in page, not a home page" do
    visit root_path

    assert_equal "/", page.current_path
    assert_text "Entrar com Google"
    assert_selector "input[type=submit][value='Entrar']"
    assert_no_text "Minhas horas extras"
  end

  test "signed-in GET / redirects the browser to /overtimes" do
    sign_in users(:one)
    visit root_path

    assert_equal "/overtimes", page.current_path
    assert_text "Minhas horas extras"
    assert_no_text "Entrar com Google"
  end

  test "signing in lands the browser on /overtimes" do
    visit root_path
    fill_in "E-mail", with: users(:one).email
    fill_in "Senha", with: "password123"
    click_button "Entrar"

    # Turbo Drive submits the form asynchronously; waiting on the dashboard
    # content synchronizes with the navigation (URL and body update together),
    # so the path assertion is not racy.
    assert_text "Minhas horas extras"
    assert_equal "/overtimes", page.current_path
  end
end
