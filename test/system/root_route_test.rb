require "application_system_test_case"

# Phase 6: the root route is the sign-in page for guests (login IS the
# landing) and the overtime list for signed-in users (SPEC §3).
class RootRouteTest < ApplicationSystemTestCase
  test "guest GET / renders the sign-in page, not a home page" do
    visit root_path

    assert_equal "/", page.current_path
    assert_text "Entrar com Google"
    assert_selector "input[type=submit][value='Entrar']"
    assert_no_text "Minhas horas extras"
  end

  test "signed-in GET / shows the overtime list" do
    sign_in users(:one)
    visit root_path

    assert_text "Minhas horas extras"
    assert_no_text "Entrar com Google"
  end
end
