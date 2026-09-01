require "application_system_test_case"

class MobileFabTest < ApplicationSystemTestCase
  test "FAB is visible on mobile and hidden on desktop" do
    sign_in users(:one)
    page.current_window.resize_to(375, 812)
    visit overtimes_path

    assert_selector "a[aria-label='Nova hora extra']", visible: true

    page.current_window.resize_to(1280, 800)
    assert_selector "a[aria-label='Nova hora extra']", visible: false
  end

  test "FAB opens the new overtime form in place" do
    sign_in users(:one)
    page.current_window.resize_to(375, 812)
    visit overtimes_path

    find("a[aria-label='Nova hora extra']").click

    assert_selector "turbo-frame#overtime_form form"
    assert_match %r{/overtimes\z}, page.current_url
  end

  test "mobile filter sheet toggles and the page has no horizontal scroll at 375px" do
    sign_in users(:one)
    page.current_window.resize_to(375, 812)
    visit overtimes_path

    # No horizontal overflow on the index.
    overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
    assert_operator overflow, :<=, 0

    # Filter sheet is collapsed by default; opens on click.
    assert_no_selector "input[name='q[start_at_gteq]']", visible: true
    find("summary", text: "Filtros").click
    assert_selector "details#filter-sheet[open]"
    assert_selector "input[name='q[start_at_gteq]']", visible: true
  end
end
