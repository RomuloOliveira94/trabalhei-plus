require "application_system_test_case"

class InfiniteScrollTest < ApplicationSystemTestCase
  setup do
    # The pagination fixtures live two months back (25 records per user).
    month = Date.current << 2
    @filter = {
      q: {
        start_at_gteq: month.beginning_of_month.to_s,
        start_at_lteq: month.end_of_month.to_s
      }
    }
  end

  test "mobile: scrolling to the end loads the next page and stops on the last" do
    sign_in users(:one)
    page.current_window.resize_to(375, 812)
    visit overtimes_path(@filter)

    assert_selector "#overtimes-mobile-list > div.rounded-lg", count: 20
    assert_selector "#overtime-sentinel"

    page.scroll_to(:bottom)

    assert_selector "#overtimes-mobile-list > div.rounded-lg", count: 25, wait: 5
    # Last page reached: no sentinel left, so nothing triggers further loads.
    assert_no_selector "#overtime-sentinel"
    # Scope integrity: Bruno's records never leak into Ana's list.
    assert_no_text "Registro de paginação B"
  end

  test "desktop: pager buttons navigate the frame and infinite scroll stays idle" do
    sign_in users(:one)
    page.current_window.resize_to(1280, 800)
    visit overtimes_path(@filter)

    assert_selector "table tbody tr", count: 20
    assert_selector "nav[aria-label='Paginação']"
    # The sentinel exists but is hidden inside the mobile-only list.
    assert_selector "#overtime-sentinel", visible: :hidden

    page.scroll_to(:bottom)
    # Scrolling on desktop never auto-loads page 2.
    assert_equal 20, page.evaluate_script("document.querySelectorAll('#overtimes-mobile-list > div.rounded-lg').length")

    within("nav[aria-label='Paginação']") { click_link "2" }

    assert_selector "table tbody tr", count: 5
    assert_match /page=2/, page.current_url
  end
end
