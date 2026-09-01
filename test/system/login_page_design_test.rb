require "application_system_test_case"

# Phase 6: branded sign-in page. The login is the landing page (SPEC §3), so
# its design is a first-class deliverable: centered card, red/white theme,
# Google button with the official G logo, mobile-first at 375px.
class LoginPageDesignTest < ApplicationSystemTestCase
  test "sign-in page shows the app name and tagline" do
    visit new_user_session_path

    assert_text "Trabalhei +"
    assert_text "Controle suas horas extras e comprove o tempo trabalhado com o RH."
  end

  test "Google button renders with the official G logo SVG" do
    visit new_user_session_path

    button = find("button", text: "Entrar com Google")
    assert button.has_selector?("svg", visible: true)
    # The G logo uses Google's brand colors (blue/red/yellow/green).
    %w[#4285F4 #EA4335 #FBBC05 #34A853].each do |color|
      assert_includes button.native.attribute("innerHTML"), color
    end
  end

  test "sign-in card is centered on the page" do
    visit new_user_session_path

    card = find(".max-w-md")
    # The card wrapper is a flex container that centers its child both axes.
    wrapper = card.find(:xpath, "..")
    assert_equal "flex", wrapper.native.style("display")
    assert_equal "center", wrapper.native.style("justify-content")
    assert_equal "center", wrapper.native.style("align-items")
  end

  test "desktop: sign-in card is vertically centered at 1280x800" do
    page.current_window.resize_to(1280, 800)
    visit new_user_session_path

    box = page.evaluate_script("document.querySelector('.max-w-md').getBoundingClientRect()")
    viewport_height = page.evaluate_script("window.innerHeight")

    card_center = box["top"] + box["height"] / 2
    viewport_center = viewport_height / 2
    # The card must sit at the viewport center (within 40px), not pushed down
    # by the header + main margin.
    assert_in_delta viewport_center, card_center, 40
  end

  test "mobile: card fills most of the viewport width with no horizontal scroll" do
    page.current_window.resize_to(375, 812)
    visit new_user_session_path

    # No horizontal overflow on the sign-in page.
    overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
    assert_operator overflow, :<=, 0

    card_width = page.evaluate_script("document.querySelector('.max-w-md').getBoundingClientRect().width")
    # Card takes most of the 375px viewport (max-w-md = 28rem = 448px, capped
    # by the px-5 padding on the layout main).
    assert_operator card_width, :>=, 300
  end

  test "sign-in page has the email/password fields and a red submit button" do
    visit new_user_session_path

    assert_selector "input[type=email]"
    assert_selector "input[type=password]"
    submit = find("input[type=submit][value='Entrar']")
    assert_includes submit[:class], "bg-red-600"
  end
end
